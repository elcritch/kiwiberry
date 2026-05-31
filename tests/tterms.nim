import std/assertions

import kiwiberry

block termCreation:
  let variable = newVariable("foo")

  let defaultTerm = initTerm(variable)
  doAssert defaultTerm.variable.sameVariable(variable)
  doAssert defaultTerm.coefficient == 1.KiwiScalar

  let weightedTerm = initTerm(variable, 100)
  doAssert weightedTerm.variable.sameVariable(variable)
  doAssert weightedTerm.coefficient == 100.KiwiScalar

block termNegMulDiv:
  let variable = newVariable("foo")
  let term = initTerm(variable, 10)

  let neg = -term
  doAssert neg.variable.sameVariable(variable)
  doAssert neg.coefficient == -10.KiwiScalar

  let mul = term * 2
  doAssert mul.variable.sameVariable(variable)
  doAssert mul.coefficient == 20.KiwiScalar

  let reverseMul = 2 * term
  doAssert reverseMul.variable.sameVariable(variable)
  doAssert reverseMul.coefficient == 20.KiwiScalar

  let quotient = term / 2
  doAssert quotient.variable.sameVariable(variable)
  doAssert quotient.coefficient == 5.KiwiScalar

block termAddition:
  let first = newVariable("foo")
  let second = newVariable("bar")
  let term = initTerm(first, 10)
  let other = initTerm(second)

  let addConstant = term + 2
  doAssert addConstant.constant == 2.KiwiScalar
  doAssert addConstant.len == 1
  doAssert addConstant.terms[0].variable.sameVariable(first)
  doAssert addConstant.terms[0].coefficient == 10.KiwiScalar

  let reverseAddConstant = 2 + term
  doAssert reverseAddConstant.constant == 2.KiwiScalar
  doAssert reverseAddConstant.len == 1
  doAssert reverseAddConstant.terms[0].variable.sameVariable(first)
  doAssert reverseAddConstant.terms[0].coefficient == 10.KiwiScalar

  let addVariable = term + second
  doAssert addVariable.constant == 0.KiwiScalar
  doAssert addVariable.len == 2
  doAssert addVariable.terms[0].variable.sameVariable(first)
  doAssert addVariable.terms[0].coefficient == 10.KiwiScalar
  doAssert addVariable.terms[1].variable.sameVariable(second)
  doAssert addVariable.terms[1].coefficient == 1.KiwiScalar

  let reverseAddVariable = second + term
  doAssert reverseAddVariable.constant == 0.KiwiScalar
  doAssert reverseAddVariable.len == 2

  let addTerm = term + other
  doAssert addTerm.constant == 0.KiwiScalar
  doAssert addTerm.len == 2
  doAssert addTerm.terms[0].variable.sameVariable(first)
  doAssert addTerm.terms[0].coefficient == 10.KiwiScalar
  doAssert addTerm.terms[1].variable.sameVariable(second)
  doAssert addTerm.terms[1].coefficient == 1.KiwiScalar

block termSubtraction:
  let first = newVariable("foo")
  let second = newVariable("bar")
  let term = initTerm(first, 10)
  let other = initTerm(second)

  let subConstant = term - 2
  doAssert subConstant.constant == -2.KiwiScalar
  doAssert subConstant.len == 1
  doAssert subConstant.terms[0].variable.sameVariable(first)
  doAssert subConstant.terms[0].coefficient == 10.KiwiScalar

  let reverseSubConstant = 2 - term
  doAssert reverseSubConstant.constant == 2.KiwiScalar
  doAssert reverseSubConstant.len == 1
  doAssert reverseSubConstant.terms[0].variable.sameVariable(first)
  doAssert reverseSubConstant.terms[0].coefficient == -10.KiwiScalar

  let subVariable = term - second
  doAssert subVariable.constant == 0.KiwiScalar
  doAssert subVariable.len == 2
  doAssert subVariable.terms[0].variable.sameVariable(first)
  doAssert subVariable.terms[0].coefficient == 10.KiwiScalar
  doAssert subVariable.terms[1].variable.sameVariable(second)
  doAssert subVariable.terms[1].coefficient == -1.KiwiScalar

  let reverseSubVariable = second - term
  doAssert reverseSubVariable.constant == 0.KiwiScalar
  doAssert reverseSubVariable.len == 2
  doAssert reverseSubVariable.terms[0].variable.sameVariable(second)
  doAssert reverseSubVariable.terms[0].coefficient == 1.KiwiScalar
  doAssert reverseSubVariable.terms[1].variable.sameVariable(first)
  doAssert reverseSubVariable.terms[1].coefficient == -10.KiwiScalar

  let subTerm = term - other
  doAssert subTerm.constant == 0.KiwiScalar
  doAssert subTerm.len == 2
  doAssert subTerm.terms[0].variable.sameVariable(first)
  doAssert subTerm.terms[0].coefficient == 10.KiwiScalar
  doAssert subTerm.terms[1].variable.sameVariable(second)
  doAssert subTerm.terms[1].coefficient == -1.KiwiScalar

block termComparisonCreatesConstraints:
  let first = newVariable("foo")
  let second = newVariable("bar")
  let term = initTerm(first, 10)
  let other = initTerm(second, 20)

  let le = term <= other + 1
  doAssert le.relation == relLe
  doAssert le.strength == Required
  doAssert le.expression.constant == -1.KiwiScalar
  doAssert le.expression.len == 2

  let eq = term == other + 1
  doAssert eq.relation == relEq
  doAssert eq.strength == Required
  doAssert eq.expression.constant == -1.KiwiScalar
  doAssert eq.expression.len == 2

  let ge = term >= other + 1
  doAssert ge.relation == relGe
  doAssert ge.strength == Required
  doAssert ge.expression.constant == -1.KiwiScalar
  doAssert ge.expression.len == 2
