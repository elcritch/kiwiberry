# Pure Nim Kiwi Port Plan

## Objective

Port `deps/kiwi/` to a pure Nim implementation under `src/kiwiberry/`, keeping the Cassowary solver behavior and public ergonomics of Kiwi while using idiomatic Nim data shapes. The finished package should not need the C++ Kiwi dependency for normal builds.

Primary references:

- `deps/kiwi/kiwi/*.h`: source behavior and algorithm.
- `deps/kiwi/tests/*.cpp`: compatibility test oracle.
- `deps/cssgrid/src/cssgrid/numberTypes.nim`: distinct scalar types and borrowed numeric operations.
- `deps/cssgrid/src/cssgrid/constraints.nim`: discriminated objects, compact constructors, and operator helpers for constraint-like data.
- `deps/cssgrid/src/cssgrid/gridtypes.nim`: plain data objects for value concepts and ref objects only for mutable identity-bearing concepts.

## API Design Direction

Apply the Nim API design rules from the `nim-api-design` skill:

- Use plain `object` types for value data: `Term`, `Expression`, `Symbol`, `Row`, `Tag`, and `EditInfo`.
- Use `ref object` only where Kiwi's contract requires identity and shared mutation:
  - `Variable`, because copies must refer to the same variable value.
  - `Constraint`, because add/remove/duplicate checks are identity-based in Kiwi.
- Use a value `Solver` with `initSolver()` and `var Solver` receiver procs. Disable accidental solver copying in the implementation if practical. Add `newSolver()` only as an optional handle wrapper if user code needs shared solver identity.
- Keep domain concepts distinct: `KiwiScalar`, `Strength`, `VariableId`, and `SymbolId` should not be interchangeable raw numbers.
- Use `newX()` for ref constructors, `initX()` for value constructors, and `toX()` for conversions.
- Keep required operations strict: duplicate/unknown/unsatisfiable states raise specific catchable exceptions.
- Keep optional checks explicit with `hasConstraint`, `hasEditVariable`, `sameVariable`, and `violated`.

Proposed public surface:

```nim
import kiwiberry

var solver = initSolver()
let x = newVariable("x")
let y = newVariable("y")

solver.addConstraint(x + y == 10)
solver.addConstraint(x - y == 4)
solver.updateVariables()

doAssert x.value == 7.KiwiScalar
doAssert y.value == 3.KiwiScalar
```

Public modules:

- `kiwiberry/scalars.nim`: `KiwiScalar`, numeric borrowing, literal/conversion helpers, and `nearZero`.
- `kiwiberry/strengths.nim`: `Strength`, `required`, `strong`, `medium`, `weak`, `createStrength`, and `clip`.
- `kiwiberry/variables.nim`: `Variable`, `newVariable`, `name`, `name=`, `value`, `value=`, `sameVariable`, `$`, and `hash`.
- `kiwiberry/expressions.nim`: `Term`, `Expression`, `initTerm`, `initExpression`, `toExpression`, arithmetic operators.
- `kiwiberry/constraints.nim`: `Relation`, `Constraint`, relational operators, `withStrength`, `|`, `violated`, and constraint identity hashing.
- `kiwiberry/errors.nim`: solver exception types.
- `kiwiberry/solver.nim`: public solver operations.
- `kiwiberry/internal/*.nim`: `symbols`, `rows`, and simplex implementation details.
- `kiwiberry/debug.nim`: `dump`/`dumps` equivalents.
- `kiwiberry.nim`: root module exporting the stable public surface only.

## Phase 1: Licensing And Package Metadata

- Keep the project on Kiwi's Modified BSD / BSD-3-Clause terms.
- Retain the Nucleic Development Team copyright and license notice for the port.
- Add Kiwiberry contributor attribution for Nim-specific changes.
- Update `kiwiberry.nimble` to `license = "BSD-3-Clause"`.
- Add source headers only if the codebase adopts file-level headers; otherwise rely on root `LICENSE`.

Done when:

- Root `LICENSE` exists and contains BSD-3-Clause terms based on Kiwi's license.
- Package metadata does not conflict with the license file.

## Phase 2: Scalar, Strength, And Symbolic Types

Implement scalar and symbolic primitives before the solver:

- Define `KiwiScalar* = distinct float64` by default. Consider a `kiwiberry.scalar` compile-time switch only after the float64 port is correct.
- Borrow arithmetic/comparison operations following cssgrid's `UiScalar` pattern.
- Define `Strength* = distinct KiwiScalar` and make strength construction explicit.
- Port Kiwi's strength formula exactly:
  - clamp each component to `0..1000`
  - combine as `a * 1_000_000 + b * 1_000 + c`
  - `required = createStrength(1000, 1000, 1000)`
- Define private `SymbolKind = enum skInvalid, skExternal, skSlack, skError, skDummy`.
- Define private `Symbol = object` with `kind` and `id`, plus equality/hash/order helpers.

Done when:

- Translated strength tests pass.
- `nearZero` matches Kiwi's `1.0e-8` tolerance.
- Distinct scalar values remain ergonomic in expressions with ordinary numeric literals.

## Phase 3: Variable, Term, Expression, And Constraint DSL

Build the public symbolic API independently from the simplex solver:

- `Variable` is a ref object with private `id`, `name`, and mutable `value`.
- `newVariable(name = "")` allocates identity. `sameVariable(a, b)` checks identity.
- `Term` stores `variable` and `coefficient`.
- `Expression` stores `seq[Term]` plus `constant`.
- `Constraint` is a ref object with reduced expression, relation, strength, and private identity.
- Reduce constraint terms by variable identity when a constraint is constructed, matching `Constraint::reduce`.
- Overload arithmetic for `Variable`, `Term`, `Expression`, and numeric constants.
- Overload `<=`, `>=`, and `==` to create constraints. Because `==` becomes DSL syntax, use `sameVariable` for variable identity checks.
- Overload `|` and add `withStrength` to return a new constraint with the same expression/relation and a new strength.

