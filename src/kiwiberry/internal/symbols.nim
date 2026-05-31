import std/hashes

type
  SymbolId* = distinct uint64

  SymbolKind* = enum
    skInvalid
    skExternal
    skSlack
    skError
    skDummy

  Symbol* = object
    kind*: SymbolKind
    id*: SymbolId

proc `==`*(a, b: SymbolId): bool {.borrow.}
proc `<`*(a, b: SymbolId): bool {.borrow.}
proc hash*(id: SymbolId): Hash {.borrow.}
proc `$`*(id: SymbolId): string {.borrow.}

proc initSymbol*(kind: SymbolKind = skInvalid, id: SymbolId = SymbolId(0)): Symbol =
  Symbol(kind: kind, id: id)

proc isInvalid*(symbol: Symbol): bool =
  symbol.kind == skInvalid

proc isExternal*(symbol: Symbol): bool =
  symbol.kind == skExternal

proc isRestricted*(symbol: Symbol): bool =
  symbol.kind in {skSlack, skError, skDummy}

proc isDummy*(symbol: Symbol): bool =
  symbol.kind == skDummy

proc isPivotable*(symbol: Symbol): bool =
  symbol.kind in {skSlack, skError}

proc `==`*(a, b: Symbol): bool =
  a.id == b.id

proc `<`*(a, b: Symbol): bool =
  a.id < b.id

proc hash*(symbol: Symbol): Hash =
  hash(symbol.id)

proc `$`*(symbol: Symbol): string =
  let prefix =
    case symbol.kind
    of skInvalid: "i"
    of skExternal: "v"
    of skSlack: "s"
    of skError: "e"
    of skDummy: "d"
  prefix & $symbol.id
