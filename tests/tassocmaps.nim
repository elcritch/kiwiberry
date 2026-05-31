import std/assertions

import kiwiberry/internal/[assocmaps, symbols]

block sortedIterationAndMutation:
  let first = initSymbol(skSlack, SymbolId(1))
  let second = initSymbol(skError, SymbolId(2))
  let third = initSymbol(skDummy, SymbolId(3))
  var map = initAssocMap[Symbol, int]()

  map[third] = 30
  map[first] = 10
  map[second] = 20
  map[second] = 21

  var keys: seq[Symbol]
  for key in map.keys:
    keys.add key

  doAssert keys == @[first, second, third]
  doAssert map.len == 3
  doAssert map[first] == 10
  doAssert map[second] == 21

  map.withValue(second, value):
    value[] = 22
  do:
    doAssert false

  doAssert map[second] == 22

  let immutable = map
  immutable.withValue(second, value):
    doAssert value == 22
  do:
    doAssert false

block popAndDelete:
  let first = initSymbol(skSlack, SymbolId(1))
  let second = initSymbol(skError, SymbolId(2))
  var map = initAssocMap[Symbol, int]()
  map[first] = 10
  map[second] = 20

  var value: int
  doAssert map.pop(first, value)
  doAssert value == 10
  doAssert not map.hasKey(first)
  doAssert not map.pop(first, value)

  map.del(second)
  doAssert map.len == 0

block missingWithValue:
  let first = initSymbol(skSlack, SymbolId(1))
  var map = initAssocMap[Symbol, int]()
  var sawMissing = false

  map.withValue(first, value):
    discard value[]
    doAssert false
  do:
    sawMissing = true

  doAssert sawMissing
