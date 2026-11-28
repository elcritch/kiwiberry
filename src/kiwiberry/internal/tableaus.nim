## Basic rows of the simplex tableau, with an index from each symbol to the
## rows that contain it.
##
## Substitution and leaving-row searches visit only the rows containing a
## symbol, instead of every row. Each index entry is a node in a doubly linked
## list per symbol, and the row cell stores its node, so entries are added and
## removed in constant time. Rows live in stable slots, so a pivot changes the
## index for two cells rather than for every cell of the pivot row. Small
## tableaus scan their rows instead; the index is built once the row count
## exceeds `IndexedRowCount`. Callers change row cells only through this module
## so the index stays exact.

import std/[algorithm, tables]

import ../scalars
import ./[assocmaps, rows, symbols]

const IndexedRowCount* {.intdefine: "kiwiberryIndexedRows".} = 128
  ## Row count above which a tableau indexes symbols instead of scanning rows.

type
  RowSlot = object
    basic: Symbol ## Invalid while the slot is free.
    row: Row

  Occurrence = object
    slot: int
    previous, next: int ## One more than the neighbouring node; 0 at the ends.

  Tableau* = object
    slots: seq[RowSlot]
    freeSlots: seq[int]
    basics: AssocMap[Symbol, int] ## Basic symbol to slot.
    indexed: bool
    heads: Table[Symbol, int] ## One more than each symbol's first node.
    nodes: seq[Occurrence] ## Occurrence lists, sharing one pool.
    freeNode: int ## One more than the first free node; 0 when none.
    infeasible: seq[Symbol] ## Restricted rows with a negative constant, sorted.
    scratch: seq[int] ## Reused by `detachSlots`.

proc initTableau*(): Tableau =
  ## Storage is allocated on first use, so empty solvers stay cheap.
  Tableau()

proc cmp(a, b: Symbol): int =
  cmp(uint64(a.id), uint64(b.id))

proc lowerIndex(symbols: seq[Symbol], symbol: Symbol): int {.inline.} =
  var high = symbols.len
  while result < high:
    let mid = (result + high) shr 1
    if symbols[mid] < symbol:
      result = mid + 1
    else:
      high = mid

proc isUsed(slot: RowSlot): bool {.inline.} =
  not slot.basic.isInvalid

proc slotOf(tableau: Tableau, basic: Symbol): int {.inline.} =
  ## The slot of `basic`'s row, or -1 when it is not basic.
  tableau.basics.getOrDefault(basic, -1)

proc linkOccurrence(tableau: var Tableau, symbol: Symbol, slot: int): int =
  ## Adds `slot` to `symbol`'s list and returns its node.
  if tableau.freeNode > 0:
    result = tableau.freeNode
    tableau.freeNode = tableau.nodes[result - 1].next
  else:
    tableau.nodes.add Occurrence()
    result = tableau.nodes.len
  var next = 0
  tableau.heads.withValue(symbol, head):
    next = head[]
    head[] = result
  do:
    tableau.heads[symbol] = result
  tableau.nodes[result - 1] = Occurrence(slot: slot, next: next)
  if next > 0:
    tableau.nodes[next - 1].previous = result

proc releaseNode(tableau: var Tableau, node: int) =
  tableau.nodes[node - 1].next = tableau.freeNode
  tableau.freeNode = node

proc unlinkOccurrence(tableau: var Tableau, symbol: Symbol, node: int) =
  if node <= 0:
    return
  let
    previous = tableau.nodes[node - 1].previous
    next = tableau.nodes[node - 1].next
  if next > 0:
    tableau.nodes[next - 1].previous = previous
  if previous > 0:
    tableau.nodes[previous - 1].next = next
  elif next > 0:
    tableau.heads[symbol] = next
  else:
    tableau.heads.del(symbol)
  tableau.releaseNode(node)

proc linkCells(tableau: var Tableau, slot: int) =
  for symbol, link in tableau.slots[slot].row.cells.mlinks:
    link = tableau.linkOccurrence(symbol, slot)

