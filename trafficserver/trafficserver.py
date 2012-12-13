#!/usr/bin/python

import tornado.httpserver
import tornado.websocket
import tornado.ioloop
import tornado.web

import os
import sys

try:
    import json
except ImportError:
    import simplejson as json

# Globals
dataGrabbers = {}
dataGrabbed = {}
CLIENT_ROOT = os.path.abspath(os.path.normpath(os.path.join(os.path.dirname(__file__), "..", "client")))


class Grabber(object):

    keys = [
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
    "tx_window_errors"
    ]

    def __init__(self, interface):
        self.interface = interface
        self.base = "/sys/class/net/%s/statistics" % interface

    def grab(self):

        data = {}
        for k in self.keys:
            data[k] = self.read(k)

        dataGrabbed[self.interface]=data

    def read(self, key):
        data = 0
        fn = os.path.join(self.base, key)
        if os.path.exists(fn):
            fp = file(fn, "rb")
            try:
                data = fp.read()
            finally:
                fp.close()
            data = int(data.strip())
        return data


class WSHandler(tornado.websocket.WebSocketHandler):

    dataSender = None
    dataInterface = None

    def open(self):

        interface = self.dataInterface = self.get_argument("if", "eth0").lower()

        grabber = dataGrabbers.get(interface, None)
        if grabber is None:
            # create new grabber
            print >>sys.stdout, "Starting grabber for %s." % interface
            callback = Grabber(interface)
            grabber = tornado.ioloop.PeriodicCallback(callback.grab, 240)
            grabber.start()
            dataGrabbers[interface]=[1, grabber]
        else:
            dataGrabbers[interface][0] = grabber[0]+1

        sender = self.dataSender = tornado.ioloop.PeriodicCallback(self.doSendData, 500)
        sender.start()

    def on_message(self, message):
        pass

    def on_close(self):

        self.dataSender.stop()
        self.dataSender = None

        grabber = dataGrabbers.get(self.dataInterface, None)
        if grabber is not None:
            dataGrabbers[self.dataInterface][0] = grabber[0]-1
            if grabber[0] <= 0:
                print >>sys.stdout, "Stopping grabber for %s." % self.dataInterface
                grabber[1].stop()
                del dataGrabbers[self.dataInterface]

    def doSendData(self):

        data = {
            self.dataInterface: dataGrabbed.get(self.dataInterface, {})
        }
        self.write_message(json.dumps(data))


class ClientHandler(tornado.web.RequestHandler):

    def get(self, filename):

        if not filename or filename == "index.html":
            filename = "realtimetraffic.html"

        fn = os.path.abspath(os.path.join(CLIENT_ROOT, os.path.normpath(filename)))
        if not fn.startswith(CLIENT_ROOT):
            raise tornado.web.HTTPError(404)
        if not os.path.isfile(fn):
            raise tornado.web.HTTPError(404)
        fp = file(fn, "rb")
        try:
            self.write(fp.read())
        finally:
            fp.close()


def main(listen="127.0.0.1:8088"):

    from optparse import OptionParser

    parser = OptionParser()
    parser.add_option("-l", "--listen", dest="listen", help="listen address (default: [%s])" % listen, default=listen)
    parser.add_option("--ssl_keyfile", dest="ssl_keyfile", help="SSL key file", metavar="FILE")
    parser.add_option("--ssl_certfile", dest="ssl_certfile", help="SSL certificate file", metavar="FILE")

    (options, args) = parser.parse_args()

    if ":" in options.listen:
        address, port = options.listen.split(":", 1)
        port = int(port)
        listen = options.listen
    else:
        address = options.listen
        port = 8088
        listen = "%s:%s" % (address, port)

    application = tornado.web.Application([
        (r'^/realtimetraffic$', WSHandler),
        (r'^/css/(.*)$', tornado.web.StaticFileHandler, {'path': os.path.join(CLIENT_ROOT, 'css')}),
        (r'^/scripts/(.*)$', tornado.web.StaticFileHandler, {'path': os.path.join(CLIENT_ROOT, 'scripts')}),
        (r'^/img/(.*)$', tornado.web.StaticFileHandler, {'path': os.path.join(CLIENT_ROOT, 'img')}),
        (r'^/(.*)$', ClientHandler)
    ], debug=False, static_path=CLIENT_ROOT)

    params = {}
    ssl = False
    if options.ssl_keyfile and options.ssl_certfile:
        if not os.path.isfile(options.ssl_keyfile):
            print >>sys.stderr, "SSL key file not found: %s" % options.ssl_keyfile
            return 1
        if not os.path.isfile(options.ssl_certfile):
            print >>sys.stderr, "SSL certificate file not found: %s" % options.ssl_certfile
            return 1
        params["ssl_options"] = {
            "keyfile": options.ssl_keyfile,
            "certfile": options.ssl_certfile
        }
        ssl = True

    http_server = tornado.httpserver.HTTPServer(application, **params)
    http_server.listen(port=port, address=address)
    print >>sys.stdout, "Server running on %s (ssl:%r) ..." % (listen, ssl)
    try:
        tornado.ioloop.IOLoop.instance().start()
    except KeyboardInterrupt:
        pass
    print >>sys.stdout, "Server stopped."
    return 0

if __name__ == "__main__":
    status = main()
    sys.exit(status)


