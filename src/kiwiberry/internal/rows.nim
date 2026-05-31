import std/tables

import ../scalars
import ./symbols

type Row* = object
  cells*: Table[Symbol, KiwiScalar]
  constant*: KiwiScalar

proc initRow*(constant: KiwiScalar = 0.KiwiScalar): Row =
  Row(cells: initTable[Symbol, KiwiScalar](), constant: constant)

proc add*(row: var Row, value: KiwiScalar): KiwiScalar =
  row.constant = KiwiScalar(row.constant.float64 + value.float64)
  row.constant

proc insert*(row: var Row, symbol: Symbol, coefficient: KiwiScalar = 1.KiwiScalar) =
  let cell = addr row.cells.mgetOrPut(symbol, 0.KiwiScalar)
  cell[] = KiwiScalar(cell[].float64 + coefficient.float64)
  if abs(cell[].float64) < 1.0e-8:
    row.cells.del(symbol)

proc insert*(row: var Row, other: Row, coefficient: KiwiScalar = 1.KiwiScalar) =
  row.constant =
    KiwiScalar(row.constant.float64 + other.constant.float64 * coefficient.float64)
  for symbol, value in other.cells:
    row.insert(symbol, KiwiScalar(value.float64 * coefficient.float64))

proc remove*(row: var Row, symbol: Symbol) =
  row.cells.del(symbol)

proc reverseSign*(row: var Row) =
  row.constant = KiwiScalar(-row.constant.float64)
  for _, value in row.cells.mpairs:
    value = KiwiScalar(-value.float64)

proc solveFor*(row: var Row, symbol: Symbol) =
  let coeff = KiwiScalar(-1.0 / row.cells[symbol].float64)
  row.cells.del(symbol)
  row.constant = KiwiScalar(row.constant.float64 * coeff.float64)
  for _, value in row.cells.mpairs:
    value = KiwiScalar(value.float64 * coeff.float64)

proc solveFor*(row: var Row, lhs, rhs: Symbol) =
  row.insert(lhs, KiwiScalar(-1.0))
  row.solveFor(rhs)

proc coefficientFor*(row: Row, symbol: Symbol): KiwiScalar =
  row.cells.getOrDefault(symbol, 0.KiwiScalar)

proc substitute*(row: var Row, symbol: Symbol, other: Row) =
  if row.cells.hasKey(symbol):
    let coefficient = row.cells[symbol]
    row.cells.del(symbol)
    row.insert(other, coefficient)
