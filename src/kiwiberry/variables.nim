## Solver variable API.

import std/hashes
when not defined(js):
  import std/atomics

import ./scalars

type
  VariableId* = distinct uint64 ## Stable identity assigned to a variable.

  Variable* = ref object ## Identity-bearing solver variable.
    id: VariableId
    nameValue: string
    currentValue: KiwiScalar

when defined(js):
  var nextVariableId = 1'u64

  proc takeVariableId(): VariableId =
    result = VariableId(nextVariableId)
    inc nextVariableId

else:
  var nextVariableId: Atomic[uint64]
  nextVariableId.store(1)

  proc takeVariableId(): VariableId =
    VariableId(nextVariableId.fetchAdd(1))

proc `==`*(a, b: VariableId): bool {.borrow.}
proc `<`*(a, b: VariableId): bool {.borrow.}
proc hash*(id: VariableId): Hash {.borrow.}
proc `$`*(id: VariableId): string {.borrow.}

proc newVariable*(name = ""): Variable =
  ## Creates a new variable with an optional display name.
  new(result)
  result.id = takeVariableId()
  result.nameValue = name

proc vars*(name: string): Variable =
  ## Creates a new variable from a custom string literal, e.g. `vars"x"`.
  newVariable(name)

proc variableId*(variable: Variable): VariableId {.inline.} =
  ## Returns the identity assigned to `variable`.
  variable.id

proc sameVariable*(a, b: Variable): bool {.inline.} =
  ## Returns true when both handles refer to the same variable identity.
  a != nil and b != nil and a.id == b.id

proc name*(variable: Variable): lent string =
  ## Returns the variable's display name.
  variable.nameValue

proc `name=`*(variable: Variable, name: string) =
  ## Updates the variable's display name.
  variable.nameValue = name

proc value*(variable: Variable): KiwiScalar {.inline.} =
  ## Returns the variable's current solved value.
  variable.currentValue

proc `value=`*(variable: Variable, value: KiwiScalar) =
  ## Updates the variable's current value.
  variable.currentValue = value.requireFinite("variable value")

proc setSolverValue*(variable: Variable, value: KiwiScalar) {.inline.} =
  ## Writes a finite value produced by the solver without repeating validation.
  variable.currentValue = value

proc hash*(variable: Variable): Hash =
  ## Hashes a variable by identity.
  hash(variable.id)

proc `$`*(variable: Variable): string =
  ## Returns the variable's name, or an identity-based fallback.
  if variable == nil:
    "nil"
  elif variable.nameValue.len == 0:
    "v" & $variable.id
  else:
    variable.nameValue
