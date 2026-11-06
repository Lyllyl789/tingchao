///|
/// Estimate diagonal error variances from 3..2048 calibration residual vectors.
/// Sample variances use Welford updates after a common magnitude scaling.
/// `floor_ratio` regularizes zero or tiny variances relative to the largest.
/// Calibration rows must precede and be disjoint from the evaluation holdout.
pub fn Hierarchy::fit_residuals(
  self : Hierarchy,
  residuals : Array[Array[Double]],
  floor_ratio~ : Double = 1.0e-6,
) -> Reconciler raise ReconcileError {
  guard residuals.length() >= 3 && residuals.length() <= 2048 else {
    raise InvalidInput("calibration.size: expected 3..2048 residual vectors")
  }
  guard finite(floor_ratio) && floor_ratio >= 1.0e-12 && floor_ratio <= 1.0 else {
    raise InvalidInput("calibration.floor: expected a ratio in 1e-12..1")
  }
  let n = self.ids.length()
  let mut scale = 0.0
  for row in residuals {
    self.check_vector(row)
    for x in row {
      if x.abs() > scale {
        scale = x.abs()
      }
    }
  }
  if scale == 0.0 {
    return self.fit(Wls, variances=Array::make(n, 1.0))
  }
  let means = Array::make(n, 0.0)
  let m2 = Array::make(n, 0.0)
  for index, row in residuals {
    let count = (index + 1).to_double()
    for j in 0..<n {
      let value = row[j] / scale
      let delta = value - means[j]
      means[j] += delta / count
      m2[j] += delta * (value - means[j])
    }
  }
  let raw = m2.map(x => x / (residuals.length() - 1).to_double())
  let mut largest = 0.0
  for x in raw {
    if x > largest {
      largest = x
    }
  }
  if largest == 0.0 {
    return self.fit(Wls, variances=Array::make(n, 1.0))
  }
  let floor = largest * floor_ratio
  // A common variance multiplier cancels in weighted least squares.
  let normalized = raw.map(v => {
    if v < floor {
      floor / largest
    } else {
      v / largest
    }
  })
  self.fit(Wls, variances=normalized)
}
