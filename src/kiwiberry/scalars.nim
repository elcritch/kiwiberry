import std/hashes

type KiwiScalar* = distinct float64

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
  KiwiScalar(float64(value))

converter toKiwiScalar*(value: SomeFloat): KiwiScalar =
  KiwiScalar(float64(value))

func toFloat*(value: KiwiScalar): float64 =
  float64(value)

func abs*(value: KiwiScalar): KiwiScalar =
  KiwiScalar(abs(float64(value)))

func min*(a, b: KiwiScalar): KiwiScalar =
  if a <= b: a else: b

func max*(a, b: KiwiScalar): KiwiScalar =
  if a <= b: b else: a

func nearZero*(value: KiwiScalar): bool =
  abs(value).toFloat < 1.0e-8
