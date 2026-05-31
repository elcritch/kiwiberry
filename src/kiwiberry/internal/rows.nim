import std/tables

import ../scalars
import ./scalarops
import ./symbols

type Row* = object
  cells*: Table[Symbol, KiwiScalar]
  constant*: KiwiScalar

proc initRow*(constant: KiwiScalar = rawZero): Row =
  Row(cells: initTable[Symbol, KiwiScalar](), constant: constant)

proc add*(row: var Row, value: KiwiScalar): KiwiScalar =
  row.constant = row.constant.uncheckedAdd(value)
  row.constant

proc insert*(row: var Row, symbol: Symbol, coefficient: KiwiScalar = rawOne) =
  let cell = addr row.cells.mgetOrPut(symbol, rawZero)
  cell[] = cell[].uncheckedAdd(coefficient)
  if cell[].uncheckedNearZero:
    row.cells.del(symbol)

proc insert*(row: var Row, other: Row, coefficient: KiwiScalar = rawOne) =
  row.constant = row.constant.uncheckedAdd(other.constant.uncheckedMul(coefficient))
  for symbol, value in other.cells:
    row.insert(symbol, value.uncheckedMul(coefficient))

proc remove*(row: var Row, symbol: Symbol) =
  row.cells.del(symbol)

proc reverseSign*(row: var Row) =
  row.constant = row.constant.uncheckedNeg
  for _, value in row.cells.mpairs:
    value = value.uncheckedNeg

proc solveFor*(row: var Row, symbol: Symbol) =
  let coeff = rawMinusOne.uncheckedDiv(row.cells[symbol])
  row.cells.del(symbol)
  row.constant = row.constant.uncheckedMul(coeff)
  for _, value in row.cells.mpairs:
    value = value.uncheckedMul(coeff)

proc solveFor*(row: var Row, lhs, rhs: Symbol) =
  row.insert(lhs, rawMinusOne)
  row.solveFor(rhs)

proc coefficientFor*(row: Row, symbol: Symbol): KiwiScalar =
  row.cells.getOrDefault(symbol, rawZero)

proc substitute*(row: var Row, symbol: Symbol, other: Row) =
  if row.cells.hasKey(symbol):
    let coefficient = row.cells[symbol]
    row.cells.del(symbol)
    row.insert(other, coefficient)
