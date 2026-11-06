# Reconciliation, with its assumptions visible

Let `b` contain the leaf forecasts, and let `S` be the summing matrix of a single rooted tree. A coherent vector is `S b`. Each row of `S` contains 1 for descendant leaves and 0 otherwise; leaf rows contain an identity matrix, so `S` has full column rank.

For base forecasts `y` and a positive diagonal residual variance matrix `V`, the weighted solution minimizes

```
sum_i ((S b)_i - y_i)^2 / V_i
```

OLS sets every variance to 1. Bottom-up simply keeps the original leaf forecasts and aggregates them. WLS uses explicit variances or sample variances estimated from earlier residuals. A common multiplier on all variances has no effect on the minimizer.

The implementation multiplies row `i` by `sqrt(min(V)/V_i)` and scales the response by its largest absolute magnitude (at least 1). Householder QR triangularizes the resulting least-squares system. Back-substitution recovers leaves; all reported nodes are reconstructed from those leaves. It never forms a matrix inverse or solves the normal equations.

## Calibration

`fit_residuals` accepts 3–2048 residual vectors, with columns in node order. Welford updates estimate sample variance after scaling all residuals by one common factor. Variances are normalized by their maximum and floored at a configurable relative fraction; the default is `1e-6`. All-zero or constant residual columns across the entire matrix fall back to equal weights. Thus the returned `error_variances()` are relative weights, not a physical-unit variance estimate or a prediction interval. Mean residual bias is not corrected by this method.

The JSON interface checks strictly increasing integer periods and requires every calibration period to precede the forecast window. It evaluates supplied actuals using fixed weights; it never fits on holdout actuals. The library's raw array API has no timestamps, so chronology is the caller's responsibility. Neither interface can establish whether a caller's upstream forecasting model was trained without leakage.

## Numeric and structural limits

- 1–128 nodes, 1–64 leaves, a single root, at most 32 levels.
- 1–256 forecast vectors per request.
- Finite forecast, actual and residual magnitudes at most `1e100`.
- Explicit variances in `1e-100..1e100`, with largest/smallest ratio at most `1e12`.
- A QR column norm at or below `1e-12` is rejected as numerically unreliable.
- Observed parent totals must agree with child sums within `1e-9 * max(1, max_abs(actual))`.

These are deliberate support limits, not a throughput guarantee. Negative values remain unchanged by any business clipping rule. Rounding the display does not round the underlying report. OLS and WLS can move leaf forecasts away from accurate values; the included counterexample demonstrates this.

## Independent checks

For a total and two leaves, the constraint is `C = [1,-1,-1]`. Its exact projection is `y - V C' (C V C')^-1 C y`. Tests calculate this scalar expression independently of QR. Further generated multi-level trees check `S' V^-1 (result-y) = 0`, coherence, idempotence, node-order invariance and common-variance scaling. Since the objective is strictly convex for this supported tree, coherence and stationarity identify the unique least-squares minimizer.

The equations are standard mathematical methods. The MoonBit implementation is original to this repository; no source code was ported. Background: [Hyndman and Athanasopoulos, forecast reconciliation](https://otexts.com/fpptr/reconciliation.html). MinT covariance shrinkage and nonnegative constrained solutions are intentionally outside version 0.1.
