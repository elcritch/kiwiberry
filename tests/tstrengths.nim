import std/assertions

import kiwiberry

block predefinedStrengthOrder:
  doAssert Weak < Medium
  doAssert Medium < Strong
  doAssert Strong < Required

block createStrengthOrder:
  doAssert createStrength(0, 0, 1) < createStrength(0, 1, 0)
  doAssert createStrength(0, 1, 0) < createStrength(1, 0, 0)
  doAssert createStrength(1, 0, 0, 1) < createStrength(1, 0, 0, 4)

block clipStrength:
  doAssert clip(createStrength(2000, 2000, 2000)) == Required
  doAssert clip(Strength(-1.KiwiScalar)).toKiwiScalar == 0.KiwiScalar
