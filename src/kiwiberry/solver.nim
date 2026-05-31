import std/[algorithm, sequtils, tables]

import ./[constraints, errors, expressions, scalars, strengths, variables]
import ./internal/[rows, symbols]

type
  Tag = object
    marker: Symbol
    other: Symbol

  EditInfo = object
    tag: Tag
    constraint: Constraint
    constant: KiwiScalar

  Solver* = object
    constraints: OrderedTable[Constraint, Tag]
    rows: OrderedTable[Symbol, Row]
    vars: OrderedTable[VariableId, Symbol]
    variables: OrderedTable[VariableId, Variable]
    edits: OrderedTable[VariableId, EditInfo]
    infeasibleRows: seq[Symbol]
    objective: Row
    artificial: Row
    hasArtificial: bool
    idTick: uint64

proc initSolver*(): Solver =
  Solver(
    constraints: initOrderedTable[Constraint, Tag](),
    rows: initOrderedTable[Symbol, Row](),
    vars: initOrderedTable[VariableId, Symbol](),
    variables: initOrderedTable[VariableId, Variable](),
    edits: initOrderedTable[VariableId, EditInfo](),
    objective: initRow(),
    artificial: initRow(),
    idTick: 1,
  )

proc newSymbol(solver: var Solver, kind: SymbolKind): Symbol =
  result = initSymbol(kind, SymbolId(solver.idTick))
  inc solver.idTick

proc sortedKeys(row: Row): seq[Symbol] =
  result = row.cells.keys.toSeq
  result.sort()

proc sortedRowKeys(solver: Solver): seq[Symbol] =
  result = solver.rows.keys.toSeq
  result.sort()

proc getVarSymbol(solver: var Solver, variable: Variable): Symbol =
  let id = variable.variableId
  if solver.vars.hasKey(id):
    return solver.vars[id]

  result = solver.newSymbol(skExternal)
  solver.vars[id] = result
  solver.variables[id] = variable

proc allDummies(row: Row): bool =
  for symbol in row.sortedKeys:
    if not symbol.isDummy:
      return false
  true

proc anyPivotableSymbol(row: Row): Symbol =
  for symbol in row.sortedKeys:
    if symbol.isPivotable:
      return symbol
  initSymbol()

proc substitute(solver: var Solver, symbol: Symbol, row: Row) =
  for key in solver.sortedRowKeys:
    solver.rows[key].substitute(symbol, row)
    if not key.isExternal and solver.rows[key].constant < 0:
      solver.infeasibleRows.add key

  solver.objective.substitute(symbol, row)
  if solver.hasArtificial:
    solver.artificial.substitute(symbol, row)

proc createRow(solver: var Solver, constraint: Constraint, tag: var Tag): Row =
  result = initRow(constraint.expression.constant)

  for term in constraint.expression:
    if not term.coefficient.nearZero:
      let symbol = solver.getVarSymbol(term.variable)
      if solver.rows.hasKey(symbol):
        result.insert(solver.rows[symbol], term.coefficient)
      else:
        result.insert(symbol, term.coefficient)

  case constraint.relation
  of relLe, relGe:
    let coeff = if constraint.relation == relLe: 1.KiwiScalar else: -1.KiwiScalar
    let slack = solver.newSymbol(skSlack)
    tag.marker = slack
    result.insert(slack, coeff)
    if constraint.strength < Required:
      let error = solver.newSymbol(skError)
      tag.other = error
      result.insert(error, -coeff)
      solver.objective.insert(error, constraint.strength.toKiwiScalar)
  of relEq:
    if constraint.strength < Required:
      let errPlus = solver.newSymbol(skError)
      let errMinus = solver.newSymbol(skError)
      tag.marker = errPlus
      tag.other = errMinus
      result.insert(errPlus, -1)
      result.insert(errMinus, 1)
      solver.objective.insert(errPlus, constraint.strength.toKiwiScalar)
      solver.objective.insert(errMinus, constraint.strength.toKiwiScalar)
    else:
      let dummy = solver.newSymbol(skDummy)
      tag.marker = dummy
      result.insert(dummy)

  if result.constant < 0:
    result.reverseSign()

proc chooseSubject(row: Row, tag: Tag): Symbol =
  for symbol in row.sortedKeys:
    if symbol.isExternal:
      return symbol

  if tag.marker.isPivotable and row.coefficientFor(tag.marker) < 0:
    return tag.marker

  if tag.other.isPivotable and row.coefficientFor(tag.other) < 0:
    return tag.other

  initSymbol()