Done when:

- Translated `VariableTest.cpp`, `TermTest.cpp`, `ExpressionTest.cpp`, and `ConstraintTest.cpp` pass.
- Constraint construction produces expressions in the same sign convention as Kiwi: `lhs <= rhs` becomes `lhs - rhs <= 0`.
- Constraint duplicate behavior is identity-based, not structural.

## Phase 4: Row And Simplex Internals

Port the implementation behind the public API:

- Represent `Row` as `object` with `constant: KiwiScalar` and `cells: OrderedTable[Symbol, KiwiScalar]` or a small sorted vector map.
- Start with `OrderedTable` for clarity and deterministic iteration. Revisit a sorted vector map only if benchmarks show table overhead matters.
- Port row operations directly:
  - `add`
  - `insert(symbol, coefficient)`
  - `insert(row, coefficient)`
  - `remove`
  - `reverseSign`
  - `solveFor(symbol)`
  - `solveFor(lhs, rhs)`
  - `coefficientFor`
  - `substitute`
- Keep `Tag`, `EditInfo`, and the solver tableau private.
- Mirror Kiwi's symbol allocation with a monotonically increasing `SymbolId` per solver.
- Keep objective and artificial rows as values or `Option[Row]`; avoid raw pointer-style ownership.

Done when:

- Row tests cover zero-coefficient removal, substitution, solving, and sign reversal.
- Internal data structures do not expose mutable scalar accessors outside the solver modules.

## Phase 5: Solver Port

Port `SolverImpl` behavior into `solver.nim`:

- `addConstraint`
- `removeConstraint`
- `hasConstraint`
- `addEditVariable`
- `removeEditVariable`
- `hasEditVariable`
- `suggestValue`
- `updateVariables`
- `reset`
- `dump` / `dumps`

Port the private algorithm helpers in the same order as Kiwi:

- `getVarSymbol`
- `createRow`
- `chooseSubject`
- `addWithArtificialVariable`
- `substitute`
- `optimize`
- `dualOptimize`
- `getEnteringSymbol`
- `getDualEnteringSymbol`
- `anyPivotableSymbol`
- `getLeavingRow`
- `getMarkerLeavingRow`
- `removeConstraintEffects`
- `removeMarkerEffects`
- `allDummies`

Exception mapping:

- `UnsatisfiableConstraintError`
- `UnknownConstraintError`
- `DuplicateConstraintError`
- `UnknownEditVariableError`
- `DuplicateEditVariableError`
- `BadRequiredStrengthError`
- `InternalSolverError`

Done when:

- Translated `SolverTest.cpp` and `SimplexTest.cpp` pass.
- `reset` returns the solver to an empty state.
- `updateVariables` writes `0` for external variables not in the row map, matching Kiwi.

## Phase 6: Test Translation

Translate the upstream test suite into Nim `unittest` files:

- `tests/tstrengths.nim`
- `tests/tvariables.nim`
- `tests/tterms.nim`
- `tests/texpressions.nim`
- `tests/tconstraints.nim`
- `tests/tsolver.nim`
- `tests/tsimplex.nim`

Test priorities:

- Arithmetic and relational DSL shape.
- Strength ordering and clipping.
- Duplicate/unknown exception paths.
- Required unsatisfiable constraints.
- Edit variables and suggestions.
- Under-constrained systems.
- Weighted strength behavior.
- Infeasible dual optimization path.
- Simplex maximization example from upstream.

Use `check abs(actual - expected) <= 1e-6.KiwiScalar` helpers instead of exact floating comparisons.

Done when:

- `nim test` passes without depending on `deps/kiwi`.
- Tests are deterministic and do not use network access.

## Phase 7: Documentation And Examples

Replace the starter README with real usage once the port compiles:

- Short description: pure Nim Cassowary constraint solver based on Kiwi.
- Install instructions using Atlas.
- Minimal example solving `x + y == 10`, `x - y == 4`.
- Edit variable example.
- Notes on `Variable` identity and `sameVariable`.
- License and upstream attribution.

Done when:

- README examples compile.
- API docs for exported types and procs render with `nim doc`.

## Phase 8: Cleanup And Dependency Removal

After the pure Nim implementation and tests pass:

- Remove the normal-development dependency on `https://github.com/nucleic/kiwi`.
- Keep `deps/kiwi` only as an Atlas-fetched reference during development, not as a runtime/build dependency.
- Update CI to run `atlas install` and `nim test`.
- Keep `deps/cssgrid` only if the package actually needs it; otherwise use it only as a reference and remove the dependency.

Done when:

- A clean checkout can run `atlas install` and `nim test`.
- No C++ compiler or Kiwi headers are required for the library build.

## Phase 9: Performance Pass

Only optimize after correctness:

- Benchmark against representative UI layout constraints and the upstream Enaml-like benchmark shape.
- Profile row cell operations and pivot selection.
- Replace `OrderedTable` with a sorted-vector map if it materially improves small-row performance.
- Avoid ARC/ORC churn by reusing row storage where it does not obscure correctness.
- Keep public API stable during internal optimization.

Done when:

- Benchmarks are recorded in `benchmarks/` or documented test output.
- Any data-structure change preserves the full test suite.

## Acceptance Checklist

- Pure Nim implementation under `src/kiwiberry/`.
- No normal build dependency on Kiwi C++.
- Public API follows the planned Nim surface.
- Upstream behavior covered by translated tests.
- Root `LICENSE` and nimble metadata use BSD-3-Clause terms.
- README describes the port and includes runnable Nim examples.
