## 2x6 UI grid layout benchmark.
##
## Run with:
##   KIWIBERRY_BENCH_ITERS=20000 nim c -d:release -r benchmarks/bgridview.nim

import std/[monotimes, os, strformat, strutils, times]

import kiwiberry

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
  result.containerLeft = vars"containerLeft"
  result.containerTop = vars"containerTop"
  result.containerWidth = vars"containerWidth"
  result.containerHeight = vars"containerHeight"

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
  let gutter = 8.KiwiScalar
  let padding = 12.KiwiScalar
  let cellInset = 4.KiwiScalar
  let minColWidth = 64.KiwiScalar
  let minRowHeight = 44.KiwiScalar

  bench.solver[bench.vars.containerWidth] = Strong
  bench.solver[bench.vars.containerHeight] = Strong
  bench.solver.constraint(bench.vars.containerLeft == 0)
  bench.solver.constraint(bench.vars.containerTop == 0)

  for col in 0 ..< ColCount:
    bench.solver.constraint(
      bench.vars.colRight[col] == bench.vars.colLeft[col] + bench.vars.colWidth[col]
    )
    bench.solver.constraint(bench.vars.colWidth[col] >= minColWidth)
    bench.solver.constraint((bench.vars.colWidth[col] == 110 + col * 3) | Weak)
    if col == 0:
      bench.solver.constraint(
        bench.vars.colLeft[col] == bench.vars.containerLeft + padding
      )
    else:
      bench.solver.constraint(
        bench.vars.colLeft[col] == bench.vars.colRight[col - 1] + gutter
      )
      bench.solver.constraint(
        (bench.vars.colWidth[col] == bench.vars.colWidth[0]) | Medium
      )

  bench.solver.constraint(
    bench.vars.colRight[ColCount - 1] ==
      bench.vars.containerLeft + bench.vars.containerWidth - padding
  )

  for row in 0 ..< RowCount:
    bench.solver.constraint(
      bench.vars.rowBottom[row] == bench.vars.rowTop[row] + bench.vars.rowHeight[row]
    )
    bench.solver.constraint(bench.vars.rowHeight[row] >= minRowHeight)
    bench.solver.constraint((bench.vars.rowHeight[row] == 96 + row * 12) | Weak)
    if row == 0:
      bench.solver.constraint(
        bench.vars.rowTop[row] == bench.vars.containerTop + padding
      )
    else:
      bench.solver.constraint(
        bench.vars.rowTop[row] == bench.vars.rowBottom[row - 1] + gutter
      )
      bench.solver.constraint(
        (bench.vars.rowHeight[row] == bench.vars.rowHeight[0]) | Medium
      )

  bench.solver.constraint(
    bench.vars.rowBottom[RowCount - 1] ==
      bench.vars.containerTop + bench.vars.containerHeight - padding
  )

  for row in 0 ..< RowCount:
    for col in 0 ..< ColCount:
      let index = cellIndex(row, col)
      bench.solver.constraint(
        bench.vars.cellLeft[index] == bench.vars.colLeft[col] + cellInset
      )
      bench.solver.constraint(
        bench.vars.cellTop[index] == bench.vars.rowTop[row] + cellInset
      )
      bench.solver.constraint(
        bench.vars.cellWidth[index] == bench.vars.colWidth[col] - 2 * cellInset
      )
      bench.solver.constraint(
        bench.vars.cellHeight[index] == bench.vars.rowHeight[row] - 2 * cellInset
      )
      bench.solver.constraint(bench.vars.cellWidth[index] >= 24)
      bench.solver.constraint(bench.vars.cellHeight[index] >= 20)

proc initGridBench(): GridBench =
  result.solver = initSolver()
  result.vars = newGridVars()
  result.addGridConstraints()

proc updateLayout(bench: var GridBench, iteration: int) =
  bench.solver.suggest(bench.vars.containerWidth, 760 + (iteration mod 37))
  bench.solver.suggest(bench.vars.containerHeight, 260 + (iteration mod 23))
  bench.solver.update()

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

  echo &"implementation=kiwiberry-nim grid={RowCount}x{ColCount} iterations={iterations}"

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
