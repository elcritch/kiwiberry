## Constraint construction and query API.

import std/hashes
when not defined(js):
  import std/atomics

import ./[expressions, scalars, strengths, variables]

type
  Relation* = enum ## Relational operator used by a constraint.
    relLe ## Less-than-or-equal relation: expression <= 0.
    relGe ## Greater-than-or-equal relation: expression >= 0.
    relEq ## Equality relation: expression == 0.

  Constraint* = ref object ## Identity-bearing linear constraint.
    id: uint64
    expressionValue: Expression
    relationValue: Relation
    strengthValue: Strength

when defined(js):
  var nextConstraintId = 1'u64

  proc takeConstraintId(): uint64 =
    result = nextConstraintId
    inc nextConstraintId

else:
  var nextConstraintId: Atomic[uint64]
  nextConstraintId.store(1)

  proc takeConstraintId(): uint64 =
    nextConstraintId.fetchAdd(1)

proc reduce(expression: Expression): Expression =
  let expressionTerms = expression.terms
  var terms = newSeqOfCap[Term](expressionTerms.len)

  for index in 0 ..< expressionTerms.len:
    let term {.cursor.} = expressionTerms[index]
    let id = term.variable.variableId
    var found = false
    for existingIndex in 0 ..< terms.len:
      if terms[existingIndex].variable.variableId == id:
        let variable = terms[existingIndex].variable
        let coefficient = terms[existingIndex].coefficient + term.coefficient
        terms[existingIndex] = initTerm(variable, coefficient)
        found = true
        break
    if not found:
      terms.add term

  var compactTerms = newSeqOfCap[Term](terms.len)
  for term in terms:
    if not term.coefficient.nearZero:
      compactTerms.add term
  initExpression(compactTerms, expression.constant)

proc newConstraint*(
    expression: Expression, relation: Relation, strength: Strength = Required
): Constraint =
  ## Creates a constraint from an already-normalized expression.
  ##
  ## The expression is reduced by variable identity and the strength is clipped
  ## into Kiwi's supported strength range.
  new(result)
  result.id = takeConstraintId()
  result.expressionValue = reduce(expression)
  result.relationValue = relation
  result.strengthValue = strength.clip

proc expression*(constraint: Constraint): lent Expression =
  ## Returns the reduced expression stored by `constraint`.
  constraint.expressionValue

proc relation*(constraint: Constraint): Relation =
  ## Returns the relation used by `constraint`.
  constraint.relationValue

proc strength*(constraint: Constraint): Strength =
  ## Returns the clipped strength used by `constraint`.
  constraint.strengthValue

proc sameConstraint*(a, b: Constraint): bool =
  ## Returns true when both handles refer to the same constraint identity.
  not a.isNil and not b.isNil and a.id == b.id

proc sameExpressionShape(a, b: Expression): bool =
  if a.constant != b.constant or a.len != b.len:
    return false

  for left in a:
    var found = false
    for right in b:
      if left.variable.sameVariable(right.variable):
        if left.coefficient != right.coefficient:
          return false
        found = true
        break
    if not found:
      return false

  true

proc sameShape*(a, b: Constraint): bool =
  ## Returns true when two constraints have the same expression, relation, and strength.
  not a.isNil and not b.isNil and a.relation == b.relation and a.strength == b.strength and
    sameExpressionShape(a.expression, b.expression)

proc `==`*(a, b: Constraint): bool =
  ## Compares constraint identity, not structural equality.
  a.sameConstraint(b)

proc hash*(constraint: Constraint): Hash =
  ## Hashes a constraint by identity.
  hash(constraint.id)

proc violated*(constraint: Constraint): bool =
  ## Returns true when the current variable values violate `constraint`.
  case constraint.relationValue
  of relEq:
    not constraint.expressionValue.value.nearZero
  of relGe:
    constraint.expressionValue.value < 0
  of relLe:
    constraint.expressionValue.value > 0

proc withStrength*(constraint: Constraint, strength: Strength): Constraint =
  ## Returns a new constraint with the same expression/relation and new strength.
  newConstraint(constraint.expressionValue, constraint.relationValue, strength)

proc `|`*(constraint: Constraint, strength: Strength): Constraint =
  ## Convenience syntax for `withStrength`.
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
type ConstraintValue = Expression | Term | Variable | KiwiScalar

proc le*[A: ConstraintValue, B: ConstraintValue](left: A, right: B): Constraint =
  ## Creates a less-than-or-equal constraint from `left <= right`.
  makeConstraint(left, relLe, right)

proc ge*[A: ConstraintValue, B: ConstraintValue](left: A, right: B): Constraint =
  ## Creates a greater-than-or-equal constraint from `left >= right`.
  makeConstraint(left, relGe, right)

proc eq*[A: ConstraintValue, B: ConstraintValue](left: A, right: B): Constraint =
  ## Creates an equality constraint from `left == right`.
  makeConstraint(left, relEq, right)

proc `<=`*[A: ConstraintSide, B: ConstraintSide](left: A, right: B): Constraint =
  ## Creates a less-than-or-equal constraint from `left <= right`.
  makeConstraint(left, relLe, right)

proc `<=`*(left, right: Variable): Constraint =
  makeConstraint(left, relLe, right)

proc `<=`*[A: ConstraintSide](left: A, right: KiwiScalar): Constraint =
  ## Creates a less-than-or-equal constraint from `left <= right`.
  makeConstraint(left, relLe, right)

proc `<=`*[B: ConstraintSide](left: KiwiScalar, right: B): Constraint =
  # Nim rewrites `x >= c` to `c <= x`, so scalar-left comparisons are
  # treated as the greater-than-or-equal constraint for the right side.
  makeConstraint(right, relGe, left)

proc `>=`*[A: ConstraintSide, B: ConstraintSide](left: A, right: B): Constraint =
  ## Creates a greater-than-or-equal constraint from `left >= right`.
  makeConstraint(left, relGe, right)

proc `>=`*(left, right: Variable): Constraint =
  makeConstraint(left, relGe, right)

proc `>=`*[A: ConstraintSide](left: A, right: KiwiScalar): Constraint =
  ## Creates a greater-than-or-equal constraint from `left >= right`.
  makeConstraint(left, relGe, right)

proc `>=`*[B: ConstraintSide](left: KiwiScalar, right: B): Constraint =
  makeConstraint(left, relGe, right)

proc `==`*[A: ConstraintSide, B: ConstraintSide](left: A, right: B): Constraint =
  ## Creates an equality constraint from `left == right`.
  makeConstraint(left, relEq, right)

proc `==`*(left, right: Variable): Constraint =
  makeConstraint(left, relEq, right)

proc `==`*[A: ConstraintSide](left: A, right: KiwiScalar): Constraint =
  ## Creates an equality constraint from `left == right`.
  makeConstraint(left, relEq, right)

proc `==`*[B: ConstraintSide](left: KiwiScalar, right: B): Constraint =
  makeConstraint(left, relEq, right)
