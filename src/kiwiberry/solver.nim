## Public solver API.

import std/tables

import ./[constraints, errors, expressions, scalars, strengths, variables]
import ./internal/[assocmaps, rows, symbols]

type
  Tag = object
    marker: Symbol
    other: Symbol

  EditInfo = object
    tag: Tag
    constraint: Constraint
    constant: KiwiScalar

  VarInfo = object
    symbol: Symbol
    variable: Variable

  Solver* = object ## Incremental Cassowary solver state.
    constraints: OrderedTable[Constraint, Tag]
    rows: AssocMap[Symbol, Row]
    vars: AssocMap[VariableId, VarInfo]
    edits: OrderedTable[VariableId, EditInfo]
    infeasibleRows: seq[Symbol]
    objective: Row
    artificial: Row
    hasArtificial: bool
    idTick: uint64

  SolverRef* = ref Solver ## Shared solver handle returned by `newSolver`.

proc initSolver*(): Solver =
  ## Creates an empty value-style solver.
  Solver(
    constraints: initOrderedTable[Constraint, Tag](),
    rows: initAssocMap[Symbol, Row](),
    vars: initAssocMap[VariableId, VarInfo](),
    edits: initOrderedTable[VariableId, EditInfo](),
    objective: initRow(),
    artificial: initRow(),
    idTick: 1,
  )

proc newSolver*(): SolverRef =
  ## Creates an empty ref-style solver handle.
  new(result)
  result[] = initSolver()

proc newSymbol(solver: var Solver, kind: SymbolKind): Symbol =
  result = initSymbol(kind, SymbolId(solver.idTick))
  inc solver.idTick

proc sortedKeys(row: Row): seq[Symbol] =
  result = newSeqOfCap[Symbol](row.cells.len)
  for symbol in row.cells.keys:
    result.add symbol

proc preferSymbol(symbol, current: Symbol): bool =
  current.isInvalid or symbol < current

proc preferRatio(
    symbol: Symbol, ratio: KiwiScalar, current: Symbol, currentRatio: KiwiScalar
): bool =
  ratio < currentRatio or
    (not current.isInvalid and ratio == currentRatio and symbol < current)

proc getVarSymbol(solver: var Solver, variable: Variable): Symbol =
  let id = variable.variableId
  solver.vars.withValue(id, info):
    return info[].symbol

  result = solver.newSymbol(skExternal)
  solver.vars[id] = VarInfo(symbol: result, variable: variable)

proc allDummies(row: Row): bool =
  for symbol in row.cells.keys:
    if not symbol.isDummy:
      return false
  true

proc anyPivotableSymbol(row: Row): Symbol =
  result = initSymbol()
  for symbol in row.cells.keys:
    if symbol.isPivotable and symbol.preferSymbol(result):
      result = symbol

proc substitute(solver: var Solver, symbol: Symbol, row: Row) =
  for key, current in solver.rows.mpairs:
    current.substitute(symbol, row)
    if not key.isExternal and current.constant < 0:
      solver.infeasibleRows.add key

  solver.objective.substitute(symbol, row)
  if solver.hasArtificial:
    solver.artificial.substitute(symbol, row)

