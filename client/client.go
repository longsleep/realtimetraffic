package client

import (
	"net/http"

	"github.com/elazarl/go-bindata-assetfs"
)

//go:generate go-bindata -prefix "static/" -pkg client -o bindata.go static/...

func handler(w http.ResponseWriter, r *http.Request) {
	http.FileServer(
		&assetfs.AssetFS{
			Asset:     Asset,
			AssetDir:  AssetDir,
			AssetInfo: AssetInfo,
			Prefix:    "/",
		},
	).ServeHTTP(w, r)
}

var HandlerFunc http.HandlerFunc = handler
