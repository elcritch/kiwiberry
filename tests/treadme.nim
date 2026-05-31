import std/assertions

import kiwiberry

block basicExample:
  var solver = initSolver()
  let x = newVariable("x")
  let y = newVariable("y")

  solver.addConstraint(x + y == 10)
  solver.addConstraint(x - y == 4)
  solver.updateVariables()

  doAssert x.value == 7.KiwiScalar
  doAssert y.value == 3.KiwiScalar

block refSolverExample:
  let solver = newSolver()
  let x = vars"x"

  solver.addConstraint(x >= 10)
  solver.updateVariables()

  doAssert x.value == 10.KiwiScalar

block namedConstructors:
  var solver = initSolver()
  let x = vars"x"
  let y = vars"y"

  solver.addConstraint(le(x + y, 10))
  solver.addConstraint(ge(x, 0))
  solver.addConstraint(eq(y, x + 2))
  solver.updateVariables()

  doAssert x.value == 0.KiwiScalar
  doAssert y.value == 2.KiwiScalar

block editVariables:
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

  solver.addConstraint(width >= 100)
  solver.addConstraint((width == 320) | Weak)
  solver.addConstraint((width >= 100).withStrength(Strong))
  solver.updateVariables()

  doAssert width.value == 320.KiwiScalar

block variableIdentity:
  let first = newVariable("x")
  let second = newVariable("x")
  let alias = first

  doAssert first.sameVariable(alias)
  doAssert not first.sameVariable(second)
