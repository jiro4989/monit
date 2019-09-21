import unittest
include monit

suite "isExecTargetFile":
  test "monit.nimは .nim とマッチする":
    check "monit.nim".isExecTargetFile(Target(extensions: @[".nim"]))
    check "monit.nim".isExecTargetFile(Target(extensions: @[".c", ".nim", ".md"]))
  test "monit.nimはextensions nim とマッチしない":
    check not "monit.nim".isExecTargetFile(Target(extensions: @["nim"]))
  test "monit.nimは monit.nim とする":
    check "monit.nim".isExecTargetFile(Target(files: @["monit.nim"]))
    check "monit.nim".isExecTargetFile(Target(files: @["main.nim", "monit.nim", "test.nim"]))
  test "files > exclude_files > extensions > exclude_extensions":
    check "monit.nim".isExecTargetFile(Target(files: @["monit.nim"], exclude_files: @["monit.nim"]))
    check "monit.nim".isExecTargetFile(Target(files: @["monit.nim"], exclude_extensions: @["monit.nim"]))
  test "exclude_files > extensions > exclude_extensions":
    check not "monit.nim".isExecTargetFile(Target(exclude_files: @["monit.nim"], extensions: @[".nim"]))
  test "extensions > exclude_extensions":
    check "monit.nim".isExecTargetFile(Target(extensions: @[".nim"], exclude_extensions: @[".nim"]))
