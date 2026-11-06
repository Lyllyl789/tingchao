///|
fn object(value : Json) -> Map[String, Json] raise @tide.ReconcileError {
  guard value is Object(fields) else {
    raise @tide.InvalidInput("json.object: expected an object")
  }
  fields
}

///|
fn allowed(
  fields : Map[String, Json],
  names : Array[String],
) -> Unit raise @tide.ReconcileError {
  for key in fields.keys() {
    guard names.contains(key) else {
      raise @tide.InvalidInput("json.field: unrecognized property")
    }
  }
}

///|
fn required(
  fields : Map[String, Json],
  key : String,
) -> Json raise @tide.ReconcileError {
  match fields.get(key) {
    Some(value) => value
    None => raise @tide.InvalidInput("json.required: missing " + key)
  }
}

///|
fn array(value : Json) -> Array[Json] raise @tide.ReconcileError {
  guard value is Array(items) else {
    raise @tide.InvalidInput("json.array: expected an array")
  }
  items
}

///|
fn text(value : Json, limit : Int32) -> String raise @tide.ReconcileError {
  guard value is String(s) && s.length() > 0 && s.length() <= limit else {
    raise @tide.InvalidInput("json.text: invalid text length or type")
  }
  for c in s {
    guard c.to_int() >= 32 && c.to_int() != 127 else {
      raise @tide.InvalidInput("json.text: control characters are not allowed")
    }
  }
  s
}

///|
fn period(fields : Map[String, Json]) -> Int32 raise @tide.ReconcileError {
  let value = number(required(fields, "period"))
  guard value >= -2147483648.0 && value <= 2147483647.0 else {
    raise @tide.InvalidInput("period.integer: expected a 32-bit integer")
  }
  let tick = value.to_int()
  guard tick.to_double() == value else {
    raise @tide.InvalidInput("period.integer: expected a 32-bit integer")
  }
  tick
}

///|
fn vector(value : Json) -> Array[Double] raise @tide.ReconcileError {
  @json.from_json(value) catch {
    _ => raise @tide.InvalidInput("json.vector: expected numeric values")
  }
}

///|
fn number(value : Json) -> Double raise @tide.ReconcileError {
  @json.from_json(value) catch {
    _ => raise @tide.InvalidInput("json.number: expected a number")
  }
}

///|
fn describe_mode(mode : @tide.Method) -> String {
  match mode {
    @tide.BottomUp => "bottom_up"
    @tide.Ols => "ols"
    @tide.Wls => "wls"
  }
}
