import ./[scalars, variables]

type
  Term* = object
    variableValue: Variable
    coefficientValue: KiwiScalar

  Expression* = object
    termsValue: seq[Term]
    constantValue: KiwiScalar

proc initTerm*(variable: Variable, coefficient: KiwiScalar = 1): Term =
  Term(variableValue: variable, coefficientValue: coefficient)

proc initExpression*(
    terms: openArray[Term] = [], constant: KiwiScalar = 0
): Expression =
  Expression(termsValue: @terms, constantValue: constant)

proc toExpression*(variable: Variable): Expression =
  initExpression([initTerm(variable)])

proc toExpression*(term: Term): Expression =
  initExpression([term])

proc toExpression*(constant: KiwiScalar): Expression =
  initExpression(constant = constant)

proc variable*(term: Term): Variable =
  term.variableValue

proc coefficient*(term: Term): KiwiScalar =
  term.coefficientValue

proc value*(term: Term): KiwiScalar =
  term.coefficientValue * term.variableValue.value

proc terms*(expression: Expression): lent seq[Term] =
  expression.termsValue

proc constant*(expression: Expression): KiwiScalar =
  expression.constantValue

proc len*(expression: Expression): int =
  expression.termsValue.len

iterator items*(expression: Expression): Term =
  for term in expression.termsValue:
    yield term

proc value*(expression: Expression): KiwiScalar =
  result = expression.constantValue
  for term in expression.termsValue:
    result += term.value

proc `-`*(variable: Variable): Term =
  initTerm(variable, -1)

proc `*`*(variable: Variable, coefficient: KiwiScalar): Term =
  initTerm(variable, coefficient)

proc `*`*(coefficient: KiwiScalar, variable: Variable): Term =
  variable * coefficient

proc `/`*(variable: Variable, denominator: KiwiScalar): Term =
  variable * (1 / denominator)

proc `-`*(term: Term): Term =
  initTerm(term.variableValue, -term.coefficientValue)

proc `*`*(term: Term, coefficient: KiwiScalar): Term =
  initTerm(term.variableValue, term.coefficientValue * coefficient)

proc `*`*(coefficient: KiwiScalar, term: Term): Term =
  term * coefficient

proc `/`*(term: Term, denominator: KiwiScalar): Term =
  term * (1 / denominator)

proc `-`*(expression: Expression): Expression =
  result = initExpression(constant = -expression.constantValue)
  for term in expression.termsValue:
    result.termsValue.add -term

proc `*`*(expression: Expression, coefficient: KiwiScalar): Expression =
  result = initExpression(constant = expression.constantValue * coefficient)
  for term in expression.termsValue:
    result.termsValue.add term * coefficient

proc `*`*(coefficient: KiwiScalar, expression: Expression): Expression =
  expression * coefficient

proc `/`*(expression: Expression, denominator: KiwiScalar): Expression =
  expression * (1 / denominator)

proc `+`*(left, right: Expression): Expression =
  result = initExpression(constant = left.constantValue + right.constantValue)
  result.termsValue = newSeqOfCap[Term](left.termsValue.len + right.termsValue.len)
  result.termsValue.add left.termsValue
  result.termsValue.add right.termsValue

proc `+`*(expression: Expression, term: Term): Expression =
  result = expression
  result.termsValue.add term

proc `+`*(term: Term, expression: Expression): Expression =
  expression + term

proc `+`*(expression: Expression, variable: Variable): Expression =
  expression + initTerm(variable)

proc `+`*(variable: Variable, expression: Expression): Expression =
  expression + variable

proc `+`*(expression: Expression, constant: KiwiScalar): Expression =
  result = expression
  result.constantValue += constant

proc `+`*(constant: KiwiScalar, expression: Expression): Expression =
  expression + constant

proc `+`*(left, right: Term): Expression =
  initExpression([left, right])

proc `+`*(term: Term, variable: Variable): Expression =
  term + initTerm(variable)

proc `+`*(variable: Variable, term: Term): Expression =
  term + variable

proc `+`*(term: Term, constant: KiwiScalar): Expression =
  initExpression([term], constant)

proc `+`*(constant: KiwiScalar, term: Term): Expression =
  term + constant

proc `+`*(left, right: Variable): Expression =
  initTerm(left) + right

proc `+`*(variable: Variable, constant: KiwiScalar): Expression =
  initTerm(variable) + constant

proc `+`*(constant: KiwiScalar, variable: Variable): Expression =
  variable + constant

proc `-`*(left, right: Expression): Expression =
  left + -right

proc `-`*(expression: Expression, term: Term): Expression =
  expression + -term

proc `-`*(term: Term, expression: Expression): Expression =
  toExpression(term) - expression

proc `-`*(expression: Expression, variable: Variable): Expression =
  expression + -variable

proc `-`*(variable: Variable, expression: Expression): Expression =
  toExpression(variable) - expression

proc `-`*(expression: Expression, constant: KiwiScalar): Expression =
  expression + -constant

proc `-`*(constant: KiwiScalar, expression: Expression): Expression =
  toExpression(constant) - expression

proc `-`*(left, right: Term): Expression =
  left + -right

proc `-`*(term: Term, variable: Variable): Expression =
  term + -variable

proc `-`*(variable: Variable, term: Term): Expression =
  initTerm(variable) - term

proc `-`*(term: Term, constant: KiwiScalar): Expression =
  term + -constant

proc `-`*(constant: KiwiScalar, term: Term): Expression =
  toExpression(constant) - toExpression(term)

proc `-`*(left, right: Variable): Expression =
  initTerm(left) - right

proc `-`*(variable: Variable, constant: KiwiScalar): Expression =
  initTerm(variable) - constant

proc `-`*(constant: KiwiScalar, variable: Variable): Expression =
  toExpression(constant) - toExpression(variable)
