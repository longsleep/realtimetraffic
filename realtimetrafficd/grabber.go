/*
 * Copyright (C) 2014-2017 struktur AG
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
	"fmt"
	"log"
	"os"
	"path"
	"strconv"
	"strings"
	"time"
)

var grabkeys = []string{
	"collisions",
	"multicast",
	"rx_bytes",
	"rx_compressed",
	"rx_crc_errors",
	"rx_dropped",
	"rx_errors",
	"rx_fifo_errors",
	"rx_frame_errors",
	"rx_length_errors",
	"rx_missed_errors",
	"rx_over_errors",
	"rx_packets",
	"tx_aborted_errors",
	"tx_bytes",
	"tx_carrier_errors",
	"tx_compressed",
	"tx_dropped",
	"tx_errors",
	"tx_fifo_errors",
	"tx_heartbeat_errors",
	"tx_packets",
	"tx_window_errors",
}

type grabber struct {
	path    string
	iface   string
	quit    chan bool
	running bool
	count   uint
}

func newGrabber(iface string) *grabber {
	return &grabber{
		iface: iface,
		path:  fmt.Sprintf("/sys/class/net/%s/statistics", iface),
	}
}

func (g *grabber) grab() {

	data := &interfacedata{}
	statistics := map[string]interface{}{}
	value := make([]byte, 100)

	var file *os.File
	var err error
	for _, key := range grabkeys {
		file, err = os.Open(path.Join(g.path, key))
		if err == nil {
			count, err := file.Read(value)
			if err == nil {
				statistics[key], err = strconv.ParseInt(strings.TrimSpace(string(value[:count])), 10, 64)
				if err != nil {
					log.Println("Failed to process data", err, value[:count], count)
				}
			} else {
				log.Println("Failed to read data", err)
			}
			file.Close()
		} else {
			log.Println("Failed to load data", err)
		}
	}

	data.set(g.iface, statistics)
	h.broadcast <- data

}

func (g *grabber) start() {

	g.count++
	if g.running {
		return
	}

	g.quit = make(chan bool)
	g.running = true

	go func() {
		fmt.Printf("Grabbing started: %s\n", g.iface)
		ticker := time.NewTicker(1000 * time.Millisecond)
		for {
			select {
			case <-ticker.C:
				g.grab()
			case <-g.quit:
				ticker.Stop()
				return
			}
		}
	}()

}

func (g *grabber) stop() {

	if !g.running {
		return
	}

	g.count--
	if g.count == 0 {
		g.running = false
		close(g.quit)
		fmt.Printf("Grabbing stopped: %s\n", g.iface)
	}

}
