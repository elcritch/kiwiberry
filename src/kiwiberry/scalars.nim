## Numeric scalar type used by the solver.

import std/hashes

import ./validation

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
proc abs*(value: KiwiScalar): KiwiScalar {.borrow.}
proc min*(a, b: KiwiScalar): KiwiScalar {.borrow.}
proc max*(a, b: KiwiScalar): KiwiScalar {.borrow.}

converter toKiwiScalar*(value: SomeInteger): KiwiScalar =
  ## Converts an integer literal/value to `KiwiScalar`.
  KiwiScalar(requireFiniteNumber(value.float64, "integer scalar"))

converter toKiwiScalar*(value: SomeFloat): KiwiScalar =
  ## Converts a floating-point literal/value to `KiwiScalar`.
  KiwiScalar(requireFiniteNumber(value.float64, "floating-point scalar"))

func requireFinite*(value: KiwiScalar, name: string): KiwiScalar =
  ## Returns `value` or raises when it is NaN or infinity.
  KiwiScalar(requireFiniteNumber(value.float64, name))

func isFinite*(value: KiwiScalar): bool =
  ## Returns true when `value` is neither NaN nor infinity.
  value.float64.isFiniteNumber

func nearZero*(value: KiwiScalar): bool =
  ## Returns true when `value` is within Kiwi's zero tolerance.
  abs(value).float64 < 1.0e-8
