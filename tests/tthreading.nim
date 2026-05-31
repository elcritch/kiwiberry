import std/[algorithm, assertions, hashes]

import kiwiberry

const
  WorkerCount = 4
  PerWorker = 200
  Total = WorkerCount * PerWorker

type WorkerArg = object
  offset: int

var variableIds: array[Total, uint64]
var constraintHashes: array[Total, Hash]

proc worker(arg: WorkerArg) {.thread.} =
  for i in 0 ..< PerWorker:
    let index = arg.offset + i
    let variable = newVariable("threaded")
    let constraint = variable >= i

    variableIds[index] = uint64(variable.variableId)
    constraintHashes[index] = hash(constraint)

block idsAreUniqueAcrossThreads:
  var threads: array[WorkerCount, Thread[WorkerArg]]

  for i in 0 ..< WorkerCount:
    createThread(threads[i], worker, WorkerArg(offset: i * PerWorker))
  joinThreads(threads)

  var sortedVariableIds = @variableIds
  sortedVariableIds.sort()
  for i in 1 ..< sortedVariableIds.len:
    doAssert sortedVariableIds[i] != sortedVariableIds[i - 1]

  var sortedConstraintHashes = @constraintHashes
  sortedConstraintHashes.sort()
  for i in 1 ..< sortedConstraintHashes.len:
    doAssert sortedConstraintHashes[i] != sortedConstraintHashes[i - 1]
