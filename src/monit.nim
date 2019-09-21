# comment
import yaml
import logging, streams, os, times, tables, osproc
from strformat import `&`

type
  Target = object
    name: string
    path: string
    commands: seq[string]
    extensions: seq[string]
    exclude_extensions: seq[string]
    once: bool
  MonitorConfig = object
    sleep: int
    targets: seq[Target]

Target.setDefaultValue(extensions, @[])
Target.setDefaultValue(exclude_extensions, @[])
Target.setDefaultValue(once, true)

const
  version = "0.0.1"

proc runCommands(commands: openArray[string], dryRun: bool) =
  for cmd in commands:
    debug &"cmd:{cmd}"
    if dryRun:
      echo "== DRY RUN =="
    else:
      echo execProcess(cmd)

proc init(): int =
  discard

proc run(loopCount = -1, file = ".monit.yml", verbose = false, dryRun = false): int =
  # Ctrl-Cで終了する時にエラー扱いにしない
  proc quitAction() {.noconv.} =
    quit 0
  setControlCHook(quitAction)

  if verbose:
    addHandler(newConsoleLogger(fmtStr=verboseFmtStr, useStderr=true))
  debug &"loopCount:{loopCount}, file:{file}, verbose:{verbose}"

  # yamlファイルをconfオブジェクトにマッピング
  var conf: MonitorConfig
  var strm = newFileStream(file)
  defer: strm.close()
  strm.load(conf)
  debug &"MonitorConfig:{conf}"

  # 一度は最低実行するオプションが有効のときは実行
  for target in conf.targets:
    if target.once:
      runCommands(target.commands, dryRun)

  # ファイル変更の監視を開始
  # 無限ループ
  var currentLoopCount: int
  var targets: Table[string, Time]
  while not (0 < loopCount and loopCount <= currentLoopCount):
    debug &"currentLoopCount:{currentLoopCount}, loopCount:{loopCount}"
    if 0 < loopCount:
      inc(currentLoopCount)
    for target in conf.targets:
      for f in walkDirRec(target.path):
        debug &"TargetFile:{f}"

        # ファイル拡張子をチェック
        let ext = f.splitFile.ext
        debug &"ext:{ext}"
        if ext in target.exclude_extensions:
          continue
        if ext notin target.extensions:
          continue

        # ファイルの更新時間のチェック
        let modTime = getFileInfo(f).lastWriteTime
        if not targets.hasKey(f):
          debug "初めてのファイル参照のためスキップ"
          targets[f] = modTime
          continue
        if targets[f] == modTime:
          debug "ファイル変更なしのためスキップ"
          continue

        targets[f] = modTime
        runCommands(target.commands, dryRun)
        break
    sleep conf.sleep * 1000

when isMainModule:
  import cligen
  clCfg.version = version
  dispatchMulti([init], [run])
