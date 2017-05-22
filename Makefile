PWD := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))

GOPKG = github.com/longsleep/realtimetraffic
GOPATH = "$(CURDIR)/vendor:$(CURDIR)"
SYSTEM_GOPATH = /usr/share/gocode/src/

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

goget:
#	if [ -z "$(DEB_BUILDING)" ]; then GOPATH=$(GOPATH) go get github.com/rogpeppe/godeps; fi
#	if [ -z "$(DEB_BUILDING)" ]; then GOPATH=$(GOPATH) $(CURDIR)/vendor/bin/godeps -u dependencies.tsv; fi
	mkdir -p $(shell dirname "$(CURDIR)/vendor/src/$(GOPKG)")
	rm -f $(CURDIR)/vendor/src/$(GOPKG)
	ln -sf $(PWD) $(CURDIR)/vendor/src/$(GOPKG)

generate:
	if [ -z "$(DEB_BUILDING)" ]; then GOPATH=$(GOPATH) go get github.com/jteeuwen/go-bindata/...; fi
	if [ -z "$(DEB_BUILDING)" ]; then GOPATH=$(GOPATH) $(CURDIR)/vendor/bin/go-bindata -prefix "client/static/" -pkg client -o client/bindata.go client/static/...; fi

generate-dev:
	GOPATH=$(GOPATH) $(CURDIR)/vendor/bin/go-bindata -dev -prefix "client/static/" -pkg client -o client/bindata.go client/static/...; fi

binary: generate
	GOPATH=$(GOPATH) go build -o bin/realtimetrafficd realtimetrafficd/*.go

build: goget binary

format:
	find $(FOLDERS) \( -name "*.go" ! -name "bindata.go" \) -print0 | xargs -0 -n 1 go fmt

dependencies.tsv:
	set -e ;\
	TMP=$$(mktemp -d) ;\
	cp -r $(CURDIR)/vendor $$TMP ;\
	GOPATH=$$TMP/vendor:$(CURDIR) $(CURDIR)/vendor/bin/godeps $(GOPKG)/wlan > $(CURDIR)/dependencies.tsv ;\
	rm -rf $$TMP ;\

.PHONY: all dist_gopath goget generate generate-dev binary dependencies.tsv
