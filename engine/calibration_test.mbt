///|
test "sample residual variances determine fixed WLS weights" {
  let tree = three()
  let fitted = tree.fit_residuals([
    [-2.0, -1.0, -1.0],
    [0.0, 0.0, 0.0],
    [2.0, 1.0, 1.0],
  ])
  assert_eq(fitted.error_variances(), [1.0, 0.25, 0.25])
  let result = fitted.apply([100.0, 70.0, 50.0])
  near(result[0], 100.0 + 80.0 / 6.0)
}

///|
test "zero residual variance has explicit OLS fallback and floor" {
  let tree = three()
  assert_eq(
    tree
    .fit_residuals([[0.0, 0.0, 0.0], [0.0, 0.0, 0.0], [0.0, 0.0, 0.0]])
    .error_variances(),
    [1.0, 1.0, 1.0],
  )
  assert_eq(
    tree
    .fit_residuals(
      [[-1.0, 2.0, 2.0], [0.0, 2.0, 2.0], [1.0, 2.0, 2.0]],
      floor_ratio=0.01,
    )
    .error_variances(),
    [1.0, 0.01, 0.01],
  )
}

///|
test "holdout reports show that coherence need not improve accuracy" {
  let fitted = three().fit(@tingchao.Ols)
  let report = fitted.evaluate([[0.0, 50.0, 50.0]], [[100.0, 50.0, 50.0]])
  assert_eq(report.horizons, 1)
  near(report.base_coherence, 100.0)
  near(report.reconciled_coherence, 0.0)
  near(report.nodes[1].base_mae, 0.0)
  assert_true(report.nodes[1].reconciled_mae > 0.0)
}

///|
test "evaluation requires coherent actuals and aligned horizons" {
  let fitted = three().fit(@tingchao.Ols)
  for actuals in [[], [[100.0, 70.0, 50.0]]] {
    try fitted.evaluate([[100.0, 70.0, 50.0]], actuals) catch {
      @tingchao.ReconcileError::InvalidInput(_) => ()
      _ => fail("expected actuals error")
    } noraise {
      _ => fail("invalid actuals accepted")
    }
  }
}
