# monit

`monit` is the simple task runner.
Run tasks and watch file changes with custom paths.

![monit](./doc/monit.gif)

## Usage

`monit` run commands when files have changed.
`monit` needs a `.monit.yml` task definition file on current directory.
Please you run below at first.

```bash
monit init
```

A template of `.monit.yml` will be generated.
You edit the yaml file and you run below.

```bash
monit run
```

## Task definitions

A example of `.monit.yml` of this repository.
See below.

```yml
%YAML 1.2
%TAG !n! tag:nimyaml.org,2016:
--- !n!custom:MonitorConfig 
sleep: 1
targets: 
  - 
    name: Task name
    paths: [src, tests]
    commands:
      - nimble build --hints:off
      - nimble test
    extensions: [.nim]
    files: []
    exclude_extensions: []
    exclude_files: []
    once: y
```

A descriptions of these keys and values.

* `sleep` - A interval to monitor files (secconds)

### Targets

| key | value |
| --- | ----- |
| name               | Task name ( for human ) |
| paths              | Target directory to monitor |
| commands           | Commands to run when files have changed |
| extensions         | Extensions of target files |
| files              | File path of target files |
| exclude_extensions | Extensions of exclude files |
| exclude_files      | File path of exclude files |
| once               | Run command once at first when you executed `monit` |

## Installation

```bash
nimble install monit
```

## Development

Nim 1.4.0

## Help

    % monit help
    This is a multiple-dispatch command.  Top-level --help/--help-syntax
    is also available.  Usage is like:
        monit {SUBCMD} [subcommand-opts & args]
    where subcommand syntaxes are as follows:

      init [optional-params] 
        Generate monit config file to current directory. If config file has existed then no generating.
      Options(opt-arg sep :|=|spc):
          -h, --help                  print this cligen-erated help
          --help-syntax               advanced: prepend,plurals,..
          --version      bool  false  print version

      run [optional-params] 
        Run commands on the commands of `file` when file modified.
      Options(opt-arg sep :|=|spc):
          -h, --help                               print this cligen-erated help
          --help-syntax                            advanced: prepend,plurals,..
          --version          bool    false         print version
          -l=, --loopCount=  int     -1            set loopCount
          -f=, --file=       string  ".monit.yml"  A task definition file path
          -v, --verbose      bool    false         Turn ON the debug logging
          -d, --dryRun       bool    false         Not execute commands

## LICENSE

MIT
