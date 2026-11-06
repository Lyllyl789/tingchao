///|
/// A named node. Exactly one node has no parent.
pub(all) struct Node {
  id : String
  parent : String?
}

///|
/// Invalid requests and numerical failures are distinct, stable error codes.
pub(all) suberror ReconcileError {
  InvalidInput(String)
  NumericalFailure(String)
}

///|
/// A validated tree. Accessors return owned copies.
pub struct Hierarchy {
  priv ids : Array[String]
  priv parents : Array[Int32]
  priv leaves : Array[Int32]
  priv summing : Array[Array[Double]]
}

///|
pub fn Hierarchy::node_ids(self : Hierarchy) -> Array[String] {
  self.ids.copy()
}

///|
pub fn Hierarchy::leaf_ids(self : Hierarchy) -> Array[String] {
  self.leaves.map(i => self.ids[i])
}

///|
pub fn Hierarchy::node_count(self : Hierarchy) -> Int32 {
  self.ids.length()
}

///|
pub fn Hierarchy::aggregation_matrix(self : Hierarchy) -> Array[Array[Double]] {
  self.summing.map(row => row.copy())
}

///|
fn finite(value : Double) -> Bool {
  value == value && value.abs() <= 1.7976931348623157e308
}

///|
fn checked_value(value : Double) -> Bool {
  finite(value) && value.abs() <= 1.0e100
}
