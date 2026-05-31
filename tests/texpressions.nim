import std/assertions

import kiwiberry

block termCreation:
  let variable = newVariable("foo")
  let term = initTerm(variable, 100)
  doAssert term.variable.sameVariable(variable)
  doAssert term.coefficient == 100.KiwiScalar

block expressionCreation:
  let first = newVariable("foo")
  let second = newVariable("bar")
  let third = newVariable("aux")

  let expression =
    initExpression([initTerm(first, 1), initTerm(second, 2), initTerm(third, 3)])

  doAssert expression.constant == 0.KiwiScalar
  doAssert expression.len == 3
  doAssert expression.terms[0].variable.sameVariable(first)
  doAssert expression.terms[0].coefficient == 1.KiwiScalar
  doAssert expression.terms[1].variable.sameVariable(second)
  doAssert expression.terms[1].coefficient == 2.KiwiScalar
  doAssert expression.terms[2].variable.sameVariable(third)
  doAssert expression.terms[2].coefficient == 3.KiwiScalar

  let expressionWithConstant =
    initExpression([initTerm(first, 1), initTerm(second, 2), initTerm(third, 3)], 10)

  doAssert expressionWithConstant.constant == 10.KiwiScalar
  doAssert expressionWithConstant.len == 3
  doAssert expressionWithConstant.terms[0].variable.sameVariable(first)
  doAssert expressionWithConstant.terms[0].coefficient == 1.KiwiScalar
  doAssert expressionWithConstant.terms[1].variable.sameVariable(second)
  doAssert expressionWithConstant.terms[1].coefficient == 2.KiwiScalar
  doAssert expressionWithConstant.terms[2].variable.sameVariable(third)
  doAssert expressionWithConstant.terms[2].coefficient == 3.KiwiScalar

block expressionArithmetic:
  let first = newVariable("foo")
  let second = newVariable("bar")
  let expression = initTerm(first, 10) + 5
  let other = second - 10

  let neg = -expression
  doAssert neg.constant == -5.KiwiScalar
  doAssert neg.terms[0].coefficient == -10.KiwiScalar

  let mul = expression * 2
  doAssert mul.constant == 10.KiwiScalar
  doAssert mul.terms[0].coefficient == 20.KiwiScalar

  let reverseMul = 2 * expression
  doAssert reverseMul.constant == 10.KiwiScalar
  doAssert reverseMul.terms[0].coefficient == 20.KiwiScalar

  let quotient = expression / 2
  doAssert quotient.constant == 2.5.KiwiScalar
  doAssert quotient.terms[0].coefficient == 5.KiwiScalar

  let addConstant = expression + 2
  doAssert addConstant.constant == 7.KiwiScalar
  doAssert addConstant.len == 1
  doAssert addConstant.terms[0].variable.sameVariable(first)
  doAssert addConstant.terms[0].coefficient == 10.KiwiScalar

  let reverseAddConstant = 2 + expression
  doAssert reverseAddConstant.constant == 7.KiwiScalar
  doAssert reverseAddConstant.len == 1
  doAssert reverseAddConstant.terms[0].variable.sameVariable(first)
  doAssert reverseAddConstant.terms[0].coefficient == 10.KiwiScalar

  let addVariable = expression + second
  doAssert addVariable.constant == 5.KiwiScalar
  doAssert addVariable.len == 2
  doAssert addVariable.terms[0].variable.sameVariable(first)
  doAssert addVariable.terms[0].coefficient == 10.KiwiScalar
  doAssert addVariable.terms[1].variable.sameVariable(second)
  doAssert addVariable.terms[1].coefficient == 1.KiwiScalar

  let addTerm = expression + initTerm(second)
  doAssert addTerm.constant == 5.KiwiScalar
  doAssert addTerm.len == 2
  doAssert addTerm.terms[0].variable.sameVariable(first)
  doAssert addTerm.terms[0].coefficient == 10.KiwiScalar
  doAssert addTerm.terms[1].variable.sameVariable(second)
  doAssert addTerm.terms[1].coefficient == 1.KiwiScalar

  let add = expression + other
  doAssert add.constant == -5.KiwiScalar
  doAssert add.len == 2
  doAssert add.terms[0].variable.sameVariable(first)
  doAssert add.terms[0].coefficient == 10.KiwiScalar
  doAssert add.terms[1].variable.sameVariable(second)
  doAssert add.terms[1].coefficient == 1.KiwiScalar

  let subConstant = expression - 2
  doAssert subConstant.constant == 3.KiwiScalar
  doAssert subConstant.len == 1
  doAssert subConstant.terms[0].variable.sameVariable(first)
  doAssert subConstant.terms[0].coefficient == 10.KiwiScalar

  let reverseSubConstant = 2 - expression
  doAssert reverseSubConstant.constant == -3.KiwiScalar
  doAssert reverseSubConstant.len == 1
  doAssert reverseSubConstant.terms[0].variable.sameVariable(first)
  doAssert reverseSubConstant.terms[0].coefficient == -10.KiwiScalar

  let subVariable = expression - second
  doAssert subVariable.constant == 5.KiwiScalar
  doAssert subVariable.len == 2
  doAssert subVariable.terms[0].variable.sameVariable(first)
  doAssert subVariable.terms[0].coefficient == 10.KiwiScalar
  doAssert subVariable.terms[1].variable.sameVariable(second)
  doAssert subVariable.terms[1].coefficient == -1.KiwiScalar

  let reverseSubVariable = second - expression
  doAssert reverseSubVariable.constant == -5.KiwiScalar
  doAssert reverseSubVariable.len == 2
  doAssert reverseSubVariable.terms[0].variable.sameVariable(second)
  doAssert reverseSubVariable.terms[0].coefficient == 1.KiwiScalar
  doAssert reverseSubVariable.terms[1].variable.sameVariable(first)
  doAssert reverseSubVariable.terms[1].coefficient == -10.KiwiScalar

  let subTerm = expression - initTerm(second)
  doAssert subTerm.constant == 5.KiwiScalar
  doAssert subTerm.len == 2
  doAssert subTerm.terms[0].variable.sameVariable(first)
  doAssert subTerm.terms[0].coefficient == 10.KiwiScalar
  doAssert subTerm.terms[1].variable.sameVariable(second)
  doAssert subTerm.terms[1].coefficient == -1.KiwiScalar

  let reverseSubTerm = initTerm(second) - expression
  doAssert reverseSubTerm.constant == -5.KiwiScalar
  doAssert reverseSubTerm.len == 2

  let sub = expression - other
  doAssert sub.constant == 15.KiwiScalar
  doAssert sub.len == 2
  doAssert sub.terms[0].variable.sameVariable(first)
  doAssert sub.terms[0].coefficient == 10.KiwiScalar
  doAssert sub.terms[1].variable.sameVariable(second)
  doAssert sub.terms[1].coefficient == -1.KiwiScalar

block expressionValue:
  let variable = newVariable("foo")
  variable.value = 3
  let expression = initTerm(variable, 10) + 5
  doAssert expression.value == 35.KiwiScalar

block expressionComparisonCreatesConstraints:
  let first = newVariable("foo")
  let second = newVariable("bar")
  let expression = initTerm(first, 10) + 5
  let other = second - 10

  let le = expression <= other
  doAssert le.relation == relLe
  doAssert le.expression.constant == 15.KiwiScalar
  doAssert le.expression.len == 2

  let eq = expression == other
  doAssert eq.relation == relEq
  doAssert eq.strength == Required

  let ge = expression >= other
  doAssert ge.relation == relGe
  doAssert ge.strength == Required
