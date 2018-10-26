/*
 * Copyright (C) 2018 Simon Eisenmann
 * Copyright (C) 2014-2017 struktur AG
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
	"fmt"
	"log"
	"net/http"
	"runtime"

	"github.com/longsleep/realtimetraffic/client"

	"github.com/gorilla/websocket"
)

func serveClient(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" && r.Method != "HEAD" {
		http.Error(w, "Method nod allowed", 405)
		return
	}

	http.StripPrefix("/", client.HandlerFunc).ServeHTTP(w, r)
}

func serveWs(w http.ResponseWriter, r *http.Request) {
	if r.Method != "GET" {
		http.Error(w, "Method not allowed", 405)
		return
	}

	// Read request details.
	r.ParseForm()
	iface := r.FormValue("if")
	if iface == "" {
		iface = "eth0"
	}

	ws, err := websocket.Upgrade(w, r, nil, 1024, 1024)
	if _, ok := err.(websocket.HandshakeError); ok {
		http.Error(w, "Not a websocket handshake", 400)
		return
	} else if err != nil {
		log.Println(err)
		return
	}
	c := &connection{send: make(chan []byte, 256), ws: ws, iface: iface}
	h.register <- c
	go c.writePump()
	c.readPump()
}

func main() {
	var err error

	listenAddr := flag.String("listen", "127.0.0.1:8088", "Listen address.")
	versionFlag := flag.Bool("version", false, "Version")
	flag.Parse()

	if *versionFlag {
		fmt.Println("Version    :", Version)
		fmt.Println("Build time :", BuildStamp)
		fmt.Println("Go         :", runtime.Version())
		return
	}

	go h.run()
	http.HandleFunc("/", serveClient)
	http.HandleFunc("/realtimetraffic", serveWs)

	log.Printf("starting realtimetrafficd %s on %sn", Version, *listenAddr)
	err = http.ListenAndServe(*listenAddr, nil)
	if err != nil {
		log.Fatal(err.Error())
	}

	defer log.Println("exiting")
}
