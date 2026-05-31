import std/assertions
import std/tables

import kiwiberry
import kiwiberry/internal/[rows, symbols]

block rowInsertAndRemove:
  let first = initSymbol(skSlack, SymbolId(1))
  let second = initSymbol(skError, SymbolId(2))
  var row = initRow(10)

  row.insert(first, 2)
  row.insert(second, 3)
  row.insert(first, -2)

  doAssert row.coefficientFor(first) == 0.KiwiScalar
  doAssert row.coefficientFor(second) == 3.KiwiScalar
  doAssert row.cells.len == 1

block rowSolveFor:
  let first = initSymbol(skSlack, SymbolId(1))
  let second = initSymbol(skError, SymbolId(2))
  var row = initRow(10)

  row.insert(first, 2)
  row.insert(second, 4)
  row.solveFor(first)

  doAssert row.constant == -5.KiwiScalar
  doAssert row.coefficientFor(second) == -2.KiwiScalar

block rowSubstitute:
  let first = initSymbol(skSlack, SymbolId(1))
  let second = initSymbol(skError, SymbolId(2))
  var row = initRow(2)
  var other = initRow(3)

  row.insert(first, 4)
  other.insert(second, 5)
  row.substitute(first, other)

  doAssert row.constant == 14.KiwiScalar
  doAssert row.coefficientFor(first) == 0.KiwiScalar
  doAssert row.coefficientFor(second) == 20.KiwiScalar
