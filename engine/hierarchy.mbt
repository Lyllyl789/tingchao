///|
/// Validate a rooted tree of at most 128 nodes and 64 leaves.
/// Node order is preserved in every forecast vector and result.
pub fn hierarchy(nodes : Array[Node]) -> Hierarchy raise ReconcileError {
  let n = nodes.length()
  guard n > 0 && n <= 128 else {
    raise InvalidInput("tree.size: expected 1..128 nodes")
  }
  let positions : Map[String, Int32] = Map([])
  let ids : Array[String] = []
  for i, node in nodes {
    guard node.id.length() > 0 &&
      node.id.length() <= 80 &&
      node.id.trim().to_owned() == node.id else {
      raise InvalidInput(
        "tree.id: expected a nonblank id of at most 80 code units",
      )
    }
    for c in node.id {
      guard c.to_int() >= 32 && c.to_int() != 127 else {
        raise InvalidInput("tree.id: control characters are not allowed")
      }
    }
    guard !positions.contains(node.id) else {
      raise InvalidInput("tree.duplicate: node ids must be unique")
    }
    positions[node.id] = i
    ids.push(node.id)
  }
  let parents = Array::make(n, -1)
  let child_counts = Array::make(n, 0)
  let mut roots = 0
  for i, node in nodes {
    match node.parent {
      None => roots += 1
      Some(parent) => {
        guard positions.get(parent) is Some(p) else {
          raise InvalidInput("tree.parent: parent id does not exist")
        }
        guard p != i else {
          raise InvalidInput("tree.cycle: a node cannot parent itself")
        }
        parents[i] = p
        child_counts[p] += 1
      }
    }
  }
  guard roots == 1 else {
    raise InvalidInput("tree.root: expected exactly one root")
  }
  for start in 0..<n {
    let mut current = start
    let mut depth = 0
    while current >= 0 {
      depth += 1
      guard depth <= n else {
        raise InvalidInput("tree.cycle: parent chain contains a cycle")
      }
      guard depth <= 32 else {
        raise InvalidInput("tree.depth: expected at most 32 levels")
      }
      current = parents[current]
    }
  }
  let leaves : Array[Int32] = []
  for i in 0..<n {
    if child_counts[i] == 0 {
      leaves.push(i)
    }
  }
  guard leaves.length() <= 64 else {
    raise InvalidInput("tree.leaves: expected at most 64 leaves")
  }
  let summing = Array::makei(n, _ => Array::make(leaves.length(), 0.0))
  for column, leaf in leaves {
    let mut current = leaf
    while current >= 0 {
      summing[current][column] = 1.0
      current = parents[current]
    }
  }
  { ids, parents, leaves, summing, }
}

///|
/// Aggregate leaf values in the order returned by `leaf_ids`.
pub fn Hierarchy::aggregate(
  self : Hierarchy,
  values : Array[Double],
) -> Array[Double] raise ReconcileError {
  guard values.length() == self.leaves.length() else {
    raise InvalidInput("values.shape: expected one value per leaf")
  }
  for value in values {
    guard checked_value(value) else {
      raise InvalidInput(
        "values.number: expected finite magnitude at most 1e100",
      )
    }
  }
  self.summing.map(row => {
    let mut total = 0.0
    let mut correction = 0.0
    for i, coefficient in row {
      let term = coefficient * values[i] - correction
      let next = total + term
      correction = next - total - term
      total = next
    }
    total
  })
}

///|
/// Largest direct parent-minus-children discrepancy, in the input unit.
pub fn Hierarchy::coherence_error(
  self : Hierarchy,
  values : Array[Double],
) -> Double raise ReconcileError {
  self.check_vector(values)
  let sums = Array::make(self.ids.length(), 0.0)
  let counts = Array::make(self.ids.length(), 0)
  for i, p in self.parents {
    if p >= 0 {
      sums[p] += values[i]
      counts[p] += 1
    }
  }
  let mut largest = 0.0
  for i in 0..<self.ids.length() {
    if counts[i] > 0 {
      let error = (values[i] - sums[i]).abs()
      if error > largest {
        largest = error
      }
    }
  }
  largest
}

///|
fn Hierarchy::check_vector(
  self : Hierarchy,
  values : Array[Double],
) -> Unit raise ReconcileError {
  guard values.length() == self.ids.length() else {
    raise InvalidInput("forecast.shape: expected one value per node")
  }
  for value in values {
    guard checked_value(value) else {
      raise InvalidInput(
        "forecast.number: expected finite magnitude at most 1e100",
      )
    }
  }
}
