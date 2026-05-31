## Validation helpers and input error types.

import std/math

type InvalidSolverValueError* = object of ValueError
  ## Numeric solver input is not usable.

func isFiniteNumber*(value: float64): bool =
  ## Returns true when `value` is neither NaN nor infinity.
  classify(value) notin {fcNan, fcInf, fcNegInf}

func requireFiniteNumber*(value: float64, name: string): float64 =
  ## Returns `value` or raises when it is NaN or infinity.
  if not value.isFiniteNumber:
    raise newException(InvalidSolverValueError, name & " must be finite.")
  value

func requireNonZeroFiniteNumber*(value: float64, name: string): float64 =
  ## Returns `value` or raises when it is zero, NaN, or infinity.
  discard requireFiniteNumber(value, name)
  if value == 0.0:
    raise newException(InvalidSolverValueError, name & " must not be zero.")
  value
