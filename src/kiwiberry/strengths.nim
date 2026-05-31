## Constraint strength helpers.

import ./scalars

type Strength* = distinct KiwiScalar ## Weighted priority for soft constraints.

proc `==`*(a, b: Strength): bool {.borrow.}
proc `<`*(a, b: Strength): bool {.borrow.}
proc `<=`*(a, b: Strength): bool {.borrow.}
proc `$`*(value: Strength): string {.borrow.}

func toKiwiScalar*(strength: Strength): KiwiScalar =
  ## Converts `strength` to its scalar weight.
  KiwiScalar(strength)

func createStrength*(a, b, c: KiwiScalar, weight: KiwiScalar = 1): Strength =
  ## Creates a strength from three weighted priority components.
  let checkedWeight = weight.requireFinite("strength weight")
  let aa = max(
    0.KiwiScalar, min(1000.KiwiScalar, a.requireFinite("strength a") * checkedWeight)
  )
  let bb = max(
    0.KiwiScalar, min(1000.KiwiScalar, b.requireFinite("strength b") * checkedWeight)
  )
  let cc = max(
    0.KiwiScalar, min(1000.KiwiScalar, c.requireFinite("strength c") * checkedWeight)
  )
  Strength(aa * 1_000_000.KiwiScalar + bb * 1_000.KiwiScalar + cc)

const
  Required* = createStrength(1000, 1000, 1000) ## Required constraint strength.
  Strong* = createStrength(1, 0, 0) ## Strong soft constraint strength.
  Medium* = createStrength(0, 1, 0) ## Medium soft constraint strength.
  Weak* = createStrength(0, 0, 1) ## Weak soft constraint strength.

func required*(): Strength =
  ## Returns `Required`.
  Required
func strong*(): Strength =
  ## Returns `Strong`.
  Strong
func medium*(): Strength =
  ## Returns `Medium`.
  Medium
func weak*(): Strength =
  ## Returns `Weak`.
  Weak

func clip*(strength: Strength): Strength =
  ## Clips `strength` into the supported `0..Required` range.
  Strength(max(0.KiwiScalar, min(Required.toKiwiScalar, strength.toKiwiScalar)))
