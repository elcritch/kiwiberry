# kiwiberry

`kiwiberry` is a pure Nim Cassowary constraint solver based on Kiwi. It solves
linear equalities and inequalities with constraint strengths and edit variables,
which is the style of solver commonly used for interactive UI layout.

## Install

```sh
atlas install
```

## Example

```nim
import kiwiberry

var solver = initSolver()
let width = vars"width"

solver[width] = Strong
solver.constraint(width >= 100)
solver.suggest(width, 240)
solver.update()

doAssert width.value == 240.KiwiScalar
```

The short form is the preferred API:

- `vars"name"` creates a variable.
- `solver[variable] = strength` adds an edit variable.
- `solver.constraint(...)` adds a constraint.
- `solver.suggest(variable, value)` suggests an edit-variable value.
- `solver.update()` writes solved values back to variables.

For ordinary constraints, use the same `constraint` and `update` helpers:

```nim
import kiwiberry

var solver = initSolver()
let x = vars"x"
let y = vars"y"

solver.constraint(x + y == 10)
solver.constraint(x - y == 4)
solver.update()

doAssert x.value == 7.KiwiScalar
doAssert y.value == 3.KiwiScalar
```

Keep the returned constraint when a dynamic layout needs to remove it later:

```nim
let minWidth = solver.constraint(width >= 100)

doAssert solver.has(minWidth)
solver.remove(minWidth)
doAssert not solver.has(minWidth)

solver.remove(width)
doAssert not solver.has(width)
```

Use `newSolver()` when you want a shared solver handle instead of a value:

```nim
import kiwiberry

let solver = newSolver()
let x = vars"x"

solver.constraint(x >= 10)
solver.update()

doAssert x.value == 10.KiwiScalar
```

The longer Kiwi-style names remain available when you want the explicit mapping:

```nim
solver.addEditVariable(width, Strong)
solver.addConstraint(width >= 100)
solver.suggestValue(width, 240)
solver.updateVariables()
```

## Constraint Constructors

Named constructors are available when operator syntax is awkward in generic
code:

```nim
solver.constraint(le(x + y, 10))
solver.constraint(ge(x, 0))
solver.constraint(eq(y, x + 2))
```

## Edit Variables

Edit variables must use a soft strength. `Required` is reserved for hard
constraints and raises `BadRequiredStrengthError` when used as an edit strength.
Call `update()` after adding constraints or suggestions to write solved values
back to variables.

## Strengths

Constraints are required by default:

```nim
solver.constraint(width >= 100)
```

Use `|` or `withStrength` for soft constraints. Kiwi-style strengths are ordered
as `Weak < Medium < Strong < Required`, and custom strengths can be created with
`createStrength(a, b, c, weight)`.

```nim
solver.constraint((width == 320) | Weak)
solver.constraint((width >= 100).withStrength(Strong))
```

Required constraints must all be satisfiable. Soft constraints are preferences
the solver may violate according to their relative strengths.

## Numeric Inputs

Solver scalars must be finite. NaN, infinity, division by zero, invalid
strength components, invalid variable values, and invalid edit suggestions raise
`InvalidSolverValueError` before they can enter the tableau.

## Variables And Identity

Variables are identity-bearing refs, matching Kiwi's copy semantics. Use
`sameVariable(a, b)` when you need to test variable identity in user code,
because `==`, `<=`, and `>=` are part of the constraint DSL.

```nim
let first = newVariable("x")
let second = newVariable("x")
let alias = first

doAssert first.sameVariable(alias)
doAssert not first.sameVariable(second)
```

## DSL Notes

The comparison operators `==`, `<=`, and `>=` create constraints for variables,
terms, and expressions. Nim does not allow the solver DSL to also use `==` as a
variable identity check, so use `sameVariable` for variables and
`sameConstraint` for constraints.

Use `le`, `ge`, and `eq` if a call site needs explicit relation names or if
operator overload resolution would make the intent unclear. In particular,
Nim may normalize scalar-left `>=` comparisons into the equivalent `<=`
constraint shape; `ge(10, x)` preserves `relGe` in the resulting constraint.

## Test

```sh
nim test
```

## License

Kiwiberry uses BSD-3-Clause terms based on Kiwi's license. See `LICENSE`.
