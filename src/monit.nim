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

proc init(): int =
  if existsFile(defaultConfigFile):
    echo &"{defaultConfigFile} existed"
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
  echo &"Generated {defaultConfigFile}"

proc run(loopCount = -1, file = defaultConfigFile, verbose = false,
         dryRun = false): int =
  # Ctrl-Cで終了する時にエラー扱いにしない
  proc quitAction() {.noconv.} =
    quit 0
  setControlCHook(quitAction)

  if verbose:
    addHandler(newConsoleLogger(fmtStr = verboseFmtStr, useStderr = true))
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
            let (dir, name, ext) = f.splitFile
            debug &"ext:{ext}"
            if ext in target.exclude_extensions:
              continue
            if ext notin target.extensions:
              continue
            let basename = &"{name}{ext}"
            if basename in target.exclude_files:
              continue
            if basename notin target.files:
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

when isMainModule:
  import cligen
  clCfg.version = version
  dispatchMulti([init], [run])
