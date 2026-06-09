## Constraint strength helpers.

import ./scalars

type Strength* = distinct KiwiScalar ## Weighted priority for soft constraints.

proc `==`*(a, b: Strength): bool {.borrow.}
proc `<`*(a, b: Strength): bool {.borrow.}
proc `<=`*(a, b: Strength): bool {.borrow.}
proc `$`*(value: Strength): string {.borrow.}

func createStrength*(a, b, c: KiwiScalar, weight: KiwiScalar = 1'ks): Strength =
  ## Creates a strength from three weighted priority components.
  let checkedWeight = weight.requireFinite("strength weight")
  let aa = max(
    0'ks, min(1000'ks, a.requireFinite("strength a") * checkedWeight)
  )
  let bb = max(
    0'ks, min(1000'ks, b.requireFinite("strength b") * checkedWeight)
  )
  let cc = max(
    0'ks, min(1000'ks, c.requireFinite("strength c") * checkedWeight)
  )
  Strength(aa * 1_000_000'ks + bb * 1_000'ks + cc)

const
  Required* = createStrength(1000'ks, 1000'ks, 1000'ks) ## Required constraint strength.
  Strong* = createStrength(1'ks, 0'ks, 0'ks) ## Strong soft constraint strength.
  Medium* = createStrength(0'ks, 1'ks, 0'ks) ## Medium soft constraint strength.
  Weak* = createStrength(0'ks, 0'ks, 1'ks) ## Weak soft constraint strength.

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
  Strength(max(0'ks, min(Required.KiwiScalar, strength.KiwiScalar)))