proc getEnteringSymbol(objective: Row): Symbol =
  for symbol in objective.sortedKeys:
    let coefficient = objective.cells[symbol]
    if not symbol.isDummy and coefficient < 0:
      return symbol
  initSymbol()

proc getDualEnteringSymbol(solver: Solver, row: Row): Symbol =
  var ratio = float64.high.KiwiScalar
  for symbol in row.sortedKeys:
    let coefficient = row.cells[symbol]
    if coefficient > 0 and not symbol.isDummy:
      let r = solver.objective.coefficientFor(symbol) / coefficient
      if r < ratio:
        ratio = r
        result = symbol

proc getLeavingRow(solver: Solver, entering: Symbol): Symbol =
  var ratio = float64.high.KiwiScalar
  result = initSymbol()
  for symbol in solver.sortedRowKeys:
    let row = solver.rows[symbol]
    if not symbol.isExternal:
      let temp = row.coefficientFor(entering)
      if temp < 0:
        let tempRatio = -row.constant / temp
        if tempRatio < ratio:
          ratio = tempRatio
          result = symbol

proc getMarkerLeavingRow(solver: Solver, marker: Symbol): Symbol =
  let dmax = float64.high.KiwiScalar
  var r1 = dmax
  var r2 = dmax
  var first = initSymbol()
  var second = initSymbol()
  var third = initSymbol()

  for symbol in solver.sortedRowKeys:
    let row = solver.rows[symbol]
    let c = row.coefficientFor(marker)
    if c != 0:
      if symbol.isExternal:
        third = symbol
      elif c < 0:
        let r = -row.constant / c
        if r < r1:
          r1 = r
          first = symbol
      else:
        let r = row.constant / c
        if r < r2:
          r2 = r
          second = symbol

  if not first.isInvalid:
    first
  elif not second.isInvalid:
    second
  else:
    third

proc optimize(solver: var Solver, objective: Row) =
  while true:
    let entering = getEnteringSymbol(objective)
    if entering.isInvalid:
      return

    let leaving = solver.getLeavingRow(entering)
    if leaving.isInvalid:
      raiseInternalSolverError("The objective is unbounded.")

    var row = solver.rows[leaving]
    solver.rows.del(leaving)
    row.solveFor(leaving, entering)
    solver.substitute(entering, row)
    solver.rows[entering] = row

proc dualOptimize(solver: var Solver) =
  while solver.infeasibleRows.len > 0:
    let leaving = solver.infeasibleRows.pop()
    if solver.rows.hasKey(leaving) and not solver.rows[leaving].constant.nearZero and
        solver.rows[leaving].constant < 0:
      let entering = solver.getDualEnteringSymbol(solver.rows[leaving])
      if entering.isInvalid:
        raiseInternalSolverError("Dual optimize failed.")

      var row = solver.rows[leaving]
      solver.rows.del(leaving)
      row.solveFor(leaving, entering)
      solver.substitute(entering, row)
      solver.rows[entering] = row

proc addWithArtificialVariable(solver: var Solver, row: Row): bool =
  let art = solver.newSymbol(skSlack)
  solver.rows[art] = row
  solver.artificial = row
  solver.hasArtificial = true

  solver.optimize(solver.artificial)
  result = solver.artificial.constant.nearZero
  solver.hasArtificial = false
  solver.artificial = initRow()

  if solver.rows.hasKey(art):
    var row = solver.rows[art]
    solver.rows.del(art)
    if row.cells.len == 0:
      return result

    let entering = anyPivotableSymbol(row)
    if entering.isInvalid:
      return false

    row.solveFor(art, entering)
    solver.substitute(entering, row)
    solver.rows[entering] = row

  for symbol in solver.sortedRowKeys:
    solver.rows[symbol].remove(art)
  solver.objective.remove(art)

proc removeMarkerEffects(solver: var Solver, marker: Symbol, strength: Strength) =
  if solver.rows.hasKey(marker):
    solver.objective.insert(solver.rows[marker], -strength.toKiwiScalar)
  else:
    solver.objective.insert(marker, -strength.toKiwiScalar)

proc removeConstraintEffects(solver: var Solver, constraint: Constraint, tag: Tag) =
  if tag.marker.kind == skError:
    solver.removeMarkerEffects(tag.marker, constraint.strength)
  if tag.other.kind == skError:
    solver.removeMarkerEffects(tag.other, constraint.strength)

