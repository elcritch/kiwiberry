import std/assertions

import kiwiberry

block scalarInputsMustBeFinite:
  doAssert 1.KiwiScalar.isFinite

  doAssertRaises InvalidSolverValueError:
    discard toKiwiScalar(NaN)

  doAssertRaises InvalidSolverValueError:
    discard toKiwiScalar(Inf)

  doAssert (1.KiwiScalar / 0.KiwiScalar).float64 == Inf
  doAssert (1e308.KiwiScalar * 1e308.KiwiScalar).float64 == Inf

block expressionsMustUseFiniteNumbers:
  let variable = newVariable("x")

  doAssertRaises InvalidSolverValueError:
    discard initTerm(variable, KiwiScalar(Inf))

  doAssertRaises InvalidSolverValueError:
    discard initExpression(constant = KiwiScalar(NaN))

  doAssertRaises InvalidSolverValueError:
    discard variable / 0

block variableValuesMustBeFinite:
  let variable = newVariable("x")

  doAssertRaises InvalidSolverValueError:
    variable.value = KiwiScalar(NaN)

block strengthInputsMustBeFinite:
  doAssertRaises InvalidSolverValueError:
    discard createStrength(KiwiScalar(NaN), 0, 0)

  doAssertRaises InvalidSolverValueError:
    discard createStrength(1, 0, 0, KiwiScalar(Inf))

block solverSuggestionsMustBeFinite:
  var solver = initSolver()
  let variable = newVariable("x")

  solver[variable] = Strong

  doAssertRaises InvalidSolverValueError:
    solver.suggest(variable, KiwiScalar(Inf))
