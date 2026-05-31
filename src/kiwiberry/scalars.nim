## Numeric scalar type used by the solver.

import std/hashes

type KiwiScalar* = distinct float64 ## Solver numeric scalar.

proc `+`*(a, b: KiwiScalar): KiwiScalar {.borrow.}
proc `-`*(a, b: KiwiScalar): KiwiScalar {.borrow.}
proc `*`*(a, b: KiwiScalar): KiwiScalar {.borrow.}
proc `/`*(a, b: KiwiScalar): KiwiScalar {.borrow.}
proc `-`*(a: KiwiScalar): KiwiScalar {.borrow.}

proc `<`*(a, b: KiwiScalar): bool {.borrow.}
proc `<=`*(a, b: KiwiScalar): bool {.borrow.}
proc `==`*(a, b: KiwiScalar): bool {.borrow.}
proc hash*(value: KiwiScalar): Hash {.borrow.}
proc `$`*(value: KiwiScalar): string {.borrow.}

proc `+=`*(a: var KiwiScalar, b: KiwiScalar) {.borrow.}
proc `-=`*(a: var KiwiScalar, b: KiwiScalar) {.borrow.}
proc `*=`*(a: var KiwiScalar, b: KiwiScalar) {.borrow.}
proc `/=`*(a: var KiwiScalar, b: KiwiScalar) {.borrow.}

converter toKiwiScalar*(value: SomeInteger): KiwiScalar =
  ## Converts an integer literal/value to `KiwiScalar`.
  KiwiScalar(float64(value))

converter toKiwiScalar*(value: SomeFloat): KiwiScalar =
  ## Converts a floating-point literal/value to `KiwiScalar`.
  KiwiScalar(float64(value))

func toFloat*(value: KiwiScalar): float64 =
  ## Converts `value` to its `float64` base representation.
  float64(value)

func abs*(value: KiwiScalar): KiwiScalar =
  ## Returns the absolute value of `value`.
  KiwiScalar(abs(float64(value)))

func min*(a, b: KiwiScalar): KiwiScalar =
  ## Returns the smaller scalar.
  if a <= b: a else: b

func max*(a, b: KiwiScalar): KiwiScalar =
  ## Returns the larger scalar.
  if a <= b: b else: a

func nearZero*(value: KiwiScalar): bool =
  ## Returns true when `value` is within Kiwi's zero tolerance.
  abs(value).toFloat < 1.0e-8
