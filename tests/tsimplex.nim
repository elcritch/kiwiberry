import std/assertions

import kiwiberry

proc closeTo(a, b: KiwiScalar, eps: KiwiScalar = 1.0e-4): bool =
  abs(a - b) <= eps

block maximization:
  let x1 = newVariable("x1")
  let x2 = newVariable("x2")
  let x3 = newVariable("x3")
  let z = newVariable("z")
  var solver = initSolver()

  solver.addConstraint(x1 >= 0)
  solver.addConstraint(x2 >= 0)
  solver.addConstraint(x3 >= 0)
  solver.addConstraint(2 * x1 - 5 * x2 <= 11)
  solver.addConstraint(-x1 + 3 * x2 + x3 == 7)
  solver.addConstraint(x1 - 8 * x2 + 4 * x3 >= 33)
  solver.addConstraint(z == -2 * x1 + 7 * x2 + 4 * x3)
  solver.addEditVariable(z, Weak)
  solver.suggestValue(z, 1e6)
  solver.updateVariables()

  doAssert x1.value.closeTo(13)
  doAssert x2.value.closeTo(3)
  doAssert x3.value.closeTo(11)
  doAssert z.value.closeTo(39)
