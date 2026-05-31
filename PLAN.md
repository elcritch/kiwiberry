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
- `README.md` contains runnable basic and edit-variable examples.
- `nim test` passes.

## Remaining Work

### API Polish

- Decide whether to add optional `newSolver()` as a ref wrapper around the value
  `Solver` for users who want shared solver identity.
- Review the `==`, `<=`, and `>=` constraint DSL against Nim overload behavior,
  especially scalar-left and variable-variable expressions.
- Consider adding explicit named constructors for constraints, such as
  `le(left, right)`, `ge(left, right)`, and `eq(left, right)`, as an escape hatch
  if operator overloads are ambiguous in user code.
- Add doc comments to exported types and procs so `nim doc` renders useful API
  docs.

### Compatibility Coverage

- Finish translating any upstream unit-test details not yet covered from:
  - `VariableTest.cpp`
  - `TermTest.cpp`
  - `ExpressionTest.cpp`
  - `ConstraintTest.cpp`
  - `SolverTest.cpp`
  - `SimplexTest.cpp`
- Add a dedicated compile-only test for DSL examples that are likely to hit Nim
  overload ambiguity.
- Add tests for removing constraints and edit variables after multiple pivots.
- Add tests for repeated `reset` and reuse of variables created before reset.

### Documentation

- Expand `README.md` with:
  - constraint strength semantics
  - edit-variable workflow
  - variable identity and `sameVariable`
  - known Nim DSL caveats
- Add examples under `examples/` once the API is stable.
- Verify README snippets compile, either manually or through a small test.

### CI And Packaging

- Confirm CI runs `atlas install` and `nim test` on a clean checkout.
- Add a check that the package builds without `deps/kiwi`.
- Decide whether `deps/cssgrid` should remain only as a reference dependency or
  be removed from Atlas metadata entirely.
- Run `nimble check` or the Atlas equivalent before publishing.

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

- Run tests under release and danger modes:
  - `nim c -d:release -r tests/tsolver.nim`
  - `nim c -d:danger -r tests/tsolver.nim`
- Add sanitizer runs if unsafe code or custom ownership hooks are introduced.
- Audit exception surfaces so solver operations raise only documented catchable
  errors for expected failure modes.

## Acceptance Criteria

- `nim test` passes on a clean checkout.
- The package builds without Kiwi C++ headers or a C++ compiler.
- Public API docs render with useful descriptions.
- README and examples compile.
- Benchmark results are recorded before replacing core data structures.
