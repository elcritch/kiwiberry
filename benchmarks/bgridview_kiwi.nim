## 2x6 UI grid layout benchmark against the Kiwi-Nim dependency.
##
## Run with:
##   KIWIBERRY_BENCH_ITERS=20000 nim c -d:release -r benchmarks/bgridview_kiwi.nim

import std/[monotimes, os, strformat, strutils, times]

import kiwi

const
  RowCount = 2
  ColCount = 6
  CellCount = RowCount * ColCount

type
  GridVars = object
    containerLeft, containerTop: Variable
    containerWidth, containerHeight: Variable
    colLeft, colWidth, colRight: array[ColCount, Variable]
    rowTop, rowHeight, rowBottom: array[RowCount, Variable]
    cellLeft, cellTop, cellWidth, cellHeight: array[CellCount, Variable]

  GridBench = object
    solver: Solver
    vars: GridVars

proc benchIterations(defaultValue: int): int =
  let raw = getEnv("KIWIBERRY_BENCH_ITERS")
  if raw.len == 0:
    defaultValue
  else:
    parseInt(raw)

proc newGridVars(): GridVars =
  result.containerLeft = newVariable("containerLeft")
  result.containerTop = newVariable("containerTop")
  result.containerWidth = newVariable("containerWidth")
  result.containerHeight = newVariable("containerHeight")

  for col in 0 ..< ColCount:
    result.colLeft[col] = newVariable(&"col{col}Left")
    result.colWidth[col] = newVariable(&"col{col}Width")
    result.colRight[col] = newVariable(&"col{col}Right")

  for row in 0 ..< RowCount:
    result.rowTop[row] = newVariable(&"row{row}Top")
    result.rowHeight[row] = newVariable(&"row{row}Height")
    result.rowBottom[row] = newVariable(&"row{row}Bottom")

  for cell in 0 ..< CellCount:
    result.cellLeft[cell] = newVariable(&"cell{cell}Left")
    result.cellTop[cell] = newVariable(&"cell{cell}Top")
    result.cellWidth[cell] = newVariable(&"cell{cell}Width")
    result.cellHeight[cell] = newVariable(&"cell{cell}Height")

proc cellIndex(row, col: int): int =
  row * ColCount + col

proc addGridConstraints(bench: var GridBench) =
  let gutter = 8.0
  let padding = 12.0
  let cellInset = 4.0
  let minColWidth = 64.0
  let minRowHeight = 44.0

  bench.solver.addEditVariable(bench.vars.containerWidth, STRONG)
  bench.solver.addEditVariable(bench.vars.containerHeight, STRONG)
  bench.solver.addConstraint(bench.vars.containerLeft == 0)
  bench.solver.addConstraint(bench.vars.containerTop == 0)

  for col in 0 ..< ColCount:
    bench.solver.addConstraint(
      bench.vars.colRight[col] == bench.vars.colLeft[col] + bench.vars.colWidth[col]
    )
    bench.solver.addConstraint(bench.vars.colWidth[col] >= minColWidth)
    bench.solver.addConstraint(
      modifyStrength(bench.vars.colWidth[col] == 110.0 + col.float * 3.0, WEAK)
    )
    if col == 0:
      bench.solver.addConstraint(
        bench.vars.colLeft[col] == bench.vars.containerLeft + padding
      )
    else:
      bench.solver.addConstraint(
        bench.vars.colLeft[col] == bench.vars.colRight[col - 1] + gutter
      )
      bench.solver.addConstraint(
        modifyStrength(bench.vars.colWidth[col] == bench.vars.colWidth[0], MEDIUM)
      )

  bench.solver.addConstraint(
    bench.vars.colRight[ColCount - 1] ==
      bench.vars.containerLeft + bench.vars.containerWidth - padding
  )

  for row in 0 ..< RowCount:
    bench.solver.addConstraint(
      bench.vars.rowBottom[row] == bench.vars.rowTop[row] + bench.vars.rowHeight[row]
    )
    bench.solver.addConstraint(bench.vars.rowHeight[row] >= minRowHeight)
    bench.solver.addConstraint(
      modifyStrength(bench.vars.rowHeight[row] == 96.0 + row.float * 12.0, WEAK)
    )
    if row == 0:
      bench.solver.addConstraint(
        bench.vars.rowTop[row] == bench.vars.containerTop + padding
      )
    else:
      bench.solver.addConstraint(
        bench.vars.rowTop[row] == bench.vars.rowBottom[row - 1] + gutter
      )
      bench.solver.addConstraint(
        modifyStrength(bench.vars.rowHeight[row] == bench.vars.rowHeight[0], MEDIUM)
      )

  bench.solver.addConstraint(
    bench.vars.rowBottom[RowCount - 1] ==
      bench.vars.containerTop + bench.vars.containerHeight - padding
  )

  for row in 0 ..< RowCount:
    for col in 0 ..< ColCount:
      let index = cellIndex(row, col)
      bench.solver.addConstraint(
        bench.vars.cellLeft[index] == bench.vars.colLeft[col] + cellInset
      )
      bench.solver.addConstraint(
        bench.vars.cellTop[index] == bench.vars.rowTop[row] + cellInset
      )
      bench.solver.addConstraint(
        bench.vars.cellWidth[index] == bench.vars.colWidth[col] - 2 * cellInset
      )
      bench.solver.addConstraint(
        bench.vars.cellHeight[index] == bench.vars.rowHeight[row] - 2 * cellInset
      )
      bench.solver.addConstraint(bench.vars.cellWidth[index] >= 24.0)
      bench.solver.addConstraint(bench.vars.cellHeight[index] >= 20.0)

proc initGridBench(): GridBench =
  result.solver = newSolver()
  result.vars = newGridVars()
  result.addGridConstraints()

proc updateLayout(bench: var GridBench, iteration: int) =
  bench.solver.suggestValue(bench.vars.containerWidth, 760.0 + float(iteration mod 37))
  bench.solver.suggestValue(bench.vars.containerHeight, 260.0 + float(iteration mod 23))
  bench.solver.updateVariables()

proc checksum(bench: GridBench): float64 =
  for cell in 0 ..< CellCount:
    result += bench.vars.cellLeft[cell].value.float64
    result += bench.vars.cellTop[cell].value.float64
    result += bench.vars.cellWidth[cell].value.float64
    result += bench.vars.cellHeight[cell].value.float64

proc finishTiming(
    benchName: string, iterations: int, started: MonoTime, sum: float64
): float64 =
  let elapsed = (getMonoTime() - started).inNanoseconds.float / 1_000_000.0
  echo &"{benchName}: {elapsed:.3f} ms total, {elapsed / iterations.float:.6f} ms/iter, checksum={sum:.3f}"
  elapsed

when isMainModule:
  when defined(release):
    let iterations = benchIterations(20_000)
  else:
    let iterations = benchIterations(50)

  echo &"implementation=kiwi-nim grid={RowCount}x{ColCount} iterations={iterations}"

  var started = getMonoTime()
  var sum = 0.0
  for i in 0 ..< iterations:
    var buildBench = initGridBench()
    buildBench.updateLayout(i)
    sum += buildBench.checksum()
  discard finishTiming("build+solve", iterations, started, sum)

  var bench = initGridBench()
  started = getMonoTime()
  sum = 0.0
  for i in 0 ..< iterations * 20:
    bench.updateLayout(i)
    sum += bench.checksum()
  discard finishTiming("edit+update", iterations * 20, started, sum)
