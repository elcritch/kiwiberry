import std/[algorithm, assertions, random]

import kiwiberry
import kiwiberry/internal/[rows, symbols, tableaus]

proc symbolAt(id: int): Symbol =
  let kind = [skExternal, skSlack, skError, skDummy][id mod 4]
  initSymbol(kind, SymbolId(uint64(id)))

proc containing(tableau: var Tableau, symbol: Symbol): seq[Symbol] =
  for basic, _ in tableau.rowsContaining(symbol):
    result.add basic
  result.sort(
    proc(a, b: Symbol): int =
      cmp(uint64(a.id), uint64(b.id))
  )

proc checkIndex(tableau: var Tableau, universe: openArray[Symbol]) =
  ## Every column lists exactly the rows whose cells contain its symbol.
  var basics: seq[Symbol]
  for basic in tableau.sortedKeys:
    basics.add basic
  for symbol in universe:
    var expected: seq[Symbol]
    for basic in basics:
      if tableau[basic].cells.hasKey(symbol):
        expected.add basic
    doAssert tableau.containing(symbol) == expected, $symbol

proc randomRow(rng: var Rand, tableau: Tableau, universe: openArray[Symbol]): Row =
  ## A row over non-basic symbols, as the solver builds them.
  result = initRow(KiwiScalar(rng.rand(-5 .. 5)))
  for _ in 0 .. rng.rand(1 .. 4):
    let symbol = universe[rng.rand(universe.high)]
    if not tableau.hasKey(symbol):
      result.insert(symbol, KiwiScalar(rng.rand(1 .. 3)))

proc exerciseIndex(symbolCount, steps, checkEvery: int): int =
  ## Returns the largest row count reached, so callers can check both the
  ## scanning and the indexed representations.
  var rng = initRand(symbolCount)
  var universe: seq[Symbol]
  for id in 1 .. symbolCount:
    universe.add symbolAt(id)
  var tableau = initTableau()
  var infeasible: seq[Symbol]
  for step in 0 ..< steps:
    let symbol = universe[rng.rand(universe.high)]
    case rng.rand(4)
    of 0, 1:
      # Make `symbol` basic: substitute it out of every row, then add its row.
      if not tableau.hasKey(symbol):
        var row = rng.randomRow(tableau, universe)
        row.remove(symbol)
        tableau.substitute(symbol, row, infeasible)
        tableau[symbol] = row
    of 2:
      var row: Row
      discard tableau.pop(symbol, row)
    of 3:
      if tableau.hasKey(symbol):
        var entering = initSymbol()
        for cell in tableau[symbol].cells.keys:
          entering = cell
        if not entering.isInvalid:
          tableau.pivot(symbol, entering, infeasible)
    else:
      if tableau.hasKey(symbol):
        discard tableau.addConstant(symbol, KiwiScalar(rng.rand(-3 .. 3)))
    if step mod checkEvery == 0 or step == steps - 1:
      tableau.checkIndex(universe)
    result = max(result, tableau.len)

block indexFollowsSubstitutionsAndPivots:
  doAssert exerciseIndex(16, 400, checkEvery = 1) <= IndexedRowCount
  doAssert exerciseIndex(400, 2500, checkEvery = 50) > IndexedRowCount

block substitutionQueuesNegativeRowsInSymbolOrder:
  let
    a = initSymbol(skSlack, SymbolId(1))
    b = initSymbol(skSlack, SymbolId(2))
    c = initSymbol(skExternal, SymbolId(3))
    d = initSymbol(skError, SymbolId(4))
    x = initSymbol(skError, SymbolId(5))
  var tableau = initTableau()
  var first = initRow(1'ks)
  first.insert(x, 1'ks)
  var unrelated = initRow(-1'ks)
  unrelated.insert(a, 1'ks)
  var external = initRow(1'ks)
  external.insert(x, 1'ks)
  tableau[d] = first
  tableau[b] = unrelated
  tableau[c] = external

  var replacement = initRow(-4'ks)
  var infeasible: seq[Symbol]
  tableau.substitute(x, replacement, infeasible)

  # `b` was already negative and is queued again, as a full scan would.
  # The external row `c` is never queued.
  doAssert infeasible == @[b, d]
  doAssert tableau[d].constant == -3'ks
  doAssert tableau[c].constant == -3'ks
