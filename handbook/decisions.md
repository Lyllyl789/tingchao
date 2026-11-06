# Design ledger

## 2026-11-06 · Scope before implementation

The owner selected hierarchical forecast reconciliation after reviewing five project directions. The requested product is a reusable MoonBit library with a working application, a distinctive identity, verifiable development and an owner-only Git identity. Remote publication is deferred until explicit approval.

The first release accepts a single rooted tree, finite point forecasts and optional historical residuals. It will offer bottom-up, ordinary least squares and diagonal variance-weighted reconciliation. Forecast model training, grouped DAGs, nonnegative optimization and MinT covariance shrinkage are outside this release.

Numerical reconciliation must solve a weighted least-squares problem without explicitly inverting a matrix. Coherence is a constraint, not evidence that forecast accuracy has improved. Holdout actuals must not be used to fit reconciliation weights.

Implementation and automated checks are AI-assisted. Product direction and publication authority belong to the owner. No claim of a completed owner code review or deployed customer use is made.
