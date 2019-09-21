# Package

version       = "0.1.0"
author        = "jiro4989"
description   = "A new awesome nimble package"
license       = "MIT"
srcDir        = "src"
bin           = @["monit"]
binDir        = "bin"

# Dependencies

requires "nim >= 0.20.2"
requires "yaml >= 0.12.0"
requires "cligen >= 0.9.32"

import strformat, os

task checkFormat, "Checking that codes were formatted":
  var errCount = 0
  for f in listFiles("src"):
    let tmpFile = f & ".tmp"
    exec &"nimpretty --output:{tmpFile} {f}"
    if readFile(f) != readFile(tmpFile):
      inc errCount
    rmFile tmpFile
  exec &"exit {errCount}"

task ci, "Run CI":
  exec "nim -v"
  exec "nimble -v"
  exec "nimble check"
  if buildOS == "linux":
    exec "nimble checkFormat"
  exec "nimble install -Y"
  exec "nimble test -Y"
  exec "nimble build -d:release -Y"
  exec "./bin/monit help"
  exec "./bin/monit --version"
