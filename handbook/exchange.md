# File contract · version 0.1

Input is one UTF-8 JSON object. The terminal host accepts a regular file of at most 1 MiB. The shared JSON engine accepts at most 524288 UTF-16 code units and 16 levels of nesting, rejects duplicate keys, and rejects unrecognized properties at each contract level.

```json
{
  "title": "Branch study",
  "unit": "items",
  "nodes": [
    { "id": "total", "parent": null },
    { "id": "a", "parent": "total" },
    { "id": "b", "parent": "total" }
  ],
  "method": "ols",
  "forecasts": [
    { "period": 1, "values": [100, 70, 50], "actual": [110, 60, 50] }
  ]
}
```

`nodes`, `method` and `forecasts` are required. `title` defaults to `Forecast study`, `unit` to `units`. Every node explicitly supplies `id` and `parent`; only the root has a null parent. IDs contain 1–80 UTF-16 code units, no leading/trailing whitespace or control characters. Title and unit limits are 160 and 40 code units, without controls. IDs are data, never markup.

Each forecast row supplies a strictly increasing 32-bit integer `period` and a `values` array in node order. Optional `actual` is null, absent, or a coherent array in the same order. Missing observations are omitted from accuracy evaluation, not filled with zeros. All forecasts must be complete; use a smaller complete hierarchy rather than inventing missing forecasts.

`method` is `bottom_up`, `ols` or `wls`. WLS requires exactly one of:

- `variances`: one positive finite diagonal error variance per node;
- `calibration`: 3–2048 rows of `{ "period": -1, "residuals": [...] }`, in strict period order, all before the first forecast period. Optional `floor_ratio` belongs only to calibration and must be in `1e-12..1`, default `1e-6`.

Changing from WLS to another method requires removing calibration-only fields. The studio does this when a method change is explicitly requested, temporarily retaining those weights so switching back works. Editing or importing source clears that saved calibration to avoid applying stale weights to different data. Direct calculations pass the source unchanged so the core can reject duplicate keys.

Successful reports contain node/leaf IDs, relative or explicit variances, calibration row count, per-period base/coherent/adjustment vectors, coherence discrepancies, and optional MAE/RMSE evaluation. Error reports use `invalid` or `numerical_failure` and a stable field-code message without echoing source text.

| CLI exit | Meaning |
| --- | --- |
| 0 | Successful report or help |
| 2 | Invalid request |
| 3 | Supported request could not be solved reliably |
| 64 | Incorrect command usage |
| 74 | File type, size, UTF-8 or read failure |

JSON reports go to standard output, including validation errors. File and usage diagnostics go to standard error without reflecting the supplied filename. CSV output has one row per period and node: `period,node,base,coherent,adjustment,actual`; IDs are quoted and embedded quotes doubled. CSV is a data exchange format: import its ID column as text in a spreadsheet rather than treating identifiers as formulas. JSON is preferred when preserving types.
