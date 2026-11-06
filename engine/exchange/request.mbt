///|
/// Process a bounded request. Error messages contain field codes, never input text.
pub fn run_request(source : String) -> Json raise @tide.ReconcileError {
  guard source.length() <= 524288 else {
    raise @tide.InvalidInput("json.size: request exceeds 524288 code units")
  }
  let parsed = @json.parse(
    source,
    max_nesting_depth=16,
    reject_duplicate_keys=true,
  ) catch {
    _ =>
      raise @tide.InvalidInput(
        "json.syntax: malformed, duplicate-key or excessively nested JSON",
      )
  }
  let fields = object(parsed)
  allowed(fields, [
    "title", "unit", "nodes", "method", "variances", "calibration", "floor_ratio",
    "forecasts",
  ])
  let title = match fields.get("title") {
    Some(value) => text(value, 160)
    None => "Forecast study"
  }
  let unit = match fields.get("unit") {
    Some(value) => text(value, 40)
    None => "units"
  }
  let node_items = array(required(fields, "nodes"))
  guard node_items.length() > 0 && node_items.length() <= 128 else {
    raise @tide.InvalidInput("tree.size: expected 1..128 nodes")
  }
  let nodes = node_items.map(item => {
    let obj = object(item)
    allowed(obj, ["id", "parent"])
    let id = text(required(obj, "id"), 80)
    let parent = match required(obj, "parent") {
      Null => None
      value => Some(text(value, 80))
    }
    @tide.Node::{ id, parent, }
  })
  let tree = @tide.hierarchy(nodes)
  let mode = match text(required(fields, "method"), 20) {
    "bottom_up" => @tide.BottomUp
    "ols" => @tide.Ols
    "wls" => @tide.Wls
    _ =>
      raise @tide.InvalidInput("method.unknown: expected bottom_up, ols or wls")
  }
  let rows = array(required(fields, "forecasts"))
  guard rows.length() > 0 && rows.length() <= 256 else {
    raise @tide.InvalidInput("forecast.horizons: expected 1..256 rows")
  }
  let periods : Array[Int32] = []
  let forecasts : Array[Array[Double]] = []
  let actuals : Array[Array[Double]] = []
  let observed_forecasts : Array[Array[Double]] = []
  let observed : Array[Json] = []
  for item in rows {
    let row = object(item)
    allowed(row, ["period", "values", "actual"])
    let tick = period(row)
    guard periods.is_empty() || tick > periods[periods.length() - 1] else {
      raise @tide.InvalidInput(
        "forecast.order: periods must be strictly increasing",
      )
    }
    periods.push(tick)
    let values = vector(required(row, "values"))
    forecasts.push(values)
    match row.get("actual") {
      None | Some(Null) => observed.push(@json.null)
      Some(value) => {
        actuals.push(vector(value))
        observed_forecasts.push(values)
        observed.push(value)
      }
    }
  }
  let mut calibration_rows = 0
  let fitted = match (fields.get("variances"), fields.get("calibration")) {
    (Some(_), Some(_)) =>
      raise @tide.InvalidInput(
        "calibration.exclusive: use variances or calibration, not both",
      )
    (Some(value), None) => {
      guard !fields.contains("floor_ratio") else {
        raise @tide.InvalidInput(
          "calibration.floor: floor_ratio requires calibration rows",
        )
      }
      tree.fit(mode, variances=vector(value))
    }
    (None, Some(value)) => {
      guard mode is @tide.Wls else {
        raise @tide.InvalidInput(
          "calibration.method: calibration rows require WLS",
        )
      }
      let items = array(value)
      guard items.length() >= 3 && items.length() <= 2048 else {
        raise @tide.InvalidInput("calibration.size: expected 3..2048 rows")
      }
      let residuals : Array[Array[Double]] = []
      let mut previous : Int32? = None
      for item in items {
        let row = object(item)
        allowed(row, ["period", "residuals"])
        let tick = period(row)
        guard tick < periods[0] else {
          raise @tide.InvalidInput(
            "calibration.leakage: calibration must precede forecast periods",
          )
        }
        match previous {
          Some(p) if tick <= p =>
            raise @tide.InvalidInput(
              "calibration.order: periods must be strictly increasing",
            )
          _ => ()
        }
        previous = Some(tick)
        residuals.push(vector(required(row, "residuals")))
      }
      calibration_rows = items.length()
      let floor_ratio = match fields.get("floor_ratio") {
        Some(x) => number(x)
        None => 1.0e-6
      }
      tree.fit_residuals(residuals, floor_ratio~)
    }
    (None, None) => {
      guard !fields.contains("floor_ratio") else {
        raise @tide.InvalidInput(
          "calibration.floor: floor_ratio requires calibration rows",
        )
      }
      tree.fit(mode)
    }
  }
  let coordinated = fitted.apply_many(forecasts)
  let outputs = Array::makei(rows.length(), i => {
    let adjusted = coordinated[i]
    Json::object({
      "period": @json.to_json(periods[i]),
      "base": @json.to_json(forecasts[i]),
      "coherent": @json.to_json(adjusted),
      "adjustments": @json.to_json(
        Array::makei(adjusted.length(), j => adjusted[j] - forecasts[i][j]),
      ),
      "coherence_before": @json.to_json(tree.coherence_error(forecasts[i])),
      "coherence_after": @json.to_json(tree.coherence_error(adjusted)),
      "actual": observed[i],
    })
  })
  let evaluation = if actuals.is_empty() {
    @json.null
  } else {
    let report = fitted.evaluate(observed_forecasts, actuals)
    Json::object({
      "horizons": @json.to_json(report.horizons),
      "base_coherence": @json.to_json(report.base_coherence),
      "reconciled_coherence": @json.to_json(report.reconciled_coherence),
      "nodes": Json::array(
        report.nodes.map(score => {
          Json::object({
            "id": @json.to_json(score.id),
            "base_mae": @json.to_json(score.base_mae),
            "reconciled_mae": @json.to_json(score.reconciled_mae),
            "base_rmse": @json.to_json(score.base_rmse),
            "reconciled_rmse": @json.to_json(score.reconciled_rmse),
          })
        }),
      ),
    })
  }
  Json::object({
    "status": Json::string("ok"),
    "title": Json::string(title),
    "unit": Json::string(unit),
    "method": Json::string(describe_mode(mode)),
    "node_ids": @json.to_json(tree.node_ids()),
    "leaf_ids": @json.to_json(tree.leaf_ids()),
    "variances": @json.to_json(fitted.error_variances()),
    "calibration_rows": @json.to_json(calibration_rows),
    "periods": Json::array(outputs),
    "evaluation": evaluation,
  })
}

///|
/// A non-throwing text boundary shared by browser and command-line hosts.
pub fn process(source : String) -> String {
  let result = run_request(source) catch {
    @tide.InvalidInput(message) =>
      Json::object({
        "status": Json::string("invalid"),
        "message": Json::string(message),
      })
    @tide.NumericalFailure(message) =>
      Json::object({
        "status": Json::string("numerical_failure"),
        "message": Json::string(message),
      })
  }
  result.stringify(indent=2)
}
