## Scaling benchmark for one connected tableau.
##
## Each view has four weak stays on its current geometry and two non-negative
## sizes, like a UI layout pass. In `stack`, each view's top follows the
## previous view's bottom, so the whole graph is connected. In `form`, every
## view follows a resizable container through its origin and size. In
## `separate`, each view has its own small tableau with intrinsic-size bounds.
##
## Run with:
##   nim c -d:release -r benchmarks/bscaling.nim

import std/[monotimes, os, strformat, strutils, times]

import kiwiberry

type ViewVars = object
  left, top, width, height: Variable

proc newViewVars(index: int): ViewVars =
  ViewVars(
    left: newVariable(&"v{index}.left"),
    top: newVariable(&"v{index}.top"),
    width: newVariable(&"v{index}.width"),
    height: newVariable(&"v{index}.height"),
  )

proc addStays(solver: var Solver, view: ViewVars, index: int) =
  solver.addConstraint(ge(view.width, 0'ks))
  solver.addConstraint(ge(view.height, 0'ks))
  solver.addConstraint((view.left == 10'ks) | Weak)
  solver.addConstraint((view.top == toKiwiScalar(index * 24)) | Weak)
  solver.addConstraint((view.width == 100'ks) | Weak)
  solver.addConstraint((view.height == 20'ks) | Weak)

proc solveStack(count: int): float =
  var solver = initSolver()
  let container = newViewVars(-1)
  solver.addConstraint(container.left == 0'ks)
  solver.addConstraint(container.top == 0'ks)
  solver.addConstraint(container.width == 500'ks)
  var previous = container
  for index in 0 ..< count:
    let view = newViewVars(index)
    solver.addConstraint(view.left == container.left + 10'ks)
    solver.addConstraint(view.width == container.width - 20'ks)
    if index == 0:
      solver.addConstraint(view.top == container.top + 4'ks)
    else:
      solver.addConstraint(view.top == previous.top + previous.height + 4'ks)
    solver.addConstraint(view.height >= 18'ks)
    solver.addStays(view, index)
    previous = view
  solver.updateVariables()
  previous.top.value.float

proc solveForm(count: int): float =
  var solver = initSolver()
  let container = newViewVars(-1)
  solver.addConstraint(container.left == 0'ks)
  solver.addConstraint(container.top == 0'ks)
  solver.addEditVariable(container.width, Strong)
  solver.addEditVariable(container.height, Strong)
  solver.suggestValue(container.width, 500'ks)
  solver.suggestValue(container.height, toKiwiScalar(count * 24))
  var last: ViewVars
  for index in 0 ..< count:
    let view = newViewVars(index)
    solver.addConstraint(view.left == container.left + 10'ks)
    solver.addConstraint(view.width == container.width * 0.5'ks - 20'ks)
    solver.addConstraint(view.top == container.top + toKiwiScalar(index * 24))
    solver.addConstraint(view.height == 20'ks)
    solver.addStays(view, index)
    last = view
  solver.suggestValue(container.width, 640'ks)
  solver.updateVariables()
  last.width.value.float

proc solveSeparately(count: int): float =
  ## Many small tableaus, one per view, as when independent groups are solved
  ## separately.
  for index in 0 ..< count:
    var solver = initSolver()
    let view = newViewVars(index)
    solver.addConstraint((view.width >= 80'ks) | Strong)
    solver.addConstraint((view.width <= 80'ks) | Medium)
    solver.addConstraint((view.height >= 20'ks) | Strong)
    solver.addConstraint((view.height <= 20'ks) | Medium)
    solver.addStays(view, index)
    solver.updateVariables()
    result += view.width.value.float

proc median(samples: var seq[float]): float =
  for i in 1 ..< samples.len:
    var j = i
    while j > 0 and samples[j - 1] > samples[j]:
      swap(samples[j - 1], samples[j])
      dec j
  samples[samples.len div 2]

proc measure(name: string, count: int, run: proc(count: int): float) =
  let rounds =
    if getEnv("KIWIBERRY_BENCH_ROUNDS").len > 0:
      parseInt(getEnv("KIWIBERRY_BENCH_ROUNDS"))
    else:
      5
  var samples: seq[float]
  var checksum = 0.0
  for _ in 0 ..< rounds:
    let start = getMonoTime()
    checksum += run(count)
    samples.add float((getMonoTime() - start).inMicroseconds) / 1000.0
  echo &"{name},{count},{samples.median():.3f},{checksum:.1f}"

when isMainModule:
  echo "case,views,median_ms,checksum"
  for count in [100, 300, 1000]:
    measure("stack", count, solveStack)
    measure("form", count, solveForm)
    measure("separate", count, solveSeparately)
