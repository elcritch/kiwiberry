## Exception types raised by solver operations.

import ./[constraints, variables]

type
  UnsatisfiableConstraintError* = object of CatchableError
    ## Required constraint cannot be satisfied.
    constraint*: Constraint ## Constraint that caused the failure.

  UnknownConstraintError* = object of CatchableError
    ## Constraint was not added to the solver.
    constraint*: Constraint ## Constraint that was requested.

  DuplicateConstraintError* = object of CatchableError
    ## Constraint has already been added.
    constraint*: Constraint ## Duplicate constraint.

  UnknownEditVariableError* = object of CatchableError
    ## Variable is not an active edit variable.
    variable*: Variable ## Variable that was requested.

  DuplicateEditVariableError* = object of CatchableError
    ## Variable is already an edit variable.
    variable*: Variable ## Duplicate edit variable.

  BadRequiredStrengthError* = object of CatchableError
    ## Required strength was used for an edit variable.

  InternalSolverError* = object of CatchableError
    ## Solver reached an unexpected internal state.

proc raiseUnsatisfiableConstraint*(constraint: Constraint) {.noinline, noreturn.} =
  ## Raises `UnsatisfiableConstraintError` for `constraint`.
  var error =
    newException(UnsatisfiableConstraintError, "The constraint can not be satisfied.")
  error.constraint = constraint
  raise error

proc raiseUnknownConstraint*(constraint: Constraint) {.noinline, noreturn.} =
  ## Raises `UnknownConstraintError` for `constraint`.
  var error = newException(
    UnknownConstraintError, "The constraint has not been added to the solver."
  )
  error.constraint = constraint
  raise error

proc raiseDuplicateConstraint*(constraint: Constraint) {.noinline, noreturn.} =
  ## Raises `DuplicateConstraintError` for `constraint`.
  var error = newException(
    DuplicateConstraintError, "The constraint has already been added to the solver."
  )
  error.constraint = constraint
  raise error

proc raiseUnknownEditVariable*(variable: Variable) {.noinline, noreturn.} =
  ## Raises `UnknownEditVariableError` for `variable`.
  var error = newException(
    UnknownEditVariableError, "The edit variable has not been added to the solver."
  )
  error.variable = variable
  raise error

proc raiseDuplicateEditVariable*(variable: Variable) {.noinline, noreturn.} =
  ## Raises `DuplicateEditVariableError` for `variable`.
  var error = newException(
    DuplicateEditVariableError,
    "The edit variable has already been added to the solver.",
  )
  error.variable = variable
  raise error

proc raiseBadRequiredStrength*() {.noinline, noreturn.} =
  ## Raises `BadRequiredStrengthError`.
  raise newException(
    BadRequiredStrengthError, "A required strength cannot be used in this context."
  )

proc raiseInternalSolverError*(message: string) {.noinline, noreturn.} =
  ## Raises `InternalSolverError` with `message`.
  raise newException(InternalSolverError, message)
