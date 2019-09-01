package main

import (
	"fmt"
	"io/ioutil"

	"gopkg.in/yaml.v2"
)

type (
	Target struct {
		Name       string
		Path       string
		Commands   []string
		Extensions []string
	}
	Monitrc struct {
		Targets []Target
	}
)

func main() {
	var monitrc Monitrc

	b, err := ioutil.ReadFile(".monitrc")
	if err != nil {
		panic(err)
	}

	if err := yaml.Unmarshal(b, &monitrc); err != nil {
		panic(err)
	}

	fmt.Println(monitrc)
}
