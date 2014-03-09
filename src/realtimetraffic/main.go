/*
 * Copyright (C) 2014 struktur AG
 * http://www.strukturag.com
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package main

import (
	"flag"
	"log"
	"net/http"
	"os"
	"path"
	"text/template"
)

var templates *template.Template

func serveClient(w http.ResponseWriter, r *http.Request) {
	if r.URL.Path != "/" {
		http.Error(w, "Not found", 404)
		return
	}
	if r.Method != "GET" {
		http.Error(w, "Method nod allowed", 405)
		return
	}
	w.Header().Set("Content-Type", "text/html; charset=utf-8")
	err := templates.ExecuteTemplate(w, "realtimetraffic.html", nil)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
	}
}

func main() {

	var err error

	cwd, _ := os.Getwd()
	client := flag.String("client", path.Join(cwd, "client"), "Full path to client directory.")
	addr := flag.String("listen", "127.0.0.1:8088", "Listen address.")

	templates, err = template.ParseGlob(path.Join(*client, "*.html"))
	if err != nil {
		log.Fatal("Failed to load templates: ", err)
	}

	flag.Parse()
	go h.run()
	http.HandleFunc("/", serveClient)
	http.HandleFunc("/realtimetraffic", serveWs)
	http.Handle("/css/", http.FileServer(http.Dir(*client)))
	http.Handle("/scripts/", http.FileServer(http.Dir(*client)))
	http.Handle("/img/", http.FileServer(http.Dir(*client)))
	http.Handle("/favicon.ico", http.FileServer(http.Dir(*client)))

	err = http.ListenAndServe(*addr, nil)
	if err != nil {
		log.Fatal("ListenAndServe: ", err)
	}

}