proc addConstraint*(solver: var Solver, constraint: Constraint) =
  if solver.constraints.hasKey(constraint):
    raiseDuplicateConstraint(constraint)

  var tag: Tag
  var row = solver.createRow(constraint, tag)
  var subject = chooseSubject(row, tag)

  if subject.isInvalid and row.allDummies:
    if not row.constant.nearZero:
      raiseUnsatisfiableConstraint(constraint)
    subject = tag.marker

  if subject.isInvalid:
    if not solver.addWithArtificialVariable(row):
      raiseUnsatisfiableConstraint(constraint)
  else:
    row.solveFor(subject)
    solver.substitute(subject, row)
    solver.rows[subject] = row

  solver.constraints[constraint] = tag
  solver.optimize(solver.objective)

proc removeConstraint*(solver: var Solver, constraint: Constraint) =
  if not solver.constraints.hasKey(constraint):
    raiseUnknownConstraint(constraint)

  let tag = solver.constraints[constraint]
  solver.constraints.del(constraint)
  solver.removeConstraintEffects(constraint, tag)

  if solver.rows.hasKey(tag.marker):
    solver.rows.del(tag.marker)
  else:
    let leaving = solver.getMarkerLeavingRow(tag.marker)
    if leaving.isInvalid:
      raiseInternalSolverError("failed to find leaving row")

    var row = solver.rows[leaving]
    solver.rows.del(leaving)
    row.solveFor(leaving, tag.marker)
    solver.substitute(tag.marker, row)

  solver.optimize(solver.objective)

proc hasConstraint*(solver: Solver, constraint: Constraint): bool =
  solver.constraints.hasKey(constraint)

proc addEditVariable*(solver: var Solver, variable: Variable, strength: Strength) =
  if solver.edits.hasKey(variable.variableId):
    raiseDuplicateEditVariable(variable)

  let clipped = strength.clip
  if clipped == Required:
    raiseBadRequiredStrength()

  let constraint = newConstraint(toExpression(variable), relEq, clipped)
  solver.addConstraint(constraint)
  solver.edits[variable.variableId] = EditInfo(
    tag: solver.constraints[constraint], constraint: constraint, constant: 0.KiwiScalar
  )

proc removeEditVariable*(solver: var Solver, variable: Variable) =
  if not solver.edits.hasKey(variable.variableId):
    raiseUnknownEditVariable(variable)
  let info = solver.edits[variable.variableId]
  solver.removeConstraint(info.constraint)
  solver.edits.del(variable.variableId)

proc hasEditVariable*(solver: Solver, variable: Variable): bool =
  solver.edits.hasKey(variable.variableId)

proc suggestValue*(solver: var Solver, variable: Variable, value: KiwiScalar) =
  if not solver.edits.hasKey(variable.variableId):
    raiseUnknownEditVariable(variable)

  var info = solver.edits[variable.variableId]
  let delta = value - info.constant
  info.constant = value
  solver.edits[variable.variableId] = info

  if solver.rows.hasKey(info.tag.marker):
    if solver.rows[info.tag.marker].add(-delta) < 0:
      solver.infeasibleRows.add info.tag.marker
    solver.dualOptimize()
    return

  if solver.rows.hasKey(info.tag.other):
    if solver.rows[info.tag.other].add(delta) < 0:
      solver.infeasibleRows.add info.tag.other
    solver.dualOptimize()
    return

  for symbol in solver.sortedRowKeys:
    let coeff = solver.rows[symbol].coefficientFor(info.tag.marker)
    if coeff != 0 and solver.rows[symbol].add(delta * coeff) < 0 and
        not symbol.isExternal:
      solver.infeasibleRows.add symbol

  solver.dualOptimize()

proc updateVariables*(solver: var Solver) =
  for id, variable in solver.variables:
    let symbol = solver.vars[id]
    if solver.rows.hasKey(symbol):
      variable.value = solver.rows[symbol].constant
    else:
      variable.value = 0

proc reset*(solver: var Solver) =
  solver = initSolver()

proc dumps*(solver: Solver): string =
  result.add "Objective\n---------\n"
  for symbol, coefficient in solver.objective.cells:
    result.add " + " & $coefficient & " * " & $symbol
  result.add "\n\nTableau\n-------\n"
  for symbol, row in solver.rows:
    result.add $symbol & " |"
    for cell, coefficient in row.cells:
      result.add " + " & $coefficient & " * " & $cell
    result.add "\n"
  result.add "\nVariables\n---------\n"
  for id, symbol in solver.vars:
    result.add $solver.variables[id].name & " = " & $symbol & "\n"
  result.add "\nConstraints\n-----------\n"
  result.add $solver.constraints.len & "\n"

proc dump*(solver: Solver) =
  echo solver.dumps
