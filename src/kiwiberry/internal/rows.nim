import ../scalars
import ./[cellmaps, symbols]

export cellmaps

type Row* = object
  cells*: CellMap
  constant*: KiwiScalar

proc initRow*(constant: KiwiScalar = 0'ks): Row =
  Row(cells: initCellMap(), constant: constant)

proc add*(row: var Row, value: KiwiScalar): KiwiScalar =
  row.constant += value
  row.constant

proc addProductFor*(row: var Row, symbol: Symbol, value: KiwiScalar): bool =
  row.cells.withValue(symbol, coefficient):
    discard row.add(value * coefficient[])
    result = true

proc insert*(row: var Row, symbol: Symbol, coefficient: KiwiScalar = 1'ks) =
  row.cells.add(symbol, coefficient)

proc insert*(row: var Row, other: Row, coefficient: KiwiScalar = 1'ks) =
  row.constant += other.constant * coefficient
  for symbol, value in other.cells:
    row.cells.add(symbol, value * coefficient)

proc remove*(row: var Row, symbol: Symbol) =
  row.cells.del(symbol)

proc reverseSign*(row: var Row) =
  row.constant = -row.constant
  for _, value in row.cells.mpairs:
    value = -value

proc solveFor*(row: var Row, symbol: Symbol) =
  let coeff = -1'ks / row.cells[symbol]
  row.cells.del(symbol)
  row.constant *= coeff
  for _, value in row.cells.mpairs:
    value *= coeff

proc solveFor*(row: var Row, lhs, rhs: Symbol) =
  row.insert(lhs, -1'ks)
  row.solveFor(rhs)

proc coefficientFor*(row: Row, symbol: Symbol): KiwiScalar =
  row.cells.getOrDefault(symbol, 0'ks)

proc substitute*(row: var Row, symbol: Symbol, other: Row) =
  var coefficient: KiwiScalar
  if row.cells.pop(symbol, coefficient):
    row.insert(other, coefficient)
