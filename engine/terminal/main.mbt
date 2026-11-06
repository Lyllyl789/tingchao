///|
fn main {
  let args = arguments()
  if args.length() == 1 && args[0] == "--help" {
    println(
      "Tingchao · coherent forecasts\nUsage: tingchao REQUEST.json [--csv]\nJSON output by default; --csv emits one row per period and node.",
    )
    return
  }
  guard args.length() == 1 || (args.length() == 2 && args[1] == "--csv") else {
    diagnostic("Usage: tingchao REQUEST.json [--csv]")
    exit(64)
    return
  }
  let input = read_request(args[0])
  guard input[0] == "ok" else {
    diagnostic(input[1])
    exit(74)
    return
  }
  let output = @exchange.process(input[1])
  let parsed = try! @json.parse(output)
  guard parsed is { "status": "ok", .. } else {
    println(output)
    exit(if parsed is { "status": "invalid", .. } { 2 } else { 3 })
    return
  }
  if args.length() == 2 {
    println(try! @exchange.to_csv(parsed))
  } else {
    println(output)
  }
}
