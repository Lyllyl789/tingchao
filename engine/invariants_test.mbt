///|
test "seeded trees satisfy weighted stationarity and projection laws" {
  for width in 1..<=12 {
    let nodes : Array[@tingchao.Node] = [{ id: "root", parent: None, }]
    for i in 0..<width {
      nodes.push({ id: "branch-\{i}", parent: Some("root"), })
      for j in 0..<2 {
        nodes.push({ id: "leaf-\{i}-\{j}", parent: Some("branch-\{i}"), })
      }
    }
    let tree = @tingchao.hierarchy(nodes)
    let matrix = tree.aggregation_matrix()
    let y = Array::makei(nodes.length(), i => {
      ((i * 37 + width * 11) % 103 - 40).to_double()
    })
    let variances = Array::makei(nodes.length(), i => (i % 5 + 1).to_double())
    let fitted = tree.fit(@tingchao.Wls, variances~)
    let output = fitted.apply(y)
    near(tree.coherence_error(output), 0.0)
    for column in 0..<tree.leaf_ids().length() {
      // Independently check S' V^-1 (S b - y) = 0.
      let mut gradient = 0.0
      for row in 0..<nodes.length() {
        gradient += matrix[row][column] *
          (output[row] - y[row]) /
          variances[row]
      }
      near(gradient, 0.0)
    }
    let twice = fitted.apply(output)
    for i in 0..<output.length() {
      near(twice[i], output[i])
    }
  }
}

///|
test "reordering nodes changes only vector order" {
  let first = three().fit(@tingchao.Ols).apply([100.0, 70.0, 50.0])
  let shuffled = @tingchao.hierarchy([
      { id: "b", parent: Some("total"), },
      { id: "total", parent: None, },
      { id: "a", parent: Some("total"), },
    ])
    .fit(@tingchao.Ols)
    .apply([50.0, 100.0, 70.0])
  near(shuffled[0], first[2])
  near(shuffled[1], first[0])
  near(shuffled[2], first[1])
}

///|
test "variance scaling has no effect on WLS and equal variances match OLS" {
  let tree = three()
  let y = [200.0, -4.0, 80.0]
  let a = tree.fit(@tingchao.Wls, variances=[2.0, 5.0, 3.0]).apply(y)
  let b = tree.fit(@tingchao.Wls, variances=[20.0, 50.0, 30.0]).apply(y)
  let c = tree.fit(@tingchao.Wls, variances=[7.0, 7.0, 7.0]).apply(y)
  let d = tree.fit(@tingchao.Ols).apply(y)
  for i in 0..<3 {
    near(a[i], b[i])
    near(c[i], d[i])
  }
}
