import std/tables

import ../scalars
import ./symbols

type Row* = object
  cells*: Table[Symbol, KiwiScalar]
  constant*: KiwiScalar

proc initRow*(constant: KiwiScalar = 0): Row =
  Row(cells: initTable[Symbol, KiwiScalar](), constant: constant)

proc add*(row: var Row, value: KiwiScalar): KiwiScalar =
  row.constant += value
  row.constant

proc insert*(row: var Row, symbol: Symbol, coefficient: KiwiScalar = 1) =
  let value = row.cells.getOrDefault(symbol, 0.KiwiScalar) + coefficient
  if value.nearZero:
    row.cells.del(symbol)
  else:
    row.cells[symbol] = value

proc insert*(row: var Row, other: Row, coefficient: KiwiScalar = 1) =
  row.constant += other.constant * coefficient
  for symbol, value in other.cells:
    row.insert(symbol, value * coefficient)

proc remove*(row: var Row, symbol: Symbol) =
  row.cells.del(symbol)

proc reverseSign*(row: var Row) =
  row.constant = -row.constant
  for _, value in row.cells.mpairs:
    value = -value

proc solveFor*(row: var Row, symbol: Symbol) =
  let coeff = -1 / row.cells[symbol]
  row.cells.del(symbol)
  row.constant *= coeff
  for _, value in row.cells.mpairs:
    value *= coeff

proc solveFor*(row: var Row, lhs, rhs: Symbol) =
  row.insert(lhs, -1)
  row.solveFor(rhs)

proc coefficientFor*(row: Row, symbol: Symbol): KiwiScalar =
  row.cells.getOrDefault(symbol, 0.KiwiScalar)

proc substitute*(row: var Row, symbol: Symbol, other: Row) =
  if row.cells.hasKey(symbol):
    let coefficient = row.cells[symbol]
    row.cells.del(symbol)
    row.insert(other, coefficient)
