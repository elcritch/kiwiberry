## Internal scalar operations for solver tableau arithmetic.
##
## Public scalar operations validate that results stay finite. Solver internals
## call these only after user input has crossed those validation boundaries.

import ../scalars

const
  rawZero* = KiwiScalar(0.0)
  rawOne* = KiwiScalar(1.0)
  rawMinusOne* = KiwiScalar(-1.0)
  rawMax* = KiwiScalar(float64.high)

func uncheckedAdd*(a, b: KiwiScalar): KiwiScalar {.inline.} =
  KiwiScalar(a.toFloat + b.toFloat)

func uncheckedSub*(a, b: KiwiScalar): KiwiScalar {.inline.} =
  KiwiScalar(a.toFloat - b.toFloat)

func uncheckedMul*(a, b: KiwiScalar): KiwiScalar {.inline.} =
  KiwiScalar(a.toFloat * b.toFloat)

func uncheckedDiv*(a, b: KiwiScalar): KiwiScalar {.inline.} =
  KiwiScalar(a.toFloat / b.toFloat)

func uncheckedNeg*(value: KiwiScalar): KiwiScalar {.inline.} =
  KiwiScalar(-value.toFloat)

func uncheckedNearZero*(value: KiwiScalar): bool {.inline.} =
  abs(value.toFloat) < 1.0e-8
