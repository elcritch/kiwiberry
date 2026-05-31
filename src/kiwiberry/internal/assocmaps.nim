import std/algorithm

type
  AssocEntry[K, V] = object
    key: K
    val: V

  AssocMap*[K, V] = object
    entries: seq[AssocEntry[K, V]]

proc cmpEntryKey[K, V](entry: AssocEntry[K, V], key: K): int =
  if entry.key < key:
    -1
  elif key < entry.key:
    1
  else:
    0

proc lowerIndex[K, V](map: AssocMap[K, V], key: K): int =
  lowerBound(map.entries, key, cmpEntryKey[K, V])

proc findIndex[K, V](map: AssocMap[K, V], key: K): int =
  result = map.lowerIndex(key)
  if result >= map.entries.len or map.entries[result].key != key:
    result = -1

proc initAssocMap*[K, V](): AssocMap[K, V] =
  AssocMap[K, V](entries: @[])

proc len*[K, V](map: AssocMap[K, V]): int =
  map.entries.len

proc hasKey*[K, V](map: AssocMap[K, V], key: K): bool =
  map.findIndex(key) >= 0

proc `[]`*[K, V](map: AssocMap[K, V], key: K): V =
  let index = map.findIndex(key)
  if index < 0:
    raise newException(KeyError, "key not found")
  map.entries[index].val

proc `[]=`*[K, V](map: var AssocMap[K, V], key: K, value: sink V) =
  let index = map.lowerIndex(key)
  if index < map.entries.len and map.entries[index].key == key:
    map.entries[index].val = value
  else:
    map.entries.insert(AssocEntry[K, V](key: key, val: value), index)

proc del*[K, V](map: var AssocMap[K, V], key: K) =
  let index = map.findIndex(key)
  if index >= 0:
    map.entries.delete(index)

proc pop*[K, V](map: var AssocMap[K, V], key: K, value: var V): bool =
  let index = map.findIndex(key)
  if index >= 0:
    value = move map.entries[index].val
    map.entries.delete(index)
    result = true

proc getOrDefault*[K, V](map: AssocMap[K, V], key: K, default: V): V =
  let index = map.findIndex(key)
  if index >= 0:
    map.entries[index].val
  else:
    default

iterator keys*[K, V](map: AssocMap[K, V]): K =
  for entry in map.entries:
    yield entry.key

iterator pairs*[K, V](map: AssocMap[K, V]): (K, V) =
  for entry in map.entries:
    yield (entry.key, entry.val)

iterator mpairs*[K, V](map: var AssocMap[K, V]): (K, var V) =
  for entry in map.entries.mitems:
    yield (entry.key, entry.val)

template withValue*[K, V](map: var AssocMap[K, V], key: K, value, body: untyped) =
  let index = findIndex(map, key)
  if index >= 0:
    var value {.inject.} = addr(map.entries[index].val)
    body

template withValue*[K, V](
    map: var AssocMap[K, V], key: K, value, body1, body2: untyped
) =
  let index = findIndex(map, key)
  if index >= 0:
    var value {.inject.} = addr(map.entries[index].val)
    body1
  else:
    body2

template withValue*[K, V](map: AssocMap[K, V], key: K, value, body1, body2: untyped) =
  let index = findIndex(map, key)
  if index >= 0:
    let value {.inject.} = map.entries[index].val
    body1
  else:
    body2

template withValue*[K, V](map: AssocMap[K, V], key: K, value, body: untyped) =
  withValue(map, key, value, body):
    discard
