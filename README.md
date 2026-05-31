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
let x = newVariable("x")
let y = newVariable("y")

solver.addConstraint(x + y == 10)
solver.addConstraint(x - y == 4)
solver.updateVariables()

doAssert x.value == 7.KiwiScalar
doAssert y.value == 3.KiwiScalar
```

Use `newSolver()` when you want a shared solver handle instead of a value:

```nim
import kiwiberry

let solver = newSolver()
let x = vars"x"

solver.addConstraint(x >= 10)
solver.updateVariables()

doAssert x.value == 10.KiwiScalar
```

Variable literals are also available:

```nim
let x = vars"x"
let y = vars"y"

solver.addConstraint(x + y == 10)
```

Named constructors are available when operator syntax is awkward in generic
code:

```nim
solver.addConstraint(le(x + y, 10))
solver.addConstraint(ge(x, 0))
solver.addConstraint(eq(y, x + 2))
```

## Edit Variables

```nim
import kiwiberry

var solver = initSolver()
let width = newVariable("width")

solver.addEditVariable(width, Strong)
solver.addConstraint(width >= 100)
solver.suggestValue(width, 240)
solver.updateVariables()

doAssert width.value == 240.KiwiScalar
```

Edit variables must use a soft strength. `Required` is reserved for hard
constraints and raises `BadRequiredStrengthError` when used as an edit strength.
Call `updateVariables()` after adding constraints or suggestions to write solved
values back to variables.

## Strengths

Constraints are required by default:

```nim
solver.addConstraint(width >= 100)
```

Use `|` or `withStrength` for soft constraints. Kiwi-style strengths are ordered
as `Weak < Medium < Strong < Required`, and custom strengths can be created with
`createStrength(a, b, c, weight)`.

```nim
solver.addConstraint((width == 320) | Weak)
solver.addConstraint((width >= 100).withStrength(Strong))
```

Required constraints must all be satisfiable. Soft constraints are preferences
the solver may violate according to their relative strengths.

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
