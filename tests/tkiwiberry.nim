import std/unittest

import kiwiberry

suite "kiwiberry":
  test "greets by name":
    check greet("Nim") == "hello, Nim"

