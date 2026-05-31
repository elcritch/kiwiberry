version       = "0.1.0"
author        = "Your Name"
description   = "A Nim package."
license       = "BSD-3-Clause"
srcDir        = "src"

requires "nim >= 2.0.0"

feature "refs":
  requires "https://github.com/elcritch/cssgrid"
  requires "https://github.com/nucleic/kiwi"
