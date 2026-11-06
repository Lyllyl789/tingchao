# Verification record · 2026-11-06

## Executed locally

Toolchain: moon `0.1.20261104`, moonc `0.10.20+65efd5b93`. Node.js: `24.22.1`. Platform: Windows x86-64.

| Check | Observed result |
| --- | --- |
| `moon check --target all --deny-warn` | Passed; JS-only adapters are excluded from other targets by package configuration |
| `moon test --target wasm,wasm-gc,js --deny-warn` | 26 tests passed on each target, including two executable documentation examples |
| `moon build --target wasm,wasm-gc,js --deny-warn` | Passed |
| `moon fmt --check` | Passed |
| `moon info` | Public interfaces generated and reviewed |
| `moon run maintenance/build.mbtx --deny-warn` | Browser and terminal release artifacts built; rerunning is supported |
| `moon run maintenance/verify.mbtx --deny-warn` | Four case files passed independent parent-sum, node-coverage, adjustment and CSV checks; exit codes 0/2/3/64/74 passed |

The numerical tests compare against an independently derived scalar projection, then check weighted stationarity on generated multi-level trees. They also cover input mutation, repeated projection, node permutation, shared variance scaling, large inputs, maximum leaves/horizons and numerical-result error classification.

Browser checks observed the retail WLS result, the multi-level energy result, the counterexample's two worsened leaf MAEs, duplicate-key rejection, and invalidation of an old report after source edits. A 390-pixel viewport used a single-column workspace without horizontal document overflow. The engine runs in a replaceable Worker rather than blocking the page.

## Not yet established

- Windows Native tests are blocked by missing MSVC C++ tools and Windows SDK. A successful all-target type check is not a successful Native execution.
- GitHub CI has been configured but has not run remotely.
- The release is not published to Mooncakes. The local package preflight checked the source archive, but registry validation did not complete under the required account. Publication needs the maintainer's own matching registry login.
- The repository remains local. GitHub authentication and author configuration have been checked; the remote repository is not yet created.
- The examples are constructed studies. No independent user deployment or business improvement has been verified.
- Maintainer manual code review and the final one-page application remain outstanding; neither is signed off by this record.

## Reproduce

Use the pinned toolchain and commands from the README, then build before running the file-workflow verifier. Verification outputs are ordinary command results, not a promise that another toolchain or untested platform behaves identically. Generated artifacts and scratch reports are ignored by Git.
