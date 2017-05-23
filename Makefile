PWD := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

UPX ?= $(shell command -v upx 2>/dev/null) # Make sure it is uxp 3.94 or higher (https://github.com/upx/upx/releases)
GOARCH ?= $(shell go env GOARCH)

GOPKG = github.com/longsleep/realtimetraffic
GOPATH = "$(CURDIR)/vendor:$(CURDIR)"
SYSTEM_GOPATH = /usr/share/gocode/src/
VERSION = $(shell git describe --tags --dirty 2>/dev/null || git rev-parse --short HEAD 2>/dev/null || echo git)
BUILDSTAMP = $(shell date -u '+%Y-%m-%dT%T%z')

DIST := $(PWD)/dist
DIST_SRC := $(DIST)/src

FOLDERS = $(shell find -mindepth 1 -maxdepth 1 -type d -not -path "*.git" -not -path "*debian" -not -path "*vendor" -not -path "*doc" -not -path "*bin")

all: build

$(DIST_SRC):
	mkdir -p $@

dist_gopath: $(DIST_SRC)
	if [ -d "$(SYSTEM_GOPATH)" ]; then find $(SYSTEM_GOPATH) -mindepth 1 -maxdepth 1 -type d \
		-exec ln -sf {} $(DIST_SRC) \; ; fi
	if [ ! -d "$(SYSTEM_GOPATH)" ]; then find $(CURDIR)/vendor/src -mindepth 1 -maxdepth 1 -type d \
		-exec ln -sf {} $(DIST_SRC) \; ; fi

godeps:
	if [ -z "$(DEB_BUILDING)" ]; then GOPATH=$(GOPATH) go get github.com/rogpeppe/godeps; fi

goget: godeps
	if [ -z "$(DEB_BUILDING)" ]; then GOPATH=$(GOPATH) $(CURDIR)/vendor/bin/godeps -u dependencies.tsv; fi
	mkdir -p $(shell dirname "$(CURDIR)/vendor/src/$(GOPKG)")
	rm -f $(CURDIR)/vendor/src/$(GOPKG)
	ln -sf $(PWD) $(CURDIR)/vendor/src/$(GOPKG)

generate:
	if [ -z "$(DEB_BUILDING)" ]; then GOPATH=$(GOPATH) go get github.com/jteeuwen/go-bindata/...; fi
	if [ -z "$(DEB_BUILDING)" ]; then GOPATH=$(GOPATH) $(CURDIR)/vendor/bin/go-bindata -prefix "client/static/" -pkg client -o client/bindata.go client/static/...; fi

generate-dev:
	GOPATH=$(GOPATH) $(CURDIR)/vendor/bin/go-bindata -dev -prefix "client/static/" -pkg client -o client/bindata.go client/static/...; fi

binary-%: generate
	GOPATH=$(GOPATH) GOOS=linux GOARCH=$(GOARCH) GOARM=$(GOARM) CGO_ENABLED=0 \
		go build \
			-ldflags="-s -w \
				-X main.Version=$(VERSION) \
				-X main.BuildStamp=$(BUILDSTAMP) \
			" \
			-o bin/realtimetrafficd-$(GOARCH) realtimetrafficd/*.go

binary: binary-$(GOARCH)
	mv bin/realtimetrafficd-$(GOARCH) bin/realtimetrafficd

build: goget binary

$(DIST)/realtimetrafficd-%: binary-$(GOARCH)
	@mkdir -p $(DIST)
	if [ -n "$(UPX)" ]; then UPX= $(UPX) -f --brute -o $@ bin/realtimetrafficd-$(GOARCH); else cp -v bin/realtimetrafficd-$(GOARCH) $@; fi

release-amd64:
	$(MAKE) GOARCH=amd64 $(DIST)/realtimetrafficd-amd64

release-armhf:
	$(MAKE) GOARCH=arm GOARM=7 $(DIST)/realtimetrafficd-armhf

release-arm64:
	$(MAKE) GOARCH=arm64 $(DIST)/realtimetrafficd-arm64

release: release-amd64 release-armhf release-arm64

format:
	find $(FOLDERS) \( -name "*.go" ! -name "bindata.go" \) -print0 | xargs -0 -n 1 go fmt

dependencies.tsv: godeps
	set -e ;\
	TMP=$$(mktemp -d) ;\
	cp -r $(CURDIR)/vendor $$TMP ;\
	GOPATH=$$TMP/vendor:$(CURDIR) $(CURDIR)/vendor/bin/godeps $(GOPKG)/realtimetrafficd > $(CURDIR)/dependencies.tsv ;\
	rm -rf $$TMP ;\

.PHONY: all dist_gopath godeps goget generate generate-dev binary dependencies.tsv build release
