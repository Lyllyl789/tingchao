///|
fn cell(value : String) -> String {
  // Every identifier is quoted; this is a data exchange CSV, not an executable sheet.
  "\"" + value.replace(old="\"", new="\"\"") + "\""
}

///|
/// Export a successful report to tidy CSV in period and node order.
/// Consumers opening CSV in spreadsheet software should import ids as text.
pub fn to_csv(report : Json) -> String raise @tide.ReconcileError {
  guard report
    is { "status": "ok", "node_ids": Array(ids), "periods": Array(rows), .. } else {
    raise @tide.InvalidInput(
      "csv.report: expected a successful reconciliation report",
    )
  }
  let lines : Array[String] = ["period,node,base,coherent,adjustment,actual"]
  for item in rows {
    let row = object(item)
    let tick = period(row)
    let base = vector(required(row, "base"))
    let coherent = vector(required(row, "coherent"))
    let adjustments = vector(required(row, "adjustments"))
    let actual = match row.get("actual") {
      None | Some(Null) => None
      Some(value) => Some(vector(value))
    }
    guard base.length() == ids.length() &&
      coherent.length() == ids.length() &&
      adjustments.length() == ids.length() else {
      raise @tide.InvalidInput("csv.shape: report vectors do not match nodes")
    }
    if actual is Some(values) && values.length() != ids.length() {
      raise @tide.InvalidInput("csv.shape: actuals do not match nodes")
    }
    for i, id in ids {
      let observed = match actual {
        Some(values) => values[i].to_string()
        None => ""
      }
      lines.push(
        "\{tick},\{cell(text(id, 80))},\{base[i]},\{coherent[i]},\{adjustments[i]},\{observed}",
      )
    }
  }
  lines.join("\n")
}
