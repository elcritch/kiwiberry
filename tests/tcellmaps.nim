import std/assertions

import kiwiberry
import kiwiberry/internal/[cellmaps, symbols]

block sortedInsertAndAdd:
  let first = initSymbol(skSlack, SymbolId(1))
  let second = initSymbol(skError, SymbolId(2))
  let third = initSymbol(skDummy, SymbolId(3))
  var map = initCellMap()

  map.add(third, 30.KiwiScalar)
  map.add(first, 10.KiwiScalar)
  map.add(second, 20.KiwiScalar)
  map.add(second, 2.KiwiScalar)

  var keys: seq[Symbol]
  for key in map.keys:
    keys.add key

  doAssert keys == @[first, second, third]
  doAssert map.len == 3
  doAssert map[first] == 10.KiwiScalar
  doAssert map[second] == 22.KiwiScalar

block removeNearZero:
  let symbol = initSymbol(skSlack, SymbolId(1))
  var map = initCellMap()

  map.add(symbol, 2.KiwiScalar)
  map.add(symbol, -2.KiwiScalar)

  doAssert map.len == 0
  doAssert map.getOrDefault(symbol, 7.KiwiScalar) == 7.KiwiScalar

block popAndMutate:
  let first = initSymbol(skSlack, SymbolId(1))
  let second = initSymbol(skError, SymbolId(2))
  var map = initCellMap()
  map.add(first, 10.KiwiScalar)
  map.add(second, 20.KiwiScalar)

  for _, coefficient in map.mpairs:
    coefficient *= 2.KiwiScalar

  doAssert map[first] == 20.KiwiScalar
  doAssert map[second] == 40.KiwiScalar

  var coefficient: KiwiScalar
  doAssert map.pop(first, coefficient)
  doAssert coefficient == 20.KiwiScalar
  doAssert not map.hasKey(first)
  doAssert not map.pop(first, coefficient)
