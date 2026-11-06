///|
fn three() -> @tingchao.Hierarchy raise {
  @tingchao.hierarchy([
    { id: "total", parent: None, },
    { id: "a", parent: Some("total"), },
    { id: "b", parent: Some("total"), },
  ])
}

///|
fn near(actual : Double, expected : Double) -> Unit raise {
  assert_true((actual - expected).abs() <= 1.0e-10 * (1.0 + expected.abs()))
}

///|
test "OLS matches the analytic orthogonal projection onto total=a+b" {
  let tree = three()
  let fitted = tree.fit(@tingchao.Ols)
  let input = [100.0, 70.0, 50.0]
  let result = fitted.apply(input)
  near(result[0], 320.0 / 3.0)
  near(result[1], 190.0 / 3.0)
  near(result[2], 130.0 / 3.0)
  near(tree.coherence_error(result), 0.0)
  assert_eq(input, [100.0, 70.0, 50.0])
  let again = fitted.apply(result)
  for i in 0..<3 {
    near(again[i], result[i])
  }
}

///|
test "WLS matches an independent one-constraint solution" {
  let tree = three()
  let variances = [4.0, 1.0, 1.0]
  let fitted = tree.fit(@tingchao.Wls, variances~)
  variances[0] = 99.0
  let result = fitted.apply([100.0, 70.0, 50.0])
  // For C=[1,-1,-1], correction = -V C' (C V C')^-1 C y.
  near(result[0], 100.0 + 80.0 / 6.0)
  near(result[1], 70.0 - 20.0 / 6.0)
  near(result[2], 50.0 - 20.0 / 6.0)
  let weights = fitted.error_variances()
  weights[0] = 7.0
  assert_eq(fitted.error_variances(), [4.0, 1.0, 1.0])
}

///|
test "bottom-up uses leaf forecasts and accepts a single-node hierarchy" {
  let tree = three()
  assert_eq(tree.fit(@tingchao.BottomUp).apply([100.0, 70.0, 50.0]), [
    120.0, 70.0, 50.0,
  ])
  let single = @tingchao.hierarchy([{ id: "one", parent: None, }])
  near(single.fit(@tingchao.Ols).apply([4.0])[0], 4.0)
}

///|
test "OLS is linear, keeps negative solutions and tolerates large magnitudes" {
  let fitted = three().fit(@tingchao.Ols)
  let a = fitted.apply([10.0, -30.0, 20.0])
  assert_true(a[1] < 0.0)
  let large = fitted.apply([1.0e80, -3.0e80, 2.0e80])
  for i in 0..<3 {
    near(large[i] / 1.0e79, a[i])
  }
}

///|
test "invalid numeric vectors and variances fail without partial output" {
  let tree = three()
  for values in [[1.0], [1.0, 0.0 / 0.0, 2.0], [1.0, 1.0e200, 2.0]] {
    try tree.fit(@tingchao.Ols).apply(values) catch {
      @tingchao.ReconcileError::InvalidInput(_) => ()
      _ => fail("expected validation error")
    } noraise {
      _ => fail("invalid vector accepted")
    }
  }
  for values in [[1.0], [0.0, 1.0, 1.0], [1.0e-20, 1.0, 1.0]] {
    try tree.fit(@tingchao.Wls, variances=values) catch {
      @tingchao.ReconcileError::InvalidInput(_) => ()
      _ => fail("expected variance error")
    } noraise {
      _ => fail("invalid variance accepted")
    }
  }
}
