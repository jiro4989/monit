// a
package main

import (
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"path/filepath"
	"time"

	"github.com/docopt/docopt-go"
	"gopkg.in/yaml.v2"
)

type (
	Target struct {
		Name              string
		Path              string
		Commands          []string
		Extensions        []string
		ExcludeExtensions []string
	}
	MonitorConfig struct {
		Sleep   int
		Targets []Target
	}
	AppConfig struct {
		Command   string
		Target    string
		LoopCount int
		File      string
		Verbose   bool
	}
	ErrorCode int
)

const (
	doc = `monit はファイル変更監視をしてタスクを実行するコマンドです。

Usage:
	saubcal <command> [options]
	saubcal -h | --help
	saubcal -v | --version

Available commands:
	init
	run <target>

Options:
	-h --help                     Print this help.
	-v --version                  Print version.
	-c --loop-count=<COUNT>       Count of monitoring. [default: -1]
	-f --file=<CONFIG_FILE>       Config file of monitoring. [default: .monit.yml]
	-x --verbose                  Print debug log.`
)

const (
	errorCodeOK ErrorCode = iota
	errorCodeFailedBinding
	errorCodeCouldNotReadFile
	errorCodeIllegalMonitorConfig
	errorCodeCouldNotReadDir
)

var (
	targets map[string]time.Time
)

func init() {
	targets = map[string]time.Time{}
}

func main() {
	os.Exit(int(Main(os.Args)))
}

func Main(argv []string) ErrorCode {
	parser := &docopt.Parser{}
	args, _ := parser.ParseArgs(doc, argv[1:], Version)
	config := AppConfig{}
	if err := args.Bind(&config); err != nil {
		fmt.Fprintln(os.Stderr, err)
		return errorCodeFailedBinding
	}

	debug := func(msg interface{}) {
		if config.Verbose {
			fmt.Println(msg)
		}
	}

	debug(config)
	var monitorConfig MonitorConfig
	b, err := ioutil.ReadFile(config.File)
	if err != nil {
		return errorCodeCouldNotReadFile
	}

	if err := yaml.Unmarshal(b, &monitorConfig); err != nil {
		return errorCodeIllegalMonitorConfig
	}
	debug(monitorConfig)

	var loopCount int
	for {
		if 0 < config.LoopCount && config.LoopCount <= loopCount {
			break
		}

		if 0 < config.LoopCount {
			loopCount++
		}

		debug("LoopCount: start " + string(loopCount))
		for _, target := range monitorConfig.Targets {
			files, err := ioutil.ReadDir(target.Path)
			if err != nil {
				return errorCodeCouldNotReadDir
			}

			for _, f := range files {
				fullPath := filepath.Join(target.Path, f.Name())
				debug("TargetFile: " + fullPath)
				var defaultTime time.Time

				// 除外拡張子のファイルはスキップ
				if isExcludeFile(fullPath, target.ExcludeExtensions) {
					continue
				}

				// 拡張子にマッチしないものはスキップ
				if !matchExt(fullPath, target.Extensions) {
					continue
				}

				debug("TargetFile: pass - " + fullPath)

				t := f.ModTime()
				// ゼロ値が返却されたら初めてチェックしたとみなす
				if targets[fullPath] == defaultTime {
					targets[fullPath] = t
					continue
				}
				// 時間が一致するので変更なし
				if targets[fullPath] == t {
					continue
				}

				targets[fullPath] = t
				for _, cmd := range target.Commands {
					debug(fmt.Sprintf(`exec: "%s"`, cmd))
					// エラーが発生しても継続してほしいので無視
					out, _ := exec.Command("bash", "-c", cmd).CombinedOutput()
					fmt.Println(string(out))
				}
			}
		}
		debug("LoopCount: end " + string(loopCount))
		time.Sleep(time.Duration(monitorConfig.Sleep) * time.Second)
	}

	return errorCodeOK
}

func matchExt(name string, exts []string) bool {
	if len(exts) < 1 {
		return true
	}
	if name == "" {
		return false
	}

	// Goが返す拡張子には . が先頭に含まれるので除外
	e := filepath.Ext(name)
	if len(e) < 1 {
		return false
	}
	for _, ext := range exts {
		if e[1:] == ext {
			return true
		}
	}

	return false
}

func isExcludeFile(name string, exts []string) bool {
	if name == "" {
		return true
	}
	if len(exts) < 1 {
		return false
	}

	// Goが返す拡張子には . が先頭に含まれるので除外
	e := filepath.Ext(name)
	if len(e) < 1 {
		return true
	}

	for _, ext := range exts {
		if e[1:] == ext {
			return true
		}
	}
	return false
}
