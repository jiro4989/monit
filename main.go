// a
package main

import (
	"fmt"
	"io/ioutil"
	"os/exec"
	"path/filepath"
	"time"

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
	Config struct {
		Sleep   int
		Targets []Target
	}
)

var (
	targets map[string]time.Time
)

func init() {
	targets = map[string]time.Time{}
}

func main() {
	var config Config

	b, err := ioutil.ReadFile(".monit.yml")
	if err != nil {
		panic(err)
	}

	if err := yaml.Unmarshal(b, &config); err != nil {
		panic(err)
	}

	var i int
	for {
		i++
		fmt.Println(fmt.Sprintf("** %d回目 **", i))

		for _, target := range config.Targets {
			fmt.Println("[suite] " + target.Name)

			files, err := ioutil.ReadDir(target.Path)
			if err != nil {
				panic(err)
			}

			for _, f := range files {
				fullPath := filepath.Join(target.Path, f.Name())
				var defaultTime time.Time

				// 除外拡張子のファイルはスキップ
				if isExcludeFile(fullPath, target.ExcludeExtensions) {
					continue
				}

				// 拡張子にマッチしないものはスキップ
				if !matchExt(fullPath, target.Extensions) {
					continue
				}

				t := f.ModTime()
				// ゼロ値が返却されたら初めてチェックしたとみなす
				if targets[fullPath] == defaultTime {
					targets[fullPath] = t
					continue
				}
				// 時間が一致するので変更なし
				if targets[fullPath] == t {
					fmt.Println(fmt.Sprintf("%s was not changed.", fullPath))
					continue
				}

				fmt.Println(fmt.Sprintf("%s was changed.", fullPath))
				targets[fullPath] = t
				for _, cmd := range target.Commands {
					// エラーが発生しても継続してほしいので無視
					out, _ := exec.Command("bash", "-c", cmd).CombinedOutput()
					fmt.Println(string(out))
				}
			}
		}
		time.Sleep(time.Duration(config.Sleep) * time.Second)
	}
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
