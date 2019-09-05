APPNAME := $(shell basename `pwd`)
VERSION := $(shell git describe --tags --abbrev=0)
LDFLAGS := -a -tags netgo -installsuffix netgo \
	-ldflags="-s -w -extldflags \"-static\""
TARGET_OS := linux darwin windows
TARGET_ARCH := amd64 386
DISTDIR := dist
README := README.*
LICENSE := LICENSE
BINDIR := bin
BINAPP := $(BINDIR)/$(APPNAME)

.PHONY: help
help: ## ドキュメントのヘルプを表示する。
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: build
build: ## ビルド
	go build -o $(BINAPP) .

.PHONY: install
install: ## インストール
	go install

.PHONY: xbuild
xbuild: ## クロスコンパイル
	for os in $(TARGET_OS); do \
		for arch in $(TARGET_ARCH); do \
			out="$(DISTDIR)/$(APPNAME)$(VERSION)_$${os}_$${arch}/$(BINAPP)"; \
			GOOS=$$os GOARCH=$$arch go build $(LDFLAGS) -o $$out . ; \
		done \
	done

.PHONY: archive
archive: clean xbuild ## クロスコンパイルしたバイナリとREADMEを圧縮する
	find $(DISTDIR)/ -mindepth 1 -maxdepth 1 -a -type d \
		| while read -r d; \
		do \
			cp $(README) $$d/ ; \
			cp $(LICENSE) $$d/ ; \
		done
	cd $(DISTDIR) && \
		find . -maxdepth 1 -mindepth 1 -a -type d  \
		| while read -r d; \
		do \
			if [[ $$d =~ .*windows.* ]]; then \
				zip -r $$d.zip $$d; \
			else \
				tar czf $$d.tar.gz $$d; \
			fi; \
		done

.PHONY: test
test: ## テストコードを実行する
	go test -cover ./...

.PHONY: clean
clean: ## バイナリ、配布物ディレクトリを削除する
	-rm -rf $(BINDIR)
	-rm -rf $(DISTDIR)
