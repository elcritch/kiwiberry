import ./[constraints, variables]

type
  UnsatisfiableConstraintError* = object of CatchableError
    constraint*: Constraint

  UnknownConstraintError* = object of CatchableError
    constraint*: Constraint

  DuplicateConstraintError* = object of CatchableError
    constraint*: Constraint

  UnknownEditVariableError* = object of CatchableError
    variable*: Variable

  DuplicateEditVariableError* = object of CatchableError
    variable*: Variable

  BadRequiredStrengthError* = object of CatchableError

  InternalSolverError* = object of CatchableError

proc raiseUnsatisfiableConstraint*(constraint: Constraint) {.noinline, noreturn.} =
  var error =
    newException(UnsatisfiableConstraintError, "The constraint can not be satisfied.")
  error.constraint = constraint
  raise error

proc raiseUnknownConstraint*(constraint: Constraint) {.noinline, noreturn.} =
  var error = newException(
    UnknownConstraintError, "The constraint has not been added to the solver."
  )
  error.constraint = constraint
  raise error

proc raiseDuplicateConstraint*(constraint: Constraint) {.noinline, noreturn.} =
  var error = newException(
    DuplicateConstraintError, "The constraint has already been added to the solver."
  )
  error.constraint = constraint
  raise error

proc raiseUnknownEditVariable*(variable: Variable) {.noinline, noreturn.} =
  var error = newException(
    UnknownEditVariableError, "The edit variable has not been added to the solver."
  )
  error.variable = variable
  raise error

proc raiseDuplicateEditVariable*(variable: Variable) {.noinline, noreturn.} =
  var error = newException(
    DuplicateEditVariableError,
    "The edit variable has already been added to the solver.",
  )
  error.variable = variable
  raise error

proc raiseBadRequiredStrength*() {.noinline, noreturn.} =
  raise newException(
    BadRequiredStrengthError, "A required strength cannot be used in this context."
  )

proc raiseInternalSolverError*(message: string) {.noinline, noreturn.} =
  raise newException(InternalSolverError, message)
