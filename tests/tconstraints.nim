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
