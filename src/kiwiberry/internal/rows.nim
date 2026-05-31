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

proc addCell(row: var Row, symbol: Symbol, coefficient: float64) =
  var removeCell = false
  row.cells.withValue(symbol, cell):
    let value = cell[].float64 + coefficient
    cell[] = KiwiScalar(value)
    removeCell = abs(value) < 1.0e-8
  do:
    if abs(coefficient) >= 1.0e-8:
      row.cells[symbol] = KiwiScalar(coefficient)

  if removeCell:
    row.cells.del(symbol)

proc addProductFor*(row: var Row, symbol: Symbol, value: KiwiScalar): bool =
  row.cells.withValue(symbol, coefficient):
    discard row.add(KiwiScalar(value.float64 * coefficient[].float64))
    result = true

proc insert*(row: var Row, symbol: Symbol, coefficient: KiwiScalar = 1.KiwiScalar) =
  row.addCell(symbol, coefficient.float64)

proc insert*(row: var Row, other: Row, coefficient: KiwiScalar = 1.KiwiScalar) =
  let scale = coefficient.float64
  row.constant = KiwiScalar(row.constant.float64 + other.constant.float64 * scale)
  for symbol, value in other.cells:
    row.addCell(symbol, value.float64 * scale)

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
  var coefficient: KiwiScalar
  if row.cells.pop(symbol, coefficient):
    row.insert(other, coefficient)
