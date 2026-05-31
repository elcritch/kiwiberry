## Numeric scalar type used by the solver.

import std/hashes

import ./validation

type KiwiScalar* = distinct float64 ## Solver numeric scalar.

func checkedScalar(value: float64, name: string): KiwiScalar =
  KiwiScalar(requireFiniteNumber(value, name))

func `+`*(a, b: KiwiScalar): KiwiScalar =
  ## Adds two finite scalar values.
  checkedScalar(float64(a) + float64(b), "scalar addition")

func `-`*(a, b: KiwiScalar): KiwiScalar =
  ## Subtracts two finite scalar values.
  checkedScalar(float64(a) - float64(b), "scalar subtraction")

func `*`*(a, b: KiwiScalar): KiwiScalar =
  ## Multiplies two finite scalar values.
  checkedScalar(float64(a) * float64(b), "scalar multiplication")

func `/`*(a, b: KiwiScalar): KiwiScalar =
  ## Divides two finite scalar values.
  let denominator = requireNonZeroFiniteNumber(float64(b), "scalar denominator")
  checkedScalar(float64(a) / denominator, "scalar division")

func `-`*(a: KiwiScalar): KiwiScalar =
  ## Negates a finite scalar value.
  checkedScalar(-float64(a), "scalar negation")

proc `<`*(a, b: KiwiScalar): bool {.borrow.}
proc `<=`*(a, b: KiwiScalar): bool {.borrow.}
proc `==`*(a, b: KiwiScalar): bool {.borrow.}
proc hash*(value: KiwiScalar): Hash {.borrow.}
proc `$`*(value: KiwiScalar): string {.borrow.}

proc `+=`*(a: var KiwiScalar, b: KiwiScalar) =
  ## Adds `b` to `a`.
  a = a + b

proc `-=`*(a: var KiwiScalar, b: KiwiScalar) =
  ## Subtracts `b` from `a`.
  a = a - b

proc `*=`*(a: var KiwiScalar, b: KiwiScalar) =
  ## Multiplies `a` by `b`.
  a = a * b

proc `/=`*(a: var KiwiScalar, b: KiwiScalar) =
  ## Divides `a` by `b`.
  a = a / b

converter toKiwiScalar*(value: SomeInteger): KiwiScalar =
  ## Converts an integer literal/value to `KiwiScalar`.
  checkedScalar(float64(value), "integer scalar")

converter toKiwiScalar*(value: SomeFloat): KiwiScalar =
  ## Converts a floating-point literal/value to `KiwiScalar`.
  checkedScalar(float64(value), "floating-point scalar")

func toFloat*(value: KiwiScalar): float64 =
  ## Converts `value` to its `float64` base representation.
  float64(value)

func requireFinite*(value: KiwiScalar, name: string): KiwiScalar =
  ## Returns `value` or raises when it is NaN or infinity.
  checkedScalar(value.toFloat, name)

func isFinite*(value: KiwiScalar): bool =
  ## Returns true when `value` is neither NaN nor infinity.
  value.toFloat.isFiniteNumber

func abs*(value: KiwiScalar): KiwiScalar =
  ## Returns the absolute value of `value`.
  checkedScalar(abs(float64(value)), "scalar absolute value")

func min*(a, b: KiwiScalar): KiwiScalar =
  ## Returns the smaller scalar.
  discard a.requireFinite("left scalar")
  discard b.requireFinite("right scalar")
  if a <= b: a else: b

func max*(a, b: KiwiScalar): KiwiScalar =
  ## Returns the larger scalar.
  discard a.requireFinite("left scalar")
  discard b.requireFinite("right scalar")
  if a <= b: b else: a

func nearZero*(value: KiwiScalar): bool =
  ## Returns true when `value` is within Kiwi's zero tolerance.
  abs(value).toFloat < 1.0e-8
