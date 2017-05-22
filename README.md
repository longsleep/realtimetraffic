# Realtime Traffic

Realtime Traffic is a Linux realtime trafic monitoring tool, graphing rx and tx of a Linux network interface in realtime to any modern web browser supporting WebSockets and SVG, developed at [struktur AG](http://www.strukturag.com)

![Screenshot](https://github.com/longsleep/realtimetraffic/raw/master/doc/screen4.png "Example Screenshot")

## Installation

Dowload the software, either using Git, or grab a [ZIP](https://github.com/longsleep/realtimetraffic/archive/master.zip) and extract it somewhere.

Getting started:

    $ wget -O rtt.zip https://github.com/longsleep/realtimetraffic/archive/master.zip
    $ unzip rtt.zip
    $ cd realtimetraffic-master
    $ make
    $ ./bin/realtimetrafficd

Now just open up your browser:

    $ firefox http://127.0.0.1:8088/?autostart=1

See the usage information (-h) for options.

## Server usage options

The trafficserver is basically a Websocket server pushing traffic data to any connected client.

```
Usage of ./bin/realtimetrafficd:
  -listen="127.0.0.1:8088": Listen address.
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

Copyright (C) 2012-2017 struktur AG

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
