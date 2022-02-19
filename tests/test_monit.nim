discard """
  exitCode: 0
  output: ""
"""

import std/unittest
include monit

block:
  checkpoint "isExecTargetFile"
  block:
    checkpoint "monit.nimは .nim とマッチする"
    check "monit.nim".isExecTargetFile(Target(extensions: @[".nim"]))
    check "monit.nim".isExecTargetFile(Target(extensions: @[".c", ".nim", ".md"]))
  block:
    checkpoint "monit.nimはextensions nim とマッチしない"
    check not "monit.nim".isExecTargetFile(Target(extensions: @["nim"]))
  block:
    checkpoint "monit.nimは monit.nim とする"
    check "monit.nim".isExecTargetFile(Target(files: @["monit.nim"]))
    check "monit.nim".isExecTargetFile(Target(files: @["main.nim", "monit.nim", "test.nim"]))
  block:
    checkpoint "files > exclude_files > extensions > exclude_extensions"
    check "monit.nim".isExecTargetFile(Target(files: @["monit.nim"],
        exclude_files: @["monit.nim"]))
    check "monit.nim".isExecTargetFile(Target(files: @["monit.nim"],
        exclude_extensions: @["monit.nim"]))
  block:
    checkpoint "exclude_files > extensions > exclude_extensions"
    check not "monit.nim".isExecTargetFile(Target(exclude_files: @["monit.nim"],
        extensions: @[".nim"]))
  block:
    checkpoint "extensions > exclude_extensions"
    check "monit.nim".isExecTargetFile(Target(extensions: @[".nim"],
        exclude_extensions: @[".nim"]))
