# monit

`monit` is the simple task runner.
Run tasks and watch file changes with custom paths.

## Usage

`monit` run commands when a modified timestamp of file has changed.
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

## Installation

```bash
nimble install monit
```

## Development

    % nim -v
    Nim Compiler Version 0.20.2 [Linux: amd64]
    Compiled at 2019-07-17
    Copyright (c) 2006-2019 by Andreas Rumpf

    git hash: 88a0edba4b1a3d535b54336fd589746add54e937
    active boot switches: -d:release

    % nimble -v
    nimble v0.10.2 compiled at 2019-08-11 10:07:38
    git hash: couldn't determine git hash

## Help

TODO

## LICENSE

MIT
