# Sources and contribution boundaries

Maintainer: **Lyllyl789**. License: MIT. The name, three-wave mark and studio visuals were designed for Tingchao; they are not copied from a third-party identity system. Names are project identifiers, not a claim of trademark clearance.

## Mathematical references

The reconciliation equations follow standard weighted least squares and hierarchical forecast reconciliation. The implementation uses Householder reflections, not a translated upstream source tree. [Forecasting: Principles and Practice](https://otexts.com/fpptr/reconciliation.html) is a conceptual reference. No book text or third-party code is redistributed.

## Adjacent MoonBit work

[wjhsb1/time-series-forecasting](https://github.com/wjhsb1/moonbit-time-series-forecasting) provides regular single-series forecasting and backtesting. Tingchao accepts base forecasts and reconciles their aggregation constraints; it does not train the same smoothing models. A future integration could use that package as a forecasting source.

The maintainer's earlier [moon-kalman](https://github.com/Lyllyl789/moon-kalman) covers state estimation and sensor fusion. Tingchao implements a separate tree-constrained batch projection and chronological residual-calibration interface. No previous repository code or Git history was imported. Common mathematical ideas such as least squares do not imply an originality claim over the method itself.

The registry and public repository searches performed on 2026-11-06 found adjacent forecasting and optimization projects but no direct hierarchical forecast reconciliation match under the searched terms. This is a bounded search, not proof that no unpublished or differently named implementation exists. Recheck before submitting the project.

## Runtime and development components

The library and exchange packages use only the MoonBit standard library. The Node.js terminal adapter uses built-in file APIs; the studio uses browser APIs and the compiled MoonBit engine. No third-party frontend assets, fonts, analytics or remote services are required.

Development `.mbtx` utilities use `moonbitlang/async` and, for reading verification fixtures, `moonbitlang/x/fs` through script-mode dependency resolution. Those are tooling dependencies, not imports of the reusable calculation library. MoonBit packages and toolchain components retain their upstream licenses. GitHub CI uses `actions/checkout`, `actions/setup-node`, and a pinned `hustcer/setup-moonbit` revision; those actions are not bundled into the published library.

All `cases/` data are constructed examples authored for this project and distributed under MIT. No private measurements or customer files are included.

## AI assistance and review

Lyllyl789 set the project direction, publication boundary and identity requirements. AI assisted implementation, tests, interface design and documentation. Mathematical checks and command results are recorded separately from product decisions. The current work does not claim that the maintainer has completed a line-by-line manual code review or that a user deployment has occurred. The maintainer retains responsibility for the final review and any submission in their name.
