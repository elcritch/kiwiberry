import std/assertions

import kiwiberry

block constraintCreation:
  let variable = newVariable("foo")
  let constraint = newConstraint(variable + 1, relEq)

  doAssert constraint.strength == Required
  doAssert constraint.relation == relEq
  doAssert constraint.expression.constant == 1.KiwiScalar
  doAssert constraint.expression.len == 1
  doAssert constraint.expression.terms[0].variable.sameVariable(variable)
  doAssert constraint.expression.terms[0].coefficient == 1.KiwiScalar

  let le = newConstraint(variable + 1, relLe)
  doAssert le.strength == Required
  doAssert le.relation == relLe

  let ge = newConstraint(variable + 1, relGe)
  doAssert ge.strength == Required
  doAssert ge.relation == relGe

block constraintReduction:
  let variable = newVariable("foo")
  let constraint = newConstraint(variable + variable + 1, relEq)

  doAssert constraint.expression.len == 1
  doAssert constraint.expression.terms[0].coefficient == 2.KiwiScalar

block constraintShape:
  let width = newVariable("width")
  let height = newVariable("height")

  let first = width + height >= 100
  let second = height + width >= 100
  let differentRelation = width + height <= 100
  let differentStrength = (width + height >= 100) | Weak

  doAssert not first.sameConstraint(second)
  doAssert first.sameShape(second)
  doAssert not first.sameShape(differentRelation)
  doAssert not first.sameShape(differentStrength)

block namedConstraintConstructors:
  let first = newVariable("foo")
  let second = newVariable("bar")

  let lessEqual = le(first + 1, second)
  doAssert lessEqual.relation == relLe
  doAssert lessEqual.expression.constant == 1.KiwiScalar
  doAssert lessEqual.expression.len == 2

  let greaterEqual = ge(first, 10)
  doAssert greaterEqual.relation == relGe
  doAssert greaterEqual.expression.constant == -10.KiwiScalar
  doAssert greaterEqual.expression.len == 1

  let equal = eq(first, second + 3)
  doAssert equal.relation == relEq
  doAssert equal.expression.constant == -3.KiwiScalar
  doAssert equal.expression.len == 2

block variableVariableDsl:
  let first = newVariable("foo")
  let second = newVariable("bar")

  doAssert (first <= second).relation == relLe
  doAssert (first >= second).relation == relGe
  doAssert (first == second).relation == relEq

block scalarVariableDsl:
  let variable = newVariable("foo")

  let lowerBound = 10 <= variable
  doAssert lowerBound.relation == relGe
  doAssert lowerBound.expression.constant == -10.KiwiScalar

  let upperBound = 10 >= variable
  doAssert upperBound.relation == relLe
  doAssert upperBound.expression.constant == -10.KiwiScalar

  let namedLowerBound = le(10, variable)
  doAssert namedLowerBound.relation == relLe
  doAssert namedLowerBound.expression.constant == 10.KiwiScalar

  let namedUpperBound = ge(10, variable)
  doAssert namedUpperBound.relation == relGe
  doAssert namedUpperBound.expression.constant == 10.KiwiScalar

block constraintStrength:
  let variable = newVariable("foo")
  let constraint = newConstraint(variable + 1, relEq)

  doAssert newConstraint(variable + 1, relEq, Weak).strength == Weak
  doAssert newConstraint(variable + 1, relEq, Medium).strength == Medium
  doAssert newConstraint(variable + 1, relEq, Strong).strength == Strong
  doAssert newConstraint(variable + 1, relEq, Required).strength == Required

  doAssert (constraint | Weak).strength == Weak
  doAssert constraint.withStrength(Medium).strength == Medium
  doAssert constraint.withStrength(Strong).strength == Strong
  doAssert constraint.withStrength(Required).strength == Required
  doAssert (constraint | createStrength(1, 1, 0)).strength == createStrength(1, 1, 0)

block constraintViolated:
  let variable = newVariable("foo")
  variable.value = 10

  let required = variable >= 10
  let weak = variable <= -5

  doAssert not required.violated
  doAssert weak.violated
