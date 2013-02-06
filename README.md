# Realtime Traffic

Realtime Traffic is a Linux realtime trafic monitoring tool, graphing rx and tx of a Linux network interface in realtime to any modern web browser supporting WebSockets and SVG, developed at [struktur AG](http://www.strukturag.com)

![Screenshot](//longsleep/realtimetraffic/raw/master/doc/screen4.png "Example Screenshot")

## Installation

Dowload the software, either using Git, or grab a [ZIP](https://github.com/longsleep/realtimetraffic/archive/master.zip) and extract it somewhere.

You can use the client right away without installation. Just open the file client/realtimetraffic.html in any modern browser, type in a WebSocket address of a server you started somewhere and press start.

To install the server, make sure you have [Python](http://www.python.org) (2.5, 2.6, 2.7 tested) and [tornado](http://pypi.python.org/pypi/tornado). For Python << 2.6 you also need [simplejson](http://pypi.python.org/pypi/simplejson). Then just startup the server.

On Ubuntu this is simple like this:

    $ wget -O rtt.zip https://github.com/longsleep/realtimetraffic/archive/master.zip
    $ unzip rtt.zip
    $ cd realtimetraffic-master
    $ sudo apt-get install python-tornado
    $ python trafficserver/trafficserver.py
    Server running on 127.0.0.1:8088 (ssl:False) ...

Now just open up your browser:

    $ firefox http://127.0.0.1:8088/?autostart=1

## Getting Started

Startup the traffice server on a Linux machine of your choice.

    $ python trafficserver/trafficserver.py

And open up the server's web page (http://yourserver:8088/).

See the usage information (--help) for options.

## Server usage options

The trafficserver is basically a Websocket server pushing traffic data to any connected client.

```
Usage: trafficserver.py [options]

Options:
  -h, --help            show this help message and exit
  -l LISTEN, --listen=LISTEN
                        listen address (default: [127.0.0.1:8088])
  --ssl_keyfile=FILE    SSL key file
  --ssl_certfile=FILE   SSL certificate file
```

## Client parameters

The client default parameters can be configured by URL query parameters.

```
url         The trafficserver Websocket URL.
interf      Inteface Name to capture the traffic (default eth0).
autostart   Automatically connect to server on launch.
```

## Authors

This library was developed by Simon Eisenmann at [struktur AG](http://www.strukturag.com)

## License

Copyright (C) 2012 struktur AG

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