proc createRow(solver: var Solver, constraint: Constraint, tag: var Tag): Row =
  result = initRow(constraint.expression.constant)

  let terms = constraint.expression.terms
  for index in 0 ..< terms.len:
    let term {.cursor.} = terms[index]
    if abs(term.coefficient.float64) >= 1.0e-8:
      let symbol = solver.getVarSymbol(term.variable)
      solver.rows.withValue(symbol, existing):
        result.insert(existing[], term.coefficient)
      do:
        result.insert(symbol, term.coefficient)

  case constraint.relation
  of relLe, relGe:
    let coeff =
      if constraint.relation == relLe:
        1.KiwiScalar
      else:
        KiwiScalar(-1.0)
    let slack = solver.newSymbol(skSlack)
    tag.marker = slack
    result.insert(slack, coeff)
    if constraint.strength < Required:
      let error = solver.newSymbol(skError)
      tag.other = error
      result.insert(error, KiwiScalar(-coeff.float64))
      solver.objective.insert(error, constraint.strength.toKiwiScalar)
  of relEq:
    if constraint.strength < Required:
      let errPlus = solver.newSymbol(skError)
      let errMinus = solver.newSymbol(skError)
      tag.marker = errPlus
      tag.other = errMinus
      result.insert(errPlus, KiwiScalar(-1.0))
      result.insert(errMinus, 1.KiwiScalar)
      solver.objective.insert(errPlus, constraint.strength.toKiwiScalar)
      solver.objective.insert(errMinus, constraint.strength.toKiwiScalar)
    else:
      let dummy = solver.newSymbol(skDummy)
      tag.marker = dummy
      result.insert(dummy)

  if result.constant < 0:
    result.reverseSign()

proc chooseSubject(row: Row, tag: Tag): Symbol =
  result = initSymbol()
  for symbol in row.cells.keys:
    if symbol.isExternal and symbol.preferSymbol(result):
      result = symbol

  if not result.isInvalid:
    return result

  if tag.marker.isPivotable and row.coefficientFor(tag.marker) < 0:
    return tag.marker

  if tag.other.isPivotable and row.coefficientFor(tag.other) < 0:
    return tag.other

proc getEnteringSymbol(objective: Row): Symbol =
  result = initSymbol()
  for symbol, coefficient in objective.cells:
    if not symbol.isDummy and coefficient < 0 and symbol.preferSymbol(result):
      result = symbol

proc getDualEnteringSymbol(solver: Solver, row: Row): Symbol =
  var ratio = float64.high.KiwiScalar
  result = initSymbol()
  for symbol, coefficient in row.cells:
    if coefficient > 0 and not symbol.isDummy:
      let r = KiwiScalar(
        solver.objective.coefficientFor(symbol).float64 / coefficient.float64
      )
      if symbol.preferRatio(r, result, ratio):
        ratio = r
        result = symbol

proc getLeavingRow(solver: var Solver, entering: Symbol): Symbol =
  var ratio = float64.high.KiwiScalar
  result = initSymbol()
  for symbol, row in solver.rows.mpairs:
    if not symbol.isExternal:
      let temp = row.coefficientFor(entering)
      if temp < 0:
        let tempRatio = KiwiScalar(-row.constant.float64 / temp.float64)
        if symbol.preferRatio(tempRatio, result, ratio):
          ratio = tempRatio
          result = symbol

proc getMarkerLeavingRow(solver: var Solver, marker: Symbol): Symbol =
  var r1 = float64.high.KiwiScalar
  var r2 = float64.high.KiwiScalar
  var first = initSymbol()
  var second = initSymbol()
  var third = initSymbol()

  for symbol, row in solver.rows.mpairs:
    let c = row.coefficientFor(marker)
    if c != 0:
      if symbol.isExternal:
        if third.isInvalid or third < symbol:
          third = symbol
      elif c < 0:
        let r = KiwiScalar(-row.constant.float64 / c.float64)
        if symbol.preferRatio(r, first, r1):
          r1 = r
          first = symbol
      else:
        let r = KiwiScalar(row.constant.float64 / c.float64)
        if symbol.preferRatio(r, second, r2):
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

    var row: Row
    discard solver.rows.pop(leaving, row)
    row.solveFor(leaving, entering)
    solver.substitute(entering, row)
    solver.rows[entering] = row

proc dualOptimize(solver: var Solver) =
  while solver.infeasibleRows.len > 0:
    let leaving = solver.infeasibleRows.pop()
    if solver.rows.hasKey(leaving) and
        abs(solver.rows[leaving].constant.float64) >= 1.0e-8 and
        solver.rows[leaving].constant < 0:
      let entering = solver.getDualEnteringSymbol(solver.rows[leaving])
      if entering.isInvalid:
        raiseInternalSolverError("Dual optimize failed.")

      var row: Row
      discard solver.rows.pop(leaving, row)
      row.solveFor(leaving, entering)
      solver.substitute(entering, row)
      solver.rows[entering] = row

