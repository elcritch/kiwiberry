import std/assertions

import kiwiberry

block preferredExample:
  var solver = initSolver()
  let width = vars"width"

  solver[width] = Strong
  solver.constraint(width >= 100)
  solver.suggest(width, 240)
  solver.update()

  doAssert width.value == 240.KiwiScalar

block basicConstraints:
  var solver = initSolver()
  let x = vars"x"
  let y = vars"y"

  solver.constraint(x + y == 10)
  solver.constraint(x - y == 4)
  solver.update()

  doAssert x.value == 7.KiwiScalar
  doAssert y.value == 3.KiwiScalar

block dynamicConstraintRemoval:
  var solver = initSolver()
  let width = vars"width"
  solver[width] = Strong

  let minWidth = solver.constraint(width >= 100)

  doAssert solver.has(minWidth)
  doAssert solver.has(width >= 100)
  solver.remove(width >= 100)
  doAssert not solver.has(minWidth)

  solver.remove(width)
  doAssert not solver.has(width)

block refSolverExample:
  let solver = newSolver()
  let x = vars"x"

  solver.constraint(x >= 10)
  solver.update()

  doAssert x.value == 10.KiwiScalar

block namedConstructors:
  var solver = initSolver()
  let x = vars"x"
  let y = vars"y"

  solver.constraint(le(x + y, 10))
  solver.constraint(ge(x, 0))
  solver.constraint(eq(y, x + 2))
  solver.update()

  doAssert x.value == 0.KiwiScalar
  doAssert y.value == 2.KiwiScalar

block explicitLongNames:
  var solver = initSolver()
  let width = newVariable("width")

  solver.addEditVariable(width, Strong)
  solver.addConstraint(width >= 100)
  solver.suggestValue(width, 240)
  solver.updateVariables()

  doAssert width.value == 240.KiwiScalar

block strengths:
  var solver = initSolver()
  let width = newVariable("width")

  solver.constraint(width >= 100)
  solver.constraint((width == 320) | Weak)
  solver.constraint((width >= 100).withStrength(Strong))
  solver.update()

  doAssert width.value == 320.KiwiScalar

block variableIdentity:
  let first = newVariable("x")
  let second = newVariable("x")
  let alias = first

  doAssert first.sameVariable(alias)
  doAssert not first.sameVariable(second)
