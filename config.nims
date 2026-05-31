import std/[os, strutils]

--mm:atomicArc
--threads:on
--define:useMalloc

task test, "run unit tests":
  for testFile in listFiles("tests/"):
    if testFile.endsWith(".nim") and testFile.splitFile().name.startsWith("t"):
      exec("nim c -r " & quoteShell(testFile))

  exec("nim js -r " & quoteShell("tests/tjsvariables.nim"))
