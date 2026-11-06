///|
test "tree preserves input order while aggregating leaves" {
  let tree = @tingchao.hierarchy([
    { id: "east", parent: Some("all"), },
    { id: "all", parent: None, },
    { id: "west", parent: Some("all"), },
  ])
  assert_eq(tree.node_count(), 3)
  assert_eq(tree.leaf_ids(), ["east", "west"])
  assert_eq(tree.aggregate([70.0, 50.0]), [70.0, 120.0, 50.0])
  assert_eq(tree.coherence_error([70.0, 100.0, 50.0]), 20.0)
  assert_eq(tree.coherence_error([70.0, 120.0, 50.0]), 0.0)
}

///|
test "aggregation accessors do not expose internal arrays" {
  let tree = @tingchao.hierarchy([{ id: "one", parent: None, }])
  let ids = tree.node_ids()
  ids[0] = "changed"
  let matrix = tree.aggregation_matrix()
  matrix[0][0] = 9.0
  assert_eq(tree.node_ids(), ["one"])
  assert_eq(tree.aggregate([4.0]), [4.0])
}

///|
test "invalid parent graph is rejected" {
  let inputs : Array[Array[@tingchao.Node]] = [
    [],
    [{ id: "a", parent: None, }, { id: "a", parent: Some("a"), }],
    [{ id: "a", parent: Some("missing"), }],
    [{ id: "a", parent: None, }, { id: "b", parent: None, }],
    [
      { id: "root", parent: None, },
      { id: "a", parent: Some("b"), },
      { id: "b", parent: Some("a"), },
    ],
    [{ id: " leading", parent: None, }],
  ]
  for nodes in inputs {
    try @tingchao.hierarchy(nodes) catch {
      @tingchao.ReconcileError::InvalidInput(_) => ()
      _ => fail("expected tree validation error")
    } noraise {
      _ => fail("invalid tree accepted")
    }
  }
}