proc detachSlots(tableau: var Tableau, symbol: Symbol, result: var seq[int]) =
  ## Collects the slots of the rows containing `symbol`. Once indexed, also
  ## empties its list, since callers remove `symbol` from those rows.
  result.setLen(0)
  if not tableau.indexed:
    for index in 0 ..< tableau.slots.len:
      if tableau.slots[index].isUsed and tableau.slots[index].row.cells.hasKey(symbol):
        result.add index
    return
  var node = 0
  discard tableau.heads.pop(symbol, node)
  while node > 0:
    result.add tableau.nodes[node - 1].slot
    let next = tableau.nodes[node - 1].next
    tableau.releaseNode(node)
    node = next

proc noteConstant(tableau: var Tableau, basic: Symbol, constant: KiwiScalar) =
  let negative = not basic.isExternal and constant < 0'ks
  if not negative and tableau.infeasible.len == 0:
    return
  let index = tableau.infeasible.lowerIndex(basic)
  let present = index < tableau.infeasible.len and tableau.infeasible[index] == basic
  if negative and not present:
    tableau.infeasible.insert(basic, index)
  elif present and not negative:
    tableau.infeasible.delete(index)

proc setBasic(tableau: var Tableau, basic: Symbol, slot: int) =
  tableau.slots[slot].basic = basic
  tableau.basics[basic] = slot
  if not tableau.indexed and tableau.basics.len > IndexedRowCount:
    tableau.indexed = true
    for index in 0 ..< tableau.slots.len:
      if tableau.slots[index].isUsed:
        tableau.linkCells(index)

