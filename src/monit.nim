import yaml
import logging, streams, os, times, tables, osproc
from strformat import `&`

type
  Target = object
    name: string
    paths: seq[string]
    commands: seq[string]
    extensions: seq[string]
    files: seq[string]
    exclude_extensions: seq[string]
    exclude_files: seq[string]
    once: bool
  MonitorConfig = object
    sleep: int
    targets: seq[Target]

Target.setDefaultValue(extensions, @[])
Target.setDefaultValue(files, @[])
Target.setDefaultValue(exclude_extensions, @[])
Target.setDefaultValue(exclude_files, @[])
Target.setDefaultValue(once, true)

const
  version = "0.0.1"
  defaultConfigFile = ".monit.yml"
  stopTriggerFile = ".monit.stop"

proc runCommands(commands: openArray[string], dryRun: bool) =
  for cmd in commands:
    debug &"cmd:{cmd}"
    if dryRun:
      echo "== DRY RUN =="
    else:
      echo execProcess(cmd)

proc isExecTargetFile(path: string, target: Target): bool =
  let (dir, name, ext) = path.splitFile
  let basename = &"{name}{ext}"
  if basename in target.files:
    return true
  if basename in target.exclude_files:
    return false
  if ext in target.extensions:
    return true
  if ext in target.exclude_extensions:
    return false
  return false

proc init(): int =
  addHandler(newConsoleLogger(lvlInfo, fmtStr = verboseFmtStr, useStderr = true))

  if existsFile(defaultConfigFile):
    info &"{defaultConfigFile} existed"
    return 0

  let conf = MonitorConfig(
    sleep: 1,
    targets: @[
      Target(
        name: "Task name",
        paths: @["src", "tests"],
        commands: @["nimble test"],
        extensions: @["nim"],
        once: true,
    ),
  ],
    )
  var s = newFileStream(defaultConfigFile, fmWrite)
  defer: s.close()
  dump(conf, s)
  info &"Generated {defaultConfigFile}"

proc run(loopCount = -1, file = defaultConfigFile, verbose = false,
         dryRun = false): int =
  let level =
    if verbose: lvlAll
    else: lvlInfo
  addHandler(newConsoleLogger(level, fmtStr = verboseFmtStr, useStderr = true))

  if not existsFile(file):
    error &"{file} doesn't exist"
    return 1

  # Ctrl-Cで終了する時にエラー扱いにしない
  proc quitAction() {.noconv.} =
    quit 0
  setControlCHook(quitAction)
  debug &"loopCount:{loopCount}, file:{file}, verbose:{verbose}"

  # yamlファイルをconfオブジェクトにマッピング
  var conf: MonitorConfig
  var strm = newFileStream(file)
  defer: strm.close()
  strm.load(conf)
  debug &"MonitorConfig:{conf}"
  info "Start to monitor"

  # 一度は最低実行するオプションが有効のときは実行
  for target in conf.targets:
    if target.once:
      runCommands(target.commands, dryRun)

  # ファイル変更の監視を開始
  # 無限ループ
  var currentLoopCount: int
  var targets: Table[string, Time]
  while not (0 < loopCount and loopCount <= currentLoopCount) and
        not existsFile(stopTriggerFile):
    debug &"currentLoopCount:{currentLoopCount}, loopCount:{loopCount}"
    if 0 < loopCount:
      inc(currentLoopCount)
    for target in conf.targets:
      block targetBlock:
        for path in target.paths:
          if not existsDir(path):
            continue
          for f in walkDirRec(path):
            debug &"TargetFile:{f}"

            # ファイル拡張子とファイル名をチェック
            if not f.isExecTargetFile(target):
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
            break targetBlock
    sleep conf.sleep * 1000
  discard tryRemoveFile(stopTriggerFile)
  info "End to monitor"

when isMainModule and not defined(isTesting):
  import cligen
  clCfg.version = version
  dispatchMulti([init], [run])
