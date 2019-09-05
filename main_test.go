package main

import (
	"fmt"
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestMain(t *testing.T) {
	fmt.Println("ok")
}

func TestMatchExt(t *testing.T) {
	tests := []struct {
		desc   string
		inName string
		inExts []string
		want   bool
	}{
		{desc: "Goファイル", inName: "main.go", inExts: []string{"go"}, want: true},
		{desc: "GoとCファイル", inName: "main.go", inExts: []string{"go", "c"}, want: true},
		{desc: "GoとCファイル", inName: "main.c", inExts: []string{"go", "c"}, want: true},
		{desc: "Goファイル (不一致)", inName: "main.go", inExts: []string{"c"}, want: false},
		{desc: "拡張子未指定の時は常にtrue", inName: "main.go", inExts: []string{}, want: true},
		{desc: "ファイル名が空の時は常にfalse", inName: "", inExts: []string{"go"}, want: false},
	}
	for _, tt := range tests {
		t.Run(tt.desc, func(t *testing.T) {
			got := matchExt(tt.inName, tt.inExts)
			assert.Equal(t, tt.want, got, tt.desc)
		})
	}
}
