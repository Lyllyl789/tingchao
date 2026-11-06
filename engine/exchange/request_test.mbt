///|
fn sample() -> Map[String, Json] {
  {
    "nodes": [
      { "id": "total", "parent": null },
      { "id": "a", "parent": "total" },
      { "id": "b", "parent": "total" },
    ],
    "method": "ols",
    "forecasts": [
      { "period": 1, "values": [100, 70, 50], "actual": [110, 60, 50] },
    ],
  }
}

///|
fn expect_invalid(source : String, code : String) -> Unit raise {
  let report = @json.parse(@exchange.process(source))
  guard report is { "status": "invalid", "message": String(message), .. } else {
    fail("expected invalid report")
  }
  assert_true(message.has_prefix(code))
}

///|
test "JSON boundary preserves period, reports adjustments and scores actuals" {
  let output = @exchange.run_request(Json::object(sample()).stringify())
  guard output
    is {
      "status": "ok",
      "periods": Array([row]),
      "evaluation": { "horizons": Number(count, ..), .. },
      ..
    } else {
    fail("expected complete report")
  }
  assert_eq(count, 1.0)
  guard row
    is { "coherent": Array(values), "coherence_after": Number(error, ..), .. } else {
    fail("expected coherent output")
  }
  let numbers : Array[Double] = @json.from_json(Json::array(values))
  assert_true((numbers[0] - 320.0 / 3.0).abs() < 1.0e-9)
  assert_true(error.abs() < 1.0e-9)
}

///|
test "calibration periods must precede evaluation and cannot share weights" {
  let input = sample()
  input["method"] = "wls"
  input["calibration"] = [
    { "period": -2, "residuals": [-2, -1, -1] },
    { "period": -1, "residuals": [0, 0, 0] },
    { "period": 0, "residuals": [2, 1, 1] },
  ]
  guard @exchange.run_request(Json::object(input).stringify())
    is { "status": "ok", "calibration_rows": Number(3.0, ..), .. } else {
    fail("expected fitted WLS")
  }
  input["calibration"] = [
    { "period": -1, "residuals": [-2, -1, -1] },
    { "period": 0, "residuals": [0, 0, 0] },
    { "period": 1, "residuals": [2, 1, 1] },
  ]
  expect_invalid(Json::object(input).stringify(), "calibration.leakage")
  input["variances"] = [1, 1, 1]
  expect_invalid(Json::object(input).stringify(), "calibration.exclusive")
}

///|
test "malformed, duplicate, misspelled and fractional requests are rejected" {
  expect_invalid("{", "json.syntax")
  expect_invalid("{\"nodes\":[],\"nodes\":[]}", "json.syntax")
  let input = sample()
  input["unknwon"] = true
  expect_invalid(Json::object(input).stringify(), "json.field")
  let fraction = sample()
  fraction["forecasts"] = [{ "period": 1.5, "values": [100, 70, 50] }]
  expect_invalid(Json::object(fraction).stringify(), "period.integer")
  let ordering = sample()
  ordering["forecasts"] = [
    { "period": 2, "values": [100, 70, 50] },
    { "period": 1, "values": [100, 70, 50] },
  ]
  expect_invalid(Json::object(ordering).stringify(), "forecast.order")
}

///|
test "errors do not echo caller-supplied text" {
  let input = sample()
  input["method"] = "private-input-marker"
  let report = @exchange.process(Json::object(input).stringify())
  assert_false(report.contains("private-input-marker"))
  expect_invalid(Json::object(input).stringify(), "method.unknown")
}
