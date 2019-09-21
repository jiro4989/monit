import yaml
import logging, streams, os, times, tables, osproc, terminal, times, strutils
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
  version = "1.0.0"
  defaultConfigFile = ".monit.yml"
  stopTriggerFile = ".monit.stop"

proc runCommands(commands: openArray[string], dryRun: bool) =
  for cmd in commands:
    let t0 = epochTime()

    # Execute command
    styledEcho fgBlue, "[Command] ", resetStyle, styleBright, cmd, resetStyle
    if dryRun:
      styledEcho fgGreen, "== DRY RUN ==", resetStyle
    else:
      discard execCmd(cmd)

    let elapsed = epochTime() - t0
    let elapsedStr = elapsed.formatFloat(format = ffDecimal, precision = 3)
    let diff = "(" & elapsedStr & " s)"
    styledEcho fgBlue, "[Processing time] ", resetStyle, styleBright, diff, resetStyle
    echo ""

proc isExecTargetFile(path: string, target: Target): bool =
  ## Returns `path` is exec target file.
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
  ## Generate monit config file to current directory.
  ## If config file has existed then no generating.
  addHandler(newConsoleLogger(lvlInfo, fmtStr = verboseFmtStr,
      useStderr = true))

  if existsFile(defaultConfigFile):
    info &"{defaultConfigFile} existed"
    return 0

  let conf = MonitorConfig(
    sleep: 1,
    targets: @[
      Target(
        name: "Task name",
        paths: @["src", "tests"],
        commands: @["nimble build", "nimble test"],
        extensions: @[".nim"],
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
  ## Run commands on the commands of `file` when file modified.
  let level =
    if verbose: lvlAll
    else: lvlInfo
  addHandler(newConsoleLogger(level, fmtStr = verboseFmtStr, useStderr = true))

  if not existsFile(file):
    error &"{file} doesn't exist"
    return 1

  # No error occurs when press Ctrl-C
  proc quitAction() {.noconv.} =
    quit 0
  setControlCHook(quitAction)
  debug &"loopCount:{loopCount}, file:{file}, verbose:{verbose}"

  # Bind yaml to object
  var conf: MonitorConfig
  var strm = newFileStream(file)
  defer: strm.close()
  strm.load(conf)
  debug &"MonitorConfig:{conf}"
  info "Start to monitor"

  # Run each commands once when `once` flag was true
  for target in conf.targets:
    if target.once:
      runCommands(target.commands, dryRun)

  # Starts to monitor modified timestamp of files
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

            if not f.isExecTargetFile(target):
              continue

            # Check time diff of files
            let modTime = getFileInfo(f).lastWriteTime
            if not targets.hasKey(f):
              debug &"Skip {f} because of first checking"
              targets[f] = modTime
              continue
            if targets[f] == modTime:
              debug &"Skip {f} because of the file has not modified"
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
  dispatchMulti(
    [init],
    [run, help = {
      "file": "A task definition file path",
      "verbose": "Turn ON the debug logging",
      "dryRun": "Not execute commands"}])
