import std/unittest

import nim_repo

suite "nim_repo":
  test "greets by name":
    check greet("Nim") == "hello, Nim"

