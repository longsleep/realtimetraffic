
PKG := realtimetraffic
EXENAME := realtimetraffic

GOPATH = "$(CURDIR)/vendor:$(CURDIR)"
SYSTEM_GOPATH := /usr/share/gocode/src/
OUTPUT := $(CURDIR)/bin

DESTDIR ?= /
BIN := $(DESTDIR)/usr/sbin
CONF := $(DESTDIR)/$(CONFIG_PATH)

BUILD_ARCH := $(shell go env GOARCH)
DIST := $(CURDIR)/dist_$(BUILD_ARCH)
DIST_SRC := $(DIST)/src
DIST_BIN := $(DIST)/bin

build: get binary

gopath:
		@echo GOPATH=$(GOPATH)

get:
		GOPATH=$(GOPATH) go get $(PKG)

binary:
		GOPATH=$(GOPATH) go build -o $(OUTPUT)/$(EXENAME) -ldflags '$(LDFLAGS)' $(PKG)

binaryrace:
		GOPATH=$(GOPATH) go build -race -o $(OUTPUT)/$(EXENAME) -ldflags '$(LDFLAGS)' $(PKG)

fmt:
		GOPATH=$(GOPATH) go fmt $(PKG)/...

test: TESTDEPS = $(shell GOPATH=$(GOPATH) go list -f '{{.ImportPath}}{{"\n"}}{{join .Deps "\n"}}' $(PKG) |grep $(PKG))
test: get
		GOPATH=$(GOPATH) go test -i $(TESTDEPS)
		GOPATH=$(GOPATH) go test -v $(TESTDEPS)

clean:
		GOPATH=$(GOPATH) go clean -i $(PKG)
		rm -rf $(CURDIR)/pkg

distclean: clean
		rm -rf $(DIST)

pristine: distclean
		rm -rf vendor/*

$(DIST_SRC):
		mkdir -p $@

$(DIST_BIN):
		mkdir -p $@

dist_gopath: $(DIST_SRC)
		find $(SYSTEM_GOPATH) -mindepth 1 -maxdepth 1 -type d \
				-exec ln -sf {} $(DIST_SRC) \;

.PHONY: clean distclean pristine get build gopath binary
