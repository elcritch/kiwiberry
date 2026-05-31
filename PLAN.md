# Kiwiberry Remaining Plan

The first pure Nim port is implemented and committed. The current code includes
the scalar, strength, variable, expression, constraint, row, symbol, error, and
solver modules, plus translated upstream-style tests for the main solver paths.

This plan tracks only the work still worth doing after the initial port.

## Current State

- Pure Nim implementation lives under `src/kiwiberry/`.
- Root module exports the public API from `src/kiwiberry.nim`.
- `kiwiberry.nimble` no longer depends on Kiwi or cssgrid for normal builds.
- `LICENSE` uses BSD-3-Clause terms based on Kiwi's license.
- Public API docs are present on exported modules, types, procs, and error
  types.
- `README.md` covers basic solving, ref solvers, named constraint
  constructors, strengths, edit variables, variable identity, and DSL caveats.
- README examples are mirrored in `tests/treadme.nim`.
- All upstream Kiwi C++ test files have corresponding Nim coverage:
  `VariableTest`, `TermTest`, `ExpressionTest`, `ConstraintTest`, `StrengthTest`,
  `SolverTest`, and `SimplexTest`.
- The public API includes both value solvers (`initSolver`) and optional ref
  solvers (`newSolver`), plus named constraint constructors `le`, `ge`, and
  `eq`.
- Solver helper aliases support `solver[variable] = strength`,
  `solver.constraint(...)`, `solver.suggest(...)`, and `solver.update()`.
- The variable literal helper is `vars"x"` and is covered by native and
  JavaScript tests.
- `tests/tsolver.nim` passes in debug, release, and danger modes.
- `nimble check` passes.
- `nim test` passes.

## Remaining Work

### Documentation

- Add examples under `examples/` once the API is stable.

### CI And Packaging

- Confirm CI runs `atlas install` and `nim test` on a clean checkout.
- Add a check that the package builds without `deps/kiwi`.
- Decide whether `deps/cssgrid` should remain only as a reference dependency or
  be removed from Atlas metadata entirely.

### Performance

- Add benchmarks based on representative UI layout workloads and Kiwi's
  Enaml-like benchmark shape.
- Profile row cell operations and pivot selection.
- Keep `OrderedTable` until benchmarks show it is the bottleneck.
- If needed, replace row cells with a sorted-vector map while preserving sorted
  iteration order, because that order affects deterministic Kiwi-compatible
  pivot choices.
- Preserve the current behavior test suite before and after any optimization.

### Robustness

- Add sanitizer runs if unsafe code or custom ownership hooks are introduced.
- Audit exception surfaces so solver operations raise only documented catchable
  errors for expected failure modes.

## Acceptance Criteria

- `nim test` passes on a clean checkout.
- The package builds without Kiwi C++ headers or a C++ compiler.
- Public API docs render with useful descriptions.
- README and examples compile.
- Benchmark results are recorded before replacing core data structures.
