import std/assertions

import kiwiberry

block variableMethods:
  let variable = newVariable()
  doAssert variable.name == ""
  variable.name = "foo"
  doAssert variable.name == "foo"
  doAssert variable.value == 0.KiwiScalar
  variable.value = 3.5
  doAssert variable.value == 3.5.KiwiScalar

block variableIdentity:
  let first = newVariable("x")
  let second = newVariable("x")
  let alias = first
  doAssert first.sameVariable(alias)
  doAssert not first.sameVariable(second)

block variableNegMulDiv:
  let variable = newVariable("foo")

  let neg = -variable
  doAssert neg.variable.sameVariable(variable)
  doAssert neg.coefficient == -1.KiwiScalar

  let mul = variable * 2
  doAssert mul.variable.sameVariable(variable)
  doAssert mul.coefficient == 2.KiwiScalar

  let quotient = variable / 2
  doAssert quotient.variable.sameVariable(variable)
  doAssert quotient.coefficient == 0.5.KiwiScalar

block variableAdditionAndSubtraction:
  let first = newVariable("foo")
  let second = newVariable("bar")

  let addConstant = first + 2
  doAssert addConstant.constant == 2.KiwiScalar
  doAssert addConstant.len == 1
  doAssert addConstant.terms[0].variable.sameVariable(first)

  let addVariable = first + second
  doAssert addVariable.constant == 0.KiwiScalar
  doAssert addVariable.len == 2
  doAssert addVariable.terms[0].coefficient == 1.KiwiScalar
  doAssert addVariable.terms[1].coefficient == 1.KiwiScalar

  let subVariable = first - second
  doAssert subVariable.constant == 0.KiwiScalar
  doAssert subVariable.len == 2
  doAssert subVariable.terms[0].coefficient == 1.KiwiScalar
  doAssert subVariable.terms[1].coefficient == -1.KiwiScalar

block variableComparisonCreatesConstraints:
  let first = newVariable("foo")
  let second = newVariable("bar")

  let le = second + 1 <= first
  doAssert le.relation == relLe
  doAssert le.strength == Required
  doAssert le.expression.constant == 1.KiwiScalar
  doAssert le.expression.len == 2

  let eq = second + 1 == first
  doAssert eq.relation == relEq

  let ge = second + 1 >= first
  doAssert ge.relation == relGe
