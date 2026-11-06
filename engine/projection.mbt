///|
/// Solve a full-column-rank weighted least-squares system using Householder QR.
/// Row scaling and response normalization avoid normal equations and inverses.
fn solve_leaves(
  tree : Hierarchy,
  forecast : Array[Double],
  variances : Array[Double],
) -> Array[Double] raise ReconcileError {
  let n = tree.ids.length()
  let p = tree.leaves.length()
  let mut smallest = variances[0]
  let mut response_scale = 1.0
  for i in 0..<n {
    if variances[i] < smallest {
      smallest = variances[i]
    }
    if forecast[i].abs() > response_scale {
      response_scale = forecast[i].abs()
    }
  }
  let weights = variances.map(v => (smallest / v).sqrt())
  let a = Array::makei(n, i => tree.summing[i].map(s => s * weights[i]))
  let b = Array::makei(n, i => forecast[i] / response_scale * weights[i])
  for k in 0..<p {
    let mut squared_norm = 0.0
    for i in k..<n {
      squared_norm += a[i][k] * a[i][k]
    }
    let norm = squared_norm.sqrt()
    guard finite(norm) && norm > 1.0e-12 else {
      raise NumericalFailure(
        "solve.rank: weighted aggregation matrix is ill-conditioned",
      )
    }
    let alpha = if a[k][k] >= 0.0 { -norm } else { norm }
    let v = Array::makei(n - k, i => a[k + i][k])
    v[0] -= alpha
    let mut vv = 0.0
    for x in v {
      vv += x * x
    }
    let beta = 2.0 / vv
    for j in k..<p {
      let mut dot = 0.0
      for i in k..<n {
        dot += v[i - k] * a[i][j]
      }
      for i in k..<n {
        a[i][j] -= beta * v[i - k] * dot
      }
    }
    let mut dot = 0.0
    for i in k..<n {
      dot += v[i - k] * b[i]
    }
    for i in k..<n {
      b[i] -= beta * v[i - k] * dot
    }
  }
  let solution = Array::make(p, 0.0)
  for step in 0..<p {
    let i = p - 1 - step
    let mut value = b[i]
    for j in (i + 1)..<p {
      value -= a[i][j] * solution[j]
    }
    solution[i] = value / a[i][i]
    guard finite(solution[i]) else {
      raise NumericalFailure("solve.overflow: result is not finite")
    }
  }
  solution.map(x => x * response_scale)
}