proc addWithArtificialVariable(solver: var Solver, row: Row): bool =
  let art = solver.newSymbol(skSlack)
  solver.rows[art] = row
  solver.artificial = row
  solver.hasArtificial = true

  solver.optimize(solver.artificial)
  result = abs(solver.artificial.constant.float64) < 1.0e-8
  solver.hasArtificial = false
  solver.artificial = initRow()

  var row: Row
  if solver.rows.pop(art, row):
    if row.cells.len == 0:
      return result

    let entering = anyPivotableSymbol(row)
    if entering.isInvalid:
      return false

    row.solveFor(art, entering)
    solver.substitute(entering, row)
    solver.rows[entering] = row

  for _, current in solver.rows.mpairs:
    current.remove(art)
  solver.objective.remove(art)

proc removeMarkerEffects(solver: var Solver, marker: Symbol, strength: Strength) =
  let strengthValue = KiwiScalar(-strength.toKiwiScalar.float64)
  solver.rows.withValue(marker, row):
    solver.objective.insert(row[], strengthValue)
  do:
    solver.objective.insert(marker, strengthValue)

proc removeConstraintEffects(solver: var Solver, constraint: Constraint, tag: Tag) =
  if tag.marker.kind == skError:
    solver.removeMarkerEffects(tag.marker, constraint.strength)
  if tag.other.kind == skError:
    solver.removeMarkerEffects(tag.other, constraint.strength)

proc findConstraint(solver: Solver, constraint: Constraint): Constraint =
  if constraint.isNil:
    return nil

  if solver.constraints.hasKey(constraint):
    return constraint

  for existing in solver.constraints.keys:
    if existing.sameShape(constraint):
      return existing

  nil

proc addConstraint*(solver: var Solver, constraint: Constraint) =
  ## Adds `constraint` to `solver`.
  ##
  ## Raises `DuplicateConstraintError` if the same constraint identity is
  ## already present. Raises `UnsatisfiableConstraintError` for required
  ## constraints that cannot be satisfied.
  if solver.constraints.hasKey(constraint):
    raiseDuplicateConstraint(constraint)

  var tag: Tag
  var row = solver.createRow(constraint, tag)
  var subject = chooseSubject(row, tag)

  if subject.isInvalid and row.allDummies:
    if abs(row.constant.float64) >= 1.0e-8:
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
  ## Removes `constraint` from `solver`.
  ##
  ## The lookup accepts the same constraint identity or a structurally equivalent
  ## constraint. Raises `UnknownConstraintError` when no matching constraint has
  ## been added.
  let storedConstraint = solver.findConstraint(constraint)
  if storedConstraint.isNil:
    raiseUnknownConstraint(constraint)

  let tag = solver.constraints[storedConstraint]
  solver.constraints.del(storedConstraint)
  solver.removeConstraintEffects(storedConstraint, tag)

  var markerRow: Row
  if solver.rows.pop(tag.marker, markerRow):
    discard
  else:
    let leaving = solver.getMarkerLeavingRow(tag.marker)
    if leaving.isInvalid:
      raiseInternalSolverError("failed to find leaving row")

    var row: Row
    discard solver.rows.pop(leaving, row)
    row.solveFor(leaving, tag.marker)
    solver.substitute(tag.marker, row)

  solver.optimize(solver.objective)

proc hasConstraint*(solver: Solver, constraint: Constraint): bool =
  ## Returns true when `constraint` or a structurally equivalent constraint has been added.
  not solver.findConstraint(constraint).isNil

