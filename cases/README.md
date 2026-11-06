# Four reproducible studies

All names, forecasts, residuals and actuals in this directory are constructed examples under the repository's MIT license. They are not measured business data, customer deployments or evidence of financial savings.

| Study | Input | Expected decision support |
| --- | --- | --- |
| `retail.json` | Branch forecasts, earlier error calibration and a later observed holdout | Compare a fixed WLS adjustment with the original branch and total forecasts before preparing an order plan. |
| `energy.json` | A two-level building hierarchy in one energy unit | Make the park, area and building projections add up; examine the adjustment at each level. |
| `visitors.json` | Three disjoint visitor counts and a total | Preserve leaf forecasts with bottom-up aggregation and check the total against observed counts. Visitors counted in multiple zones must be deduplicated before using this tree. |
| `accuracy-tradeoff.json` | Accurate leaf forecasts and an inaccurate total | Observe a leaf accuracy loss despite perfect coherence. |

Periods are ordered integer ticks. Calibration ticks strictly precede forecast ticks. The report evaluates only forecast rows with supplied actuals, without refitting weights on those actuals. Calibration residuals should come from genuine out-of-sample predictions made before the evaluation window. The program can check tick separation, but cannot establish how externally supplied forecasts were trained.

Before using real data, verify additive units, disjoint leaves, common time buckets and complete observed totals. Compare against the raw forecasts on several chronological windows. Keep cases where reconciliation makes forecasts worse.
