///|
test "CSV preserves periods, escapes quotes and represents missing actuals" {
  let input = sample()
  input["nodes"] = [
    { "id": "all", "parent": null },
    { "id": "a,\"b", "parent": "all" },
    { "id": "c", "parent": "all" },
  ]
  input["method"] = "bottom_up"
  input["forecasts"] = [{ "period": 7, "values": [10, 3, 5] }]
  let csv = @exchange.to_csv(
    @exchange.run_request(Json::object(input).stringify()),
  )
  assert_eq(
    csv, "period,node,base,coherent,adjustment,actual\n7,\"all\",10,8,-2,\n7,\"a,\"\"b\",3,3,0,\n7,\"c\",5,5,0,",
  )
}

///|
test "CSV rejects forged report shapes instead of indexing past a vector" {
  let invalid : Json = {
    "status": "ok",
    "node_ids": ["a", "b"],
    "periods": [
      { "period": 1, "base": [1], "coherent": [1], "adjustments": [0] },
    ],
  }
  try @exchange.to_csv(invalid) catch {
    _ => ()
  } noraise {
    _ => fail("invalid CSV report accepted")
  }
}
