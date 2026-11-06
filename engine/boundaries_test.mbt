///|
test "full supported leaf count remains coherent" {
  let nodes : Array[@tingchao.Node] = [{ id: "root", parent: None, }]
  for i in 0..<64 {
    nodes.push({ id: "n\{i}", parent: Some("root"), })
  }
  let tree = @tingchao.hierarchy(nodes)
  let y = Array::makei(65, i => (i * 13 % 61).to_double())
  let output = tree.fit(@tingchao.Ols).apply(y)
  near(tree.coherence_error(output), 0.0)
  nodes.push({ id: "overflow", parent: Some("root"), })
  try @tingchao.hierarchy(nodes) catch {
    @tingchao.InvalidInput(_) => ()
    _ => fail("expected leaf count validation")
  } noraise {
    _ => fail("too many leaves accepted")
  }
}

///|
test "valid inputs whose projection exceeds the limit are numerical failures" {
  let fitted = three().fit(@tingchao.Ols)
  try fitted.apply([1.0e100, -1.0e100, 1.0e100]) catch {
    @tingchao.NumericalFailure(_) => ()
    _ => fail("supported input must not be misclassified as an input error")
  } noraise {
    _ => fail("out-of-range projection accepted")
  }
}

///|
test "variance ratio limit and maximum horizon are exercised" {
  let tree = three()
  let fitted = tree.fit(@tingchao.Wls, variances=[1.0e-6, 1.0, 1.0e6])
  let y = [100.0, 70.0, 50.0]
  near(tree.coherence_error(fitted.apply(y)), 0.0)
  assert_eq(fitted.apply_many(Array::makei(256, _ => y.copy())).length(), 256)
  try fitted.apply_many(Array::makei(257, _ => y.copy())) catch {
    @tingchao.InvalidInput(_) => ()
    _ => fail("expected horizon validation")
  } noraise {
    _ => fail("too many horizons accepted")
  }
}
