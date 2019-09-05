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

func TestIsExcludeFile(t *testing.T) {
	tests := []struct {
		desc   string
		inName string
		inExts []string
		want   bool
	}{
		{desc: "Goファイルを除外", inName: "main.go", inExts: []string{"go"}, want: true},
		{desc: "GoとCファイルを除外", inName: "main.go", inExts: []string{"go", "c"}, want: true},
		{desc: "GoとCファイルを除外", inName: "main.go", inExts: []string{"c", "go"}, want: true},
		{desc: "除外ファイルがマッチしない", inName: "main.go", inExts: []string{"java"}, want: false},
		{desc: "除外ファイル未指定の場合は常にfalse", inName: "main.go", inExts: []string{}, want: false},
		{desc: "対象ファイルが空の場合は常にtrue", inName: "", inExts: []string{"go"}, want: true},
	}
	for _, tt := range tests {
		t.Run(tt.desc, func(t *testing.T) {
			got := isExcludeFile(tt.inName, tt.inExts)
			assert.Equal(t, tt.want, got, tt.desc)
		})
	}
}
