///|
pub(all) enum Method {
  BottomUp
  Ols
  Wls
}

///|
/// A fitted transformation. Variances are fixed across future horizons.
pub struct Reconciler {
  priv tree : Hierarchy
  priv mode : Method
  priv variances : Array[Double]
}

///|
/// Fit a transformation with explicit diagonal error variances.
/// For OLS and bottom-up omit variances. WLS requires positive variances.
pub fn Hierarchy::fit(
  self : Hierarchy,
  mode : Method,
  variances? : Array[Double],
) -> Reconciler raise ReconcileError {
  let values = match (mode, variances) {
    (Wls, Some(v)) => {
      guard v.length() == self.ids.length() else {
        raise InvalidInput("variance.shape: expected one variance per node")
      }
      let mut minimum = 1.0e100
      let mut maximum = 0.0
      for x in v {
        guard finite(x) && x >= 1.0e-100 && x <= 1.0e100 else {
          raise InvalidInput(
            "variance.number: expected positive variance in 1e-100..1e100",
          )
        }
        if x < minimum {
          minimum = x
        }
        if x > maximum {
          maximum = x
        }
      }
      guard maximum / minimum <= 1.0e12 else {
        raise InvalidInput("variance.condition: variance ratio exceeds 1e12")
      }
      v.copy()
    }
    (Wls, None) =>
      raise InvalidInput(
        "variance.missing: WLS requires variances or calibration residuals",
      )
    (_, Some(_)) =>
      raise InvalidInput(
        "variance.method: variances are only meaningful for WLS",
      )
    (_, None) => Array::make(self.ids.length(), 1.0)
  }
  { tree: self, mode, variances: values, }
}

///|
pub fn Reconciler::error_variances(self : Reconciler) -> Array[Double] {
  self.variances.copy()
}

///|
/// Reconcile one forecast vector without modifying the input.
/// Negative reconciled values are retained; no clipping is applied.
pub fn Reconciler::apply(
  self : Reconciler,
  forecast : Array[Double],
) -> Array[Double] raise ReconcileError {
  self.tree.check_vector(forecast)
  let leaves = match self.mode {
    BottomUp => self.tree.leaves.map(i => forecast[i])
    Ols | Wls => solve_leaves(self.tree, forecast, self.variances)
  }
  for value in leaves {
    guard checked_value(value) else {
      raise NumericalFailure(
        "solve.range: reconciled leaves exceed supported numeric range",
      )
    }
  }
  let result = self.tree.aggregate(leaves)
  for value in result {
    guard checked_value(value) else {
      raise NumericalFailure(
        "solve.range: reconciled output exceeds supported numeric range",
      )
    }
  }
  result
}

///|
pub fn Reconciler::apply_many(
  self : Reconciler,
  forecasts : Array[Array[Double]],
) -> Array[Array[Double]] raise ReconcileError {
  guard forecasts.length() > 0 && forecasts.length() <= 256 else {
    raise InvalidInput("forecast.horizons: expected 1..256 forecast vectors")
  }
  forecasts.map(row => self.apply(row))
}
