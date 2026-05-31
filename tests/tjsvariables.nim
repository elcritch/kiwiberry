import std/assertions

import kiwiberry

block javascriptVariableLiteral:
  let x = vars"x"
  let y = vars"y"

  doAssert x.name == "x"
  doAssert y.name == "y"
  doAssert not x.sameVariable(y)
  doAssert (x + y == 10).relation == relEq