proc addEditVariable*(solver: var Solver, variable: Variable, strength: Strength) =
  ## Adds `variable` as an editable variable with a non-required strength.
  ##
  ## Raises `DuplicateEditVariableError` when already present and
  ## `BadRequiredStrengthError` when `strength` clips to `Required`.
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
  ## Removes an editable variable.
  ##
  ## Raises `UnknownEditVariableError` if `variable` is not editable.
  if not solver.edits.hasKey(variable.variableId):
    raiseUnknownEditVariable(variable)
  let info = solver.edits[variable.variableId]
  solver.removeConstraint(info.constraint)
  solver.edits.del(variable.variableId)

proc hasEditVariable*(solver: Solver, variable: Variable): bool =
  ## Returns true when `variable` has been added as an edit variable.
  solver.edits.hasKey(variable.variableId)

proc suggestValue*(solver: var Solver, variable: Variable, value: KiwiScalar) =
  ## Suggests a new value for an edit variable and dual-optimizes the solver.
  ##
  ## Raises `UnknownEditVariableError` if `variable` is not editable.
  let checkedValue = value.requireFinite("suggested value")
  if not solver.edits.hasKey(variable.variableId):
    raiseUnknownEditVariable(variable)

  var info = solver.edits[variable.variableId]
  let delta = KiwiScalar(checkedValue.float64 - info.constant.float64)
  info.constant = checkedValue
  solver.edits[variable.variableId] = info

  solver.rows.withValue(info.tag.marker, row):
    if row[].add(KiwiScalar(-delta.float64)) < 0:
      solver.infeasibleRows.add info.tag.marker
    solver.dualOptimize()
    return

  solver.rows.withValue(info.tag.other, row):
    if row[].add(delta) < 0:
      solver.infeasibleRows.add info.tag.other
    solver.dualOptimize()
    return

  for symbol, row in solver.rows.mpairs:
    if row.addProductFor(info.tag.marker, delta) and row.constant < 0 and
        not symbol.isExternal:
      solver.infeasibleRows.add symbol

  solver.dualOptimize()

proc updateVariables*(solver: var Solver) =
  ## Writes solved values back into all external variables known to `solver`.
  for _, info in solver.vars.mpairs:
    var updated = false
    solver.rows.withValue(info.symbol, row):
      if info.variable.value != row[].constant:
        info.variable.value = row[].constant
      updated = true
    if not updated:
      if info.variable.value != 0:
        info.variable.value = 0

proc reset*(solver: var Solver) =
  ## Resets the solver to the empty starting state.
  solver = initSolver()

proc dumps*(solver: Solver): string =
  ## Returns a textual dump of the current solver internals.
  result.add "Objective\n---------\n"
  for symbol in solver.objective.sortedKeys:
    let coefficient = solver.objective.cells[symbol]
    result.add " + " & $coefficient & " * " & $symbol
  result.add "\n\nTableau\n-------\n"
  for symbol in solver.rows.keys:
    let row = solver.rows[symbol]
    result.add $symbol & " |"
    for cell in row.sortedKeys:
      let coefficient = row.cells[cell]
      result.add " + " & $coefficient & " * " & $cell
    result.add "\n"
  result.add "\nVariables\n---------\n"
  for _, info in solver.vars:
    result.add $info.variable.name & " = " & $info.symbol & "\n"
  result.add "\nConstraints\n-----------\n"
  result.add $solver.constraints.len & "\n"

proc dump*(solver: Solver) =
  ## Writes a textual dump of the current solver internals to stdout.
  echo solver.dumps

proc `[]=`*(solver: var Solver, variable: Variable, strength: Strength) =
  ## Adds `variable` as an edit variable with `strength`.
  solver.addEditVariable(variable, strength)

proc constraint*(
    solver: var Solver, constraint: Constraint
): Constraint {.discardable.} =
  ## Adds `constraint` to `solver` and returns it for later removal.
  solver.addConstraint(constraint)
  constraint

proc remove*(solver: var Solver, constraint: Constraint) =
  ## Removes `constraint` from `solver`.
  solver.removeConstraint(constraint)