proc clearBasic(tableau: var Tableau, basic: Symbol): int =
  ## Returns the slot of `basic`'s row, or -1 when it is not basic.
  if not tableau.basics.pop(basic, result):
    return -1
  tableau.slots[result].basic = initSymbol()
  tableau.noteConstant(basic, 0'ks)

proc len*(tableau: Tableau): int =
  tableau.basics.len

proc hasKey*(tableau: Tableau, basic: Symbol): bool =
  tableau.slotOf(basic) >= 0

proc `[]`*(tableau: Tableau, basic: Symbol): lent Row =
  let slot = tableau.slotOf(basic)
  if slot < 0:
    raise newException(KeyError, "symbol is not basic")
  tableau.slots[slot].row

proc `[]=`*(tableau: var Tableau, basic: Symbol, row: sink Row) =
  ## Adds the row for a symbol that is not yet basic.
  assert not tableau.hasKey(basic)
  let slot =
    if tableau.freeSlots.len > 0:
      tableau.freeSlots.pop()
    else:
      tableau.slots.add RowSlot()
      tableau.slots.high
  tableau.noteConstant(basic, row.constant)
  tableau.slots[slot].row = row
  if tableau.indexed:
    tableau.linkCells(slot)
  tableau.setBasic(basic, slot)

proc pop*(tableau: var Tableau, basic: Symbol, row: var Row): bool =
  let slot = tableau.clearBasic(basic)
  if slot < 0:
    return false
  row = move tableau.slots[slot].row
  if tableau.indexed:
    for symbol, link in row.cells.links:
      tableau.unlinkOccurrence(symbol, link)
  tableau.freeSlots.add slot
  true

proc constantFor*(tableau: Tableau, basic: Symbol, constant: var KiwiScalar): bool =
  ## Reads the constant of `basic`'s row, if it is basic.
  let slot = tableau.slotOf(basic)
  if slot >= 0:
    constant = tableau.slots[slot].row.constant
    result = true

proc addConstant*(tableau: var Tableau, basic: Symbol, value: KiwiScalar): KiwiScalar =
  ## Adds `value` to the constant of `basic`'s row and returns the new constant.
  result = tableau.slots[tableau.slotOf(basic)].row.add(value)
  tableau.noteConstant(basic, result)

iterator slotsContaining(tableau: Tableau, symbol: Symbol): int =
  ## Callers must not add or remove occurrences of `symbol` while iterating.
  if tableau.indexed:
    var node = tableau.heads.getOrDefault(symbol)
    while node > 0:
      let slot = tableau.nodes[node - 1].slot
      node = tableau.nodes[node - 1].next
      yield slot
  else:
    for index in 0 ..< tableau.slots.len:
      if tableau.slots[index].isUsed and tableau.slots[index].row.cells.hasKey(symbol):
        yield index

iterator rowsContaining*(tableau: var Tableau, symbol: Symbol): (Symbol, var Row) =
  ## Rows with a cell for `symbol`, in no particular order. Callers must not
  ## change the yielded row; use the mutation procs so the index stays exact.
  for slot in tableau.slotsContaining(symbol):
    yield (tableau.slots[slot].basic, tableau.slots[slot].row)

iterator sortedKeys*(tableau: Tableau): Symbol =
  for basic in tableau.basics.keys:
    yield basic

proc substitute*(
    tableau: var Tableau, symbol: Symbol, other: Row, infeasible: var seq[Symbol]
) =
  ## Replaces `symbol` with `other` in every row, then queues every restricted
  ## row with a negative constant in symbol order, as a full row scan would.
  var slots = move tableau.scratch
  tableau.detachSlots(symbol, slots)
  for slot in slots:
    var coefficient: KiwiScalar
    discard tableau.slots[slot].row.cells.pop(symbol, coefficient)
    tableau.slots[slot].row.constant += other.constant * coefficient
    for cell, value in other.cells:
      var link: int
      case tableau.slots[slot].row.cells.accumulate(cell, value * coefficient, link)
      of ccAdded:
        if tableau.indexed:
          tableau.slots[slot].row.cells.setLink(
            cell, tableau.linkOccurrence(cell, slot)
          )
      of ccRemoved:
        if tableau.indexed:
          tableau.unlinkOccurrence(cell, link)
      of ccUpdated:
        discard
    tableau.noteConstant(tableau.slots[slot].basic, tableau.slots[slot].row.constant)
  tableau.scratch = move slots
  infeasible.add tableau.infeasible

proc pivot*(
    tableau: var Tableau, leaving, entering: Symbol, infeasible: var seq[Symbol]
) =
  ## Solves `leaving`'s row for `entering`, substitutes it into every other
  ## row, and makes it `entering`'s row. Like popping the row, substituting,
  ## and adding it back, the pivot row is not queued as infeasible.
  let slot = tableau.clearBasic(leaving)
  assert slot >= 0
  let enteringLink = tableau.slots[slot].row.cells.linkFor(entering)
  tableau.slots[slot].row.solveFor(leaving, entering)
  if tableau.indexed:
    tableau.unlinkOccurrence(entering, enteringLink)
    tableau.slots[slot].row.cells.setLink(
      leaving, tableau.linkOccurrence(leaving, slot)
    )
  # Substitution touches only rows containing `entering`, which no longer
  # includes this slot, so the row can be moved out while it runs.
  var pivotRow = move tableau.slots[slot].row
  tableau.substitute(entering, pivotRow, infeasible)
  tableau.noteConstant(entering, pivotRow.constant)
  tableau.slots[slot].row = move pivotRow
  tableau.setBasic(entering, slot)

proc addProduct*(
    tableau: var Tableau, symbol: Symbol, value: KiwiScalar, infeasible: var seq[Symbol]
) =
  ## Adds `value` times each row's `symbol` coefficient to that row's constant
  ## and queues restricted rows that become negative, in symbol order.
  let start = infeasible.len
  for slot in tableau.slotsContaining(symbol):
    discard tableau.slots[slot].row.addProductFor(symbol, value)
    let
      basic = tableau.slots[slot].basic
      constant = tableau.slots[slot].row.constant
    tableau.noteConstant(basic, constant)
    if not basic.isExternal and constant < 0'ks:
      infeasible.add basic
  infeasible.toOpenArray(start, infeasible.high).sort(cmp)

proc removeSymbol*(tableau: var Tableau, symbol: Symbol) =
  ## Removes `symbol`'s cell from every row.
  var slots = move tableau.scratch
  tableau.detachSlots(symbol, slots)
  for slot in slots:
    tableau.slots[slot].row.remove(symbol)
  tableau.scratch = move slots
