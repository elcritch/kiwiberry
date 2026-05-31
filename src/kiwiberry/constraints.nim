import std/[hashes, tables]

import ./[expressions, scalars, strengths, variables]

type
  Relation* = enum
    relLe
    relGe
    relEq

  Constraint* = ref object
    id: uint64
    expressionValue: Expression
    relationValue: Relation
    strengthValue: Strength

var nextConstraintId = 1'u64

proc reduce(expression: Expression): Expression =
  var reduced = initOrderedTable[VariableId, Term]()
  for term in expression:
    let id = term.variable.variableId
    if reduced.hasKey(id):
      let old = reduced[id]
      reduced[id] = initTerm(old.variable, old.coefficient + term.coefficient)
    else:
      reduced[id] = term

  var terms = newSeq[Term]()
  for term in reduced.values:
    if not term.coefficient.nearZero:
      terms.add term
  initExpression(terms, expression.constant)

proc newConstraint*(
    expression: Expression, relation: Relation, strength: Strength = Required
): Constraint =
  new(result)
  result.id = nextConstraintId
  inc nextConstraintId
  result.expressionValue = reduce(expression)
  result.relationValue = relation
  result.strengthValue = strength.clip

proc expression*(constraint: Constraint): lent Expression =
  constraint.expressionValue

proc relation*(constraint: Constraint): Relation =
  constraint.relationValue

proc strength*(constraint: Constraint): Strength =
  constraint.strengthValue

proc sameConstraint*(a, b: Constraint): bool =
  a != nil and b != nil and a.id == b.id

proc `==`*(a, b: Constraint): bool =
  a.sameConstraint(b)

proc hash*(constraint: Constraint): Hash =
  hash(constraint.id)

proc violated*(constraint: Constraint): bool =
  case constraint.relationValue
  of relEq:
    not constraint.expressionValue.value.nearZero
  of relGe:
    constraint.expressionValue.value < 0
  of relLe:
    constraint.expressionValue.value > 0

proc withStrength*(constraint: Constraint, strength: Strength): Constraint =
  newConstraint(constraint.expressionValue, constraint.relationValue, strength)

proc `|`*(constraint: Constraint, strength: Strength): Constraint =
  constraint.withStrength(strength)

proc toExpressionForConstraint(value: Expression): Expression =
  value

proc toExpressionForConstraint(value: Term): Expression =
  toExpression(value)

proc toExpressionForConstraint(value: Variable): Expression =
  toExpression(value)

proc toExpressionForConstraint(value: KiwiScalar): Expression =
  toExpression(value)

proc makeConstraint[A, B](left: A, relation: Relation, right: B): Constraint =
  newConstraint(
    toExpressionForConstraint(left) - toExpressionForConstraint(right), relation
  )

type ConstraintSide = Expression | Term | Variable

proc `<=`*[A: ConstraintSide, B: ConstraintSide](left: A, right: B): Constraint =
  makeConstraint(left, relLe, right)

proc `<=`*(left, right: Variable): Constraint =
  makeConstraint(left, relLe, right)

proc `<=`*[A: ConstraintSide](left: A, right: KiwiScalar): Constraint =
  makeConstraint(left, relLe, right)

proc `<=`*[B: ConstraintSide](left: KiwiScalar, right: B): Constraint =
  # Nim rewrites `x >= c` to `c <= x`, so scalar-left comparisons are
  # treated as the greater-than-or-equal constraint for the right side.
  makeConstraint(right, relGe, left)

proc `>=`*[A: ConstraintSide, B: ConstraintSide](left: A, right: B): Constraint =
  makeConstraint(left, relGe, right)

proc `>=`*(left, right: Variable): Constraint =
  makeConstraint(left, relGe, right)

proc `>=`*[A: ConstraintSide](left: A, right: KiwiScalar): Constraint =
  makeConstraint(left, relGe, right)

proc `>=`*[B: ConstraintSide](left: KiwiScalar, right: B): Constraint =
  makeConstraint(left, relGe, right)

proc `==`*[A: ConstraintSide, B: ConstraintSide](left: A, right: B): Constraint =
  makeConstraint(left, relEq, right)

proc `==`*(left, right: Variable): Constraint =
  makeConstraint(left, relEq, right)

proc `==`*[A: ConstraintSide](left: A, right: KiwiScalar): Constraint =
  makeConstraint(left, relEq, right)

proc `==`*[B: ConstraintSide](left: KiwiScalar, right: B): Constraint =
  makeConstraint(left, relEq, right)
