PWD := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

UPX ?= $(shell command -v upx 2>/dev/null) # Make sure it is uxp 3.94 or higher (https://github.com/upx/upx/releases)
GOARCH ?= $(shell go env GOARCH)

VERSION = $(shell git describe --tags --dirty 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo git)
BUILDSTAMP = $(shell date -u '+%Y-%m-%dT%T%z')

DIST := $(PWD)/dist
DIST_SRC := $(DIST)/src

FOLDERS = $(shell find -mindepth 1 -maxdepth 1 -type d -not -path "*.git" -not -path "*debian" -not -path "*vendor" -not -path "*doc" -not -path "*bin")

export GO111MODULE=on

all: build

$(DIST_SRC):
	mkdir -p $@

generate: mods client/bindata.go

client/bindata.go: bin/go-bindata
	bin/go-bindata -prefix "client/static/" -pkg client -o client/bindata.go client/static/...

generate-dev: bin/go-bindata
	bin/go-bindata -dev -prefix "client/static/" -pkg client -o client/bindata.go client/static/...

mods: go.mod go.sum
	go mod download
	go mod verify

bin/go-bindata:
	go build -v -o bin/go-bindata github.com/kevinburke/go-bindata/go-bindata

binary-%: mods generate client/bindata.go
	GOOS=linux GOARCH=$(GOARCH) GOARM=$(GOARM) CGO_ENABLED=0 \
		go build \
			-ldflags="-s -w \
				-X main.Version=$(VERSION) \
				-X main.BuildStamp=$(BUILDSTAMP) \
			" \
			-o bin/realtimetrafficd_$(GOARCH) realtimetrafficd/*.go

binary: binary-$(GOARCH)
	cp -va bin/realtimetrafficd_$(GOARCH) bin/realtimetrafficd

build: binary

$(DIST)/realtimetrafficd-$(VERSION)_%: binary-$(GOARCH)
	@mkdir -p $(DIST)
	if [ -n "$(UPX)" ]; then UPX= $(UPX) -f --brute -o $@ bin/realtimetrafficd_$(GOARCH); else cp -va bin/realtimetrafficd_$(GOARCH) $@; fi

release-amd64:
	$(MAKE) GOARCH=amd64 $(DIST)/realtimetrafficd-$(VERSION)_amd64

release-armhf:
	$(MAKE) GOARCH=arm GOARM=7 $(DIST)/realtimetrafficd-$(VERSION)_armhf

release-arm64:
	$(MAKE) GOARCH=arm64 $(DIST)/realtimetrafficd-$(VERSION)_arm64

release: release-amd64 release-armhf release-arm64

format:
	find $(FOLDERS) \( -name "*.go" ! -name "bindata.go" \) -print0 | xargs -0 -n 1 go fmt

.PHONY: all client/bindata.go mods generate-dev binary build release
