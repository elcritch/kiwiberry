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
  let expression = initExpression([initTerm(first, 1), initTerm(second, 2)], 10)

  doAssert expression.constant == 10.KiwiScalar
  doAssert expression.len == 2
  doAssert expression.terms[0].variable.sameVariable(first)
  doAssert expression.terms[1].coefficient == 2.KiwiScalar

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

  let quotient = expression / 2
  doAssert quotient.constant == 2.5.KiwiScalar
  doAssert quotient.terms[0].coefficient == 5.KiwiScalar

  let add = expression + other
  doAssert add.constant == -5.KiwiScalar
  doAssert add.len == 2

  let sub = expression - other
  doAssert sub.constant == 15.KiwiScalar
  doAssert sub.len == 2
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

  let ge = expression >= other
  doAssert ge.relation == relGe
