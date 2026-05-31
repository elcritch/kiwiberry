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
proc `$`*(id: SymbolId): string {.borrow.}

proc hash*(id: SymbolId): Hash {.inline.} =
  cast[Hash](uint64(id))

proc initSymbol*(
    kind: SymbolKind = skInvalid, id: SymbolId = SymbolId(0)
): Symbol {.inline.} =
  Symbol(kind: kind, id: id)

proc isInvalid*(symbol: Symbol): bool {.inline.} =
  symbol.kind == skInvalid

proc isExternal*(symbol: Symbol): bool {.inline.} =
  symbol.kind == skExternal

proc isRestricted*(symbol: Symbol): bool {.inline.} =
  symbol.kind in {skSlack, skError, skDummy}

proc isDummy*(symbol: Symbol): bool {.inline.} =
  symbol.kind == skDummy

proc isPivotable*(symbol: Symbol): bool {.inline.} =
  symbol.kind in {skSlack, skError}

proc `==`*(a, b: Symbol): bool {.inline.} =
  a.id == b.id

proc `<`*(a, b: Symbol): bool {.inline.} =
  a.id < b.id

proc hash*(symbol: Symbol): Hash {.inline.} =
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
