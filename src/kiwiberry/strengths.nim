import ./scalars

type Strength* = distinct KiwiScalar

proc `==`*(a, b: Strength): bool {.borrow.}
proc `<`*(a, b: Strength): bool {.borrow.}
proc `<=`*(a, b: Strength): bool {.borrow.}
proc `$`*(value: Strength): string {.borrow.}

func toKiwiScalar*(strength: Strength): KiwiScalar =
  KiwiScalar(strength)

func createStrength*(a, b, c: KiwiScalar, weight: KiwiScalar = 1): Strength =
  let aa = max(0.KiwiScalar, min(1000.KiwiScalar, a * weight))
  let bb = max(0.KiwiScalar, min(1000.KiwiScalar, b * weight))
  let cc = max(0.KiwiScalar, min(1000.KiwiScalar, c * weight))
  Strength(aa * 1_000_000.KiwiScalar + bb * 1_000.KiwiScalar + cc)

const
  Required* = createStrength(1000, 1000, 1000)
  Strong* = createStrength(1, 0, 0)
  Medium* = createStrength(0, 1, 0)
  Weak* = createStrength(0, 0, 1)

func required*(): Strength =
  Required
func strong*(): Strength =
  Strong
func medium*(): Strength =
  Medium
func weak*(): Strength =
  Weak

func clip*(strength: Strength): Strength =
  Strength(max(0.KiwiScalar, min(Required.toKiwiScalar, strength.toKiwiScalar)))
