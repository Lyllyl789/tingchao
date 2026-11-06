# Library notebook

Import `Lyllyl789/tingchao` and keep forecast vectors in `node_ids()` order.
The leaf order is available separately through `leaf_ids()`.

```mbt check
///|
test "a forecast may disagree with its components" {
  let tree = @tingchao.hierarchy([
    { id: "all", parent: None, },
    { id: "east", parent: Some("all"), },
    { id: "west", parent: Some("all"), },
  ])
  let input = [100.0, 70.0, 50.0]
  let fitted = tree.fit(@tingchao.Ols)
  let result = fitted.apply(input)
  assert_true((result[0] - 320.0 / 3.0).abs() < 1.0e-9)
  assert_true(tree.coherence_error(result) < 1.0e-9)
  assert_eq(input, [100.0, 70.0, 50.0])
}
```

Historical error calibration and evaluation remain separate operations:

```mbt check
///|
test "weights are fixed before evaluating a holdout" {
  let tree = @tingchao.hierarchy([
    { id: "all", parent: None, },
    { id: "east", parent: Some("all"), },
    { id: "west", parent: Some("all"), },
  ])
  let fitted = tree.fit_residuals([
    [-2.0, -1.0, -1.0],
    [0.0, 0.0, 0.0],
    [2.0, 1.0, 1.0],
  ])
  let evaluation = fitted.evaluate([[100.0, 70.0, 50.0]], [[110.0, 60.0, 50.0]])
  assert_eq(evaluation.horizons, 1)
  assert_true(evaluation.reconciled_coherence < 1.0e-9)
}
```

Both examples are checked and tested as package documentation. The caller must
use calibration residuals obtained before the holdout window. Units must be
additive, and child populations must be disjoint.