proc remove*(solver: var Solver, variable: Variable) =
  ## Removes `variable` as an edit variable.
  solver.removeEditVariable(variable)

proc has*(solver: Solver, constraint: Constraint): bool =
  ## Returns true when `constraint` has been added to `solver`.
  solver.hasConstraint(constraint)

proc has*(solver: Solver, variable: Variable): bool =
  ## Returns true when `variable` is an edit variable.
  solver.hasEditVariable(variable)

proc suggest*(solver: var Solver, variable: Variable, value: KiwiScalar) =
  ## Suggests `value` for an edit variable.
  solver.suggestValue(variable, value)

proc update*(solver: var Solver) =
  ## Writes solved values back into variables known to `solver`.
  solver.updateVariables()

proc addConstraint*(solver: SolverRef, constraint: Constraint) =
  ## Adds `constraint` to a ref-style solver.
  solver[].addConstraint(constraint)

proc removeConstraint*(solver: SolverRef, constraint: Constraint) =
  ## Removes `constraint` from a ref-style solver.
  solver[].removeConstraint(constraint)

proc hasConstraint*(solver: SolverRef, constraint: Constraint): bool =
  ## Returns true when `constraint` has been added to a ref-style solver.
  solver[].hasConstraint(constraint)

proc addEditVariable*(solver: SolverRef, variable: Variable, strength: Strength) =
  ## Adds `variable` as an edit variable on a ref-style solver.
  solver[].addEditVariable(variable, strength)

proc removeEditVariable*(solver: SolverRef, variable: Variable) =
  ## Removes an edit variable from a ref-style solver.
  solver[].removeEditVariable(variable)

proc hasEditVariable*(solver: SolverRef, variable: Variable): bool =
  ## Returns true when `variable` is editable in a ref-style solver.
  solver[].hasEditVariable(variable)

proc suggestValue*(solver: SolverRef, variable: Variable, value: KiwiScalar) =
  ## Suggests a new edit-variable value on a ref-style solver.
  solver[].suggestValue(variable, value)

proc updateVariables*(solver: SolverRef) =
  ## Writes solved values back into variables known to a ref-style solver.
  solver[].updateVariables()

proc reset*(solver: SolverRef) =
  ## Resets a ref-style solver to the empty starting state.
  solver[] = initSolver()

proc dumps*(solver: SolverRef): string =
  ## Returns a textual dump from a ref-style solver.
  solver[].dumps()

proc dump*(solver: SolverRef) =
  ## Writes a textual dump from a ref-style solver to stdout.
  solver[].dump()

proc `[]=`*(solver: SolverRef, variable: Variable, strength: Strength) =
  ## Adds `variable` as an edit variable on a ref-style solver.
  solver[].addEditVariable(variable, strength)

proc constraint*(
    solver: SolverRef, constraint: Constraint
): Constraint {.discardable.} =
  ## Adds `constraint` to a ref-style solver and returns it for later removal.
  solver[].addConstraint(constraint)
  constraint

proc remove*(solver: SolverRef, constraint: Constraint) =
  ## Removes `constraint` from a ref-style solver.
  solver[].removeConstraint(constraint)

proc remove*(solver: SolverRef, variable: Variable) =
  ## Removes `variable` as an edit variable from a ref-style solver.
  solver[].removeEditVariable(variable)

proc has*(solver: SolverRef, constraint: Constraint): bool =
  ## Returns true when `constraint` has been added to a ref-style solver.
  solver[].hasConstraint(constraint)

proc has*(solver: SolverRef, variable: Variable): bool =
  ## Returns true when `variable` is editable in a ref-style solver.
  solver[].hasEditVariable(variable)

proc suggest*(solver: SolverRef, variable: Variable, value: KiwiScalar) =
  ## Suggests `value` for an edit variable on a ref-style solver.
  solver[].suggestValue(variable, value)

proc update*(solver: SolverRef) =
  ## Writes solved values back into variables known to a ref-style solver.
  solver[].updateVariables()
