///|
/// Per-node holdout errors. All nodes must share one additive measurement unit.
pub(all) struct NodeScore {
  id : String
  base_mae : Double
  reconciled_mae : Double
  base_rmse : Double
  reconciled_rmse : Double
}

///|
/// Accuracy and coherence are deliberately reported as separate quantities.
pub(all) struct Evaluation {
  horizons : Int32
  base_coherence : Double
  reconciled_coherence : Double
  nodes : Array[NodeScore]
}

///|
/// Evaluate a fixed reconciler without fitting on the holdout actuals.
/// Actuals must already satisfy the declared tree, up to relative tolerance.
pub fn Reconciler::evaluate(
  self : Reconciler,
  forecasts : Array[Array[Double]],
  actuals : Array[Array[Double]],
) -> Evaluation raise ReconcileError {
  guard actuals.length() == forecasts.length() else {
    raise InvalidInput("actuals.horizons: forecasts and actuals must align")
  }
  let adjusted = self.apply_many(forecasts)
  let n = self.tree.ids.length()
  let base_abs = Array::make(n, 0.0)
  let recon_abs = Array::make(n, 0.0)
  let base_sq = Array::make(n, 0.0)
  let recon_sq = Array::make(n, 0.0)
  let mut before = 0.0
  let mut after = 0.0
  for t, actual in actuals {
    self.tree.check_vector(actual)
    let mut scale = 1.0
    for x in actual {
      if x.abs() > scale {
        scale = x.abs()
      }
    }
    guard self.tree.coherence_error(actual) <= 1.0e-9 * scale else {
      raise InvalidInput(
        "actuals.coherence: observed totals do not match their children",
      )
    }
    let b = self.tree.coherence_error(forecasts[t])
    let a = self.tree.coherence_error(adjusted[t])
    if b > before {
      before = b
    }
    if a > after {
      after = a
    }
    for j in 0..<n {
      let e0 = forecasts[t][j] - actual[j]
      let e1 = adjusted[t][j] - actual[j]
      base_abs[j] += e0.abs()
      recon_abs[j] += e1.abs()
      base_sq[j] += e0 * e0
      recon_sq[j] += e1 * e1
    }
  }
  let count = actuals.length().to_double()
  let nodes = Array::makei(n, j => NodeScore::{
    id: self.tree.ids[j],
    base_mae: base_abs[j] / count,
    reconciled_mae: recon_abs[j] / count,
    base_rmse: (base_sq[j] / count).sqrt(),
    reconciled_rmse: (recon_sq[j] / count).sqrt(),
  })
  {
    horizons: actuals.length(),
    base_coherence: before,
    reconciled_coherence: after,
    nodes,
  }
}
