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

Variables are identity-bearing refs, matching Kiwi's copy semantics. Use
`sameVariable(a, b)` when you need to test variable identity in user code,
because `==`, `<=`, and `>=` are part of the constraint DSL.

## Test

```sh
nim test
```

## License

Kiwiberry uses BSD-3-Clause terms based on Kiwi's license. See `LICENSE`.
