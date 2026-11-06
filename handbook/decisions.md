# Design ledger

## 2026-11-06 · Scope before implementation

Hierarchical forecast reconciliation is the product's central capability: make independently produced total and component forecasts coherent, then measure the accuracy tradeoff. Forecast generation is deliberately a separate concern, so the library can accept predictions from different models.

The first release accepts a single rooted tree, finite point forecasts and optional historical residuals. It will offer bottom-up, ordinary least squares and diagonal variance-weighted reconciliation. Forecast model training, grouped DAGs, nonnegative optimization and MinT covariance shrinkage are outside this release.

Numerical reconciliation must solve a weighted least-squares problem without explicitly inverting a matrix. Coherence is a constraint, not evidence that forecast accuracy has improved. Holdout actuals must not be used to fit reconciliation weights.

## 2026-11-06 · Verification changes the implementation

The first projection tests exposed invalid scientific-literal spelling. This was corrected without rewriting history, and the commit gate was extended to run formatting and both Wasm and JavaScript tests before subsequent commits.

An exchange test showed that generic integer decoding accepted a fractional period. Periods now undergo explicit bounds and round-trip checks before conversion; a regression test covers this case. Duplicate-key and chronological-separation tests accompany the contract.

Variance calibration uses a common scaling factor and Welford sample variance. Near-zero columns are regularized by an explicit relative floor; all-constant calibration falls back to equal weights. The report exposes the resulting relative variances so callers can review this choice.

## 2026-11-06 · Application boundary

The terminal and browser call the same JSON exchange package. The browser runs it in a replaceable Worker, discards old reports when input changes, supports cancellation, and stops work after 15 seconds. The local server serves a fixed allowlist of application assets; requests cannot browse repository files.

Source text is passed verbatim on direct calculation, allowing the MoonBit decoder to detect duplicate keys. An explicit method change rewrites the request and removes inapplicable calibration fields. Every constructed case remains clearly separated from real deployment evidence.
