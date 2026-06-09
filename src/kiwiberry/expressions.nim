## Linear terms and expressions.

import ./[scalars, variables]

type
  Term* = object ## Variable/coefficient pair.
    variableValue: Variable
    coefficientValue: KiwiScalar

  Expression* = object ## Linear expression plus constant.
    termsValue: seq[Term]
    constantValue: KiwiScalar

proc initTerm*(variable: Variable, coefficient: KiwiScalar = 1'ks): Term =
  ## Creates a term for `coefficient * variable`.
  Term(
    variableValue: variable,
    coefficientValue: coefficient.requireFinite("term coefficient"),
  )

proc initExpression*(
    terms: openArray[Term] = [], constant: KiwiScalar = 0'ks
): Expression =
  ## Creates an expression from terms and a constant.
  Expression(
    termsValue: @terms, constantValue: constant.requireFinite("expression constant")
  )

proc toExpression*(variable: Variable): Expression =
  ## Converts a variable to a one-term expression.
  initExpression([initTerm(variable)])

proc toExpression*(term: Term): Expression =
  ## Converts a term to a one-term expression.
  initExpression([term])

proc toExpression*(constant: KiwiScalar): Expression =
  ## Converts a constant to an expression with no terms.
  initExpression(constant = constant)

proc variable*(term: Term): lent Variable =
  ## Returns the variable used by `term`.
  term.variableValue

proc coefficient*(term: Term): KiwiScalar =
  ## Returns the coefficient used by `term`.
  term.coefficientValue

proc value*(term: Term): KiwiScalar =
  ## Evaluates the term using the variable's current value.
  term.coefficientValue * term.variableValue.value

proc terms*(expression: Expression): lent seq[Term] =
  ## Returns the expression terms.
  expression.termsValue

proc constant*(expression: Expression): KiwiScalar =
  ## Returns the expression constant.
  expression.constantValue

proc len*(expression: Expression): int =
  ## Returns the number of terms in the expression.
  expression.termsValue.len

iterator items*(expression: Expression): lent Term =
  for index in 0 ..< expression.termsValue.len:
    yield expression.termsValue[index]

proc value*(expression: Expression): KiwiScalar =
  ## Evaluates the expression using current variable values.
  result = expression.constantValue
  for term in expression.termsValue:
    result += term.value

proc `-`*(variable: Variable): Term =
  initTerm(variable, -1'ks)

proc `*`*(variable: Variable, coefficient: KiwiScalar): Term =
  initTerm(variable, coefficient)

proc `*`*(coefficient: KiwiScalar, variable: Variable): Term =
  variable * coefficient

proc `/`*(variable: Variable, denominator: KiwiScalar): Term =
  variable * (1'ks / denominator)

proc `-`*(term: Term): Term =
  initTerm(term.variableValue, -term.coefficientValue)

proc `*`*(term: Term, coefficient: KiwiScalar): Term =
  initTerm(term.variableValue, term.coefficientValue * coefficient)

proc `*`*(coefficient: KiwiScalar, term: Term): Term =
  term * coefficient

proc `/`*(term: Term, denominator: KiwiScalar): Term =
  term * (1'ks / denominator)

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
  expression * (1'ks / denominator)

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
