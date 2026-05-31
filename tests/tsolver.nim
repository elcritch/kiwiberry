import std/assertions
import std/strutils

import kiwiberry

proc closeTo(a, b: KiwiScalar, eps: KiwiScalar = 1.0e-6): bool =
  abs(a - b) <= eps

block solverCreation:
  var solver = initSolver()
  doAssert solver.dumps.contains("Objective")

block refSolverCreation:
  let solver = newSolver()
  let x = newVariable("x")

  solver.addConstraint(x == 1)
  solver.updateVariables()

  doAssert x.value.closeTo(1)

block managingConstraints:
  var solver = initSolver()
  let variable = newVariable("foo")
  let first = variable >= 1
  let second = variable <= 0

  doAssert not solver.hasConstraint(first)
  solver.addConstraint(first)
  doAssert solver.hasConstraint(first)

  doAssertRaises DuplicateConstraintError:
    solver.addConstraint(first)

  doAssertRaises UnknownConstraintError:
    solver.removeConstraint(second)

  doAssertRaises UnsatisfiableConstraintError:
    solver.addConstraint(second)

  solver.removeConstraint(first)
  doAssert not solver.hasConstraint(first)

block simpleSolving:
  var solver = initSolver()
  let x = newVariable("x")
  let y = newVariable("y")

  solver.addConstraint(x + y == 10)
  solver.addConstraint(x - y == 4)
  solver.updateVariables()

  doAssert x.value.closeTo(7)
  doAssert y.value.closeTo(3)

block managingEditVariables:
  var solver = initSolver()
  let first = newVariable("foo")
  let second = newVariable("bar")

  doAssert not solver.hasEditVariable(first)
  solver.addEditVariable(first, Weak)
  doAssert solver.hasEditVariable(first)

  doAssertRaises DuplicateEditVariableError:
    solver.addEditVariable(first, Medium)

  doAssertRaises UnknownEditVariableError:
    solver.removeEditVariable(second)

  solver.removeEditVariable(first)
  doAssert not solver.hasEditVariable(first)

  doAssertRaises BadRequiredStrengthError:
    solver.addEditVariable(first, Required)

block suggestingValues:
  var solver = initSolver()
  let variable = newVariable("foo")

  solver.addEditVariable(variable, Medium)
  solver.addConstraint((variable == 1) | Weak)
  solver.suggestValue(variable, 2)
  solver.updateVariables()

  doAssert variable.value.closeTo(2)

block ergonomicValueSolver:
  var solver = initSolver()
  let width = vars"width"

  solver[width] = Strong
  let minWidth = solver.constraint(width >= 100)
  doAssert solver.has(minWidth)
  doAssert solver.has(width >= 100)
  doAssert solver.has(width)
  solver.suggest(width, 240)
  solver.update()

  doAssert width.value.closeTo(240)
  solver.remove(width >= 100)
  solver.remove(width)
  doAssert not solver.has(minWidth)
  doAssert not solver.has(width >= 100)
  doAssert not solver.has(width)

block ergonomicRefSolver:
  let solver = newSolver()
  let width = vars"refWidth"

  solver[width] = Strong
  let minWidth = solver.constraint(width >= 100)
  doAssert solver.has(minWidth)
  doAssert solver.has(width >= 100)
  doAssert solver.has(width)
  solver.suggest(width, 240)
  solver.update()

  doAssert width.value.closeTo(240)
  solver.remove(width >= 100)
  solver.remove(width)
  doAssert not solver.has(minWidth)
  doAssert not solver.has(width >= 100)
  doAssert not solver.has(width)

block suggestingValuesAcrossRows:
  var solver = initSolver()
  let first = newVariable("foo")
  let second = newVariable("bar")

  solver.addEditVariable(second, Weak)
  solver.addConstraint(first + second == 0)
  solver.addConstraint(second <= -1)
  solver.addConstraint((second >= 0) | Weak)
  solver.suggestValue(second, 0)
  solver.updateVariables()

  doAssert second.value <= -1.KiwiScalar

block underConstrainedSystem:
  var solver = initSolver()
  let variable = newVariable("foo")
  let constraint = 2 * variable + 1 >= 0

  solver.addEditVariable(variable, Weak)
  solver.addConstraint(constraint)
  solver.suggestValue(variable, 10)
  solver.updateVariables()

  doAssert constraint.expression.value.closeTo(21)
  doAssert constraint.expression.terms[0].value.closeTo(20)
  doAssert variable.value.closeTo(10)

block solvingWithStrength:
  let first = newVariable("foo")
  let second = newVariable("bar")
  var solver = initSolver()

  solver.addConstraint(first + second == 0)
  solver.addConstraint(first == 10)
  solver.addConstraint((second >= 0) | Weak)
  solver.updateVariables()

  doAssert first.value.closeTo(10)
  doAssert second.value.closeTo(-10)

  solver.reset()
  solver.addConstraint(first + second == 0)
  solver.addConstraint((first >= 10) | Medium)
  solver.addConstraint((second == 2) | Strong)
  solver.updateVariables()

  doAssert first.value.closeTo(-2)
  doAssert second.value.closeTo(2)

block dumpContainsHeaders:
  let first = newVariable("foo")
  let second = newVariable("bar")
  var solver = initSolver()

  solver.addEditVariable(second, Weak)
  solver.addConstraint(first + second == 0)
  solver.addConstraint(second <= -1)
  solver.addConstraint((second >= 0) | Weak)
  solver.updateVariables()

  doAssertRaises UnsatisfiableConstraintError:
    solver.addConstraint(second >= 1)

  let state = solver.dumps()
  doAssert state.contains("Objective")
  doAssert state.contains("Tableau")
  doAssert state.contains("Variables")
  doAssert state.contains("Constraints")

block handlingInfeasibleConstraints:
  let xm = newVariable("xm")
  let xl = newVariable("xl")
  let xr = newVariable("xr")
  var solver = initSolver()

  solver.addEditVariable(xm, Strong)
  solver.addEditVariable(xl, Weak)
  solver.addEditVariable(xr, Weak)
  solver.addConstraint(2 * xm == xl + xr)
  solver.addConstraint(xl + 20 <= xr)
  solver.addConstraint(xl >= -10)
  solver.addConstraint(xr <= 100)

  solver.suggestValue(xm, 40)
  solver.suggestValue(xr, 50)
  solver.suggestValue(xl, 30)
  solver.suggestValue(xm, 60)
  solver.suggestValue(xm, 90)
  solver.updateVariables()

  doAssert (xl.value + xr.value).closeTo(2 * xm.value)
  doAssert xl.value.closeTo(80)
  doAssert xr.value.closeTo(100)

block constraintViolatedAfterSolve:
  var solver = initSolver()
  let variable = newVariable("foo")
  let requiredConstraint = (variable >= 10) | Required
  let weakConstraint = (variable <= -5) | Weak

  solver.addConstraint(requiredConstraint)
  solver.addConstraint(weakConstraint)
  solver.updateVariables()

  doAssert variable.value >= 10.KiwiScalar
  doAssert not requiredConstraint.violated
  doAssert weakConstraint.violated
