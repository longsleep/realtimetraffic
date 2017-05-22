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

type hub struct {
	grabbers    map[string]*grabber
	connections map[*connection]bool
	broadcast   chan *interfacedata
	register    chan *connection
	unregister  chan *connection
}

var h = hub{
	broadcast:   make(chan *interfacedata),
	register:    make(chan *connection),
	unregister:  make(chan *connection),
	connections: make(map[*connection]bool),
	grabbers:    make(map[string]*grabber),
}

func (h *hub) run() {

	var eg *grabber
	var ok bool

	for {
		select {
		case c := <-h.register:
			h.connections[c] = true
			if eg, ok = h.grabbers[c.iface]; !ok {
				eg = newGrabber(c.iface)
				h.grabbers[c.iface] = eg
			}
			eg.start()
		case c := <-h.unregister:
			delete(h.connections, c)
			close(c.send)
			if eg, ok = h.grabbers[c.iface]; ok {
				eg.stop()
			}
		case d := <-h.broadcast:
			for c := range h.connections {
				if c.iface == d.iface {
					if m, err := d.encode(); err == nil {
						select {
						case c.send <- m:
						default:
							close(c.send)
							delete(h.connections, c)
						}
					}
				}
			}
		}
	}
}
