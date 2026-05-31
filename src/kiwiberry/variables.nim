import std/hashes

import ./scalars

type
  VariableId* = distinct uint64

  Variable* = ref object
    id: VariableId
    nameValue: string
    currentValue: KiwiScalar

var nextVariableId = 1'u64

proc `==`*(a, b: VariableId): bool {.borrow.}
proc `<`*(a, b: VariableId): bool {.borrow.}
proc hash*(id: VariableId): Hash {.borrow.}
proc `$`*(id: VariableId): string {.borrow.}

proc newVariable*(name = ""): Variable =
  new(result)
  result.id = VariableId(nextVariableId)
  result.nameValue = name
  inc nextVariableId

proc variableId*(variable: Variable): VariableId =
  variable.id

proc sameVariable*(a, b: Variable): bool =
  a != nil and b != nil and a.id == b.id

proc name*(variable: Variable): lent string =
  variable.nameValue

proc `name=`*(variable: Variable, name: string) =
  variable.nameValue = name

proc value*(variable: Variable): KiwiScalar =
  variable.currentValue

proc `value=`*(variable: Variable, value: KiwiScalar) =
  variable.currentValue = value

proc hash*(variable: Variable): Hash =
  hash(variable.id)

proc `$`*(variable: Variable): string =
  if variable == nil:
    "nil"
  elif variable.nameValue.len == 0:
    "v" & $variable.id
  else:
    variable.nameValue
