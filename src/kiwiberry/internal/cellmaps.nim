import ../scalars
import ./symbols

type
  Cell = object
    symbol: Symbol
    coefficient: KiwiScalar
    link: int ## Owner-defined handle, such as a tableau index node; 0 if unset.

  CellMap* = object
    entries: seq[Cell]

  CellChange* = enum
    ccUpdated ## The symbol's presence did not change.
    ccAdded ## The symbol now has a cell.
    ccRemoved ## The symbol's coefficient cancelled to zero.

proc initCellMap*(): CellMap {.inline.} =
  CellMap(entries: @[])

proc lowerIndex(map: CellMap, symbol: Symbol): int {.inline.} =
  var low = 0
  var high = map.entries.len
  while low < high:
    let mid = (low + high) shr 1
    if map.entries[mid].symbol < symbol:
      low = mid + 1
    else:
      high = mid
  low

proc findIndex(map: CellMap, symbol: Symbol): int {.inline.} =
  if map.entries.len <= 8:
    for index in 0 ..< map.entries.len:
      let current = map.entries[index].symbol
      if current == symbol:
        return index
      if symbol < current:
        return -1
    return -1

  let index = map.lowerIndex(symbol)
  if index < map.entries.len and map.entries[index].symbol == symbol: index else: -1

proc len*(map: CellMap): int {.inline.} =
  map.entries.len

proc hasKey*(map: CellMap, symbol: Symbol): bool {.inline.} =
  map.findIndex(symbol) >= 0

proc accumulate*(
    map: var CellMap, symbol: Symbol, coefficient: KiwiScalar, link: var int
): CellChange =
  ## Adds `coefficient` to `symbol`'s cell, dropping the cell when it cancels,
  ## and reports whether a cell appeared or vanished. A dropped cell's link is
  ## stored in `link`; a new cell has no link.
  let index = map.lowerIndex(symbol)
  if index < map.entries.len and map.entries[index].symbol == symbol:
    let next = map.entries[index].coefficient + coefficient
    if next.nearZero:
      link = map.entries[index].link
      map.entries.delete(index)
      ccRemoved
    else:
      map.entries[index].coefficient = next
      ccUpdated
  elif not coefficient.nearZero:
    map.entries.insert(Cell(symbol: symbol, coefficient: coefficient), index)
    ccAdded
  else:
    ccUpdated

proc accumulate*(
    map: var CellMap, symbol: Symbol, coefficient: KiwiScalar
): CellChange =
  var link: int
  map.accumulate(symbol, coefficient, link)

proc add*(map: var CellMap, symbol: Symbol, coefficient: KiwiScalar) =
  discard map.accumulate(symbol, coefficient)

proc linkFor*(map: CellMap, symbol: Symbol): int =
  ## The link of `symbol`'s cell, or 0 when it has none.
  let index = map.findIndex(symbol)
  if index >= 0:
    result = map.entries[index].link

proc setLink*(map: var CellMap, symbol: Symbol, link: int) =
  let index = map.findIndex(symbol)
  if index >= 0:
    map.entries[index].link = link

iterator links*(map: CellMap): (Symbol, int) =
  for cell in map.entries:
    yield (cell.symbol, cell.link)

iterator mlinks*(map: var CellMap): (Symbol, var int) =
  for cell in map.entries.mitems:
    yield (cell.symbol, cell.link)

proc `[]`*(map: CellMap, symbol: Symbol): KiwiScalar {.inline.} =
  let index = map.findIndex(symbol)
  if index < 0:
    raise newException(KeyError, "symbol not found")
  map.entries[index].coefficient

proc `[]=`*(map: var CellMap, symbol: Symbol, coefficient: KiwiScalar) {.inline.} =
  let index = map.lowerIndex(symbol)
  if index < map.entries.len and map.entries[index].symbol == symbol:
    map.entries[index].coefficient = coefficient
  else:
    map.entries.insert(Cell(symbol: symbol, coefficient: coefficient), index)

proc del*(map: var CellMap, symbol: Symbol) {.inline.} =
  let index = map.findIndex(symbol)
  if index >= 0:
    map.entries.delete(index)

proc pop*(
    map: var CellMap, symbol: Symbol, coefficient: var KiwiScalar
): bool {.inline.} =
  let index = map.findIndex(symbol)
  if index >= 0:
    coefficient = map.entries[index].coefficient
    map.entries.delete(index)
    result = true

proc getOrDefault*(
    map: CellMap, symbol: Symbol, default: KiwiScalar
): KiwiScalar {.inline.} =
  let index = map.findIndex(symbol)
  if index >= 0:
    map.entries[index].coefficient
  else:
    default

iterator keys*(map: CellMap): Symbol =
  for cell in map.entries:
    yield cell.symbol

iterator pairs*(map: CellMap): (Symbol, KiwiScalar) =
  for cell in map.entries:
    yield (cell.symbol, cell.coefficient)

iterator mpairs*(map: var CellMap): (Symbol, var KiwiScalar) =
  for cell in map.entries.mitems:
    yield (cell.symbol, cell.coefficient)

template withValue*(map: var CellMap, symbol: Symbol, coefficient, body: untyped) =
  let index = findIndex(map, symbol)
  if index >= 0:
    var coefficient {.inject.} = addr(map.entries[index].coefficient)
    body
