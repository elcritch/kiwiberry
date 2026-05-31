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

block constraintReduction:
  let variable = newVariable("foo")
  let constraint = newConstraint(variable + variable + 1, relEq)

  doAssert constraint.expression.len == 1
  doAssert constraint.expression.terms[0].coefficient == 2.KiwiScalar

block constraintStrength:
  let variable = newVariable("foo")
  let constraint = newConstraint(variable + 1, relEq)

  doAssert (constraint | Weak).strength == Weak
  doAssert constraint.withStrength(Medium).strength == Medium
  doAssert constraint.withStrength(Strong).strength == Strong

block constraintViolated:
  let variable = newVariable("foo")
  variable.value = 10

  let required = variable >= 10
  let weak = variable <= -5

  doAssert not required.violated
  doAssert weak.violated
