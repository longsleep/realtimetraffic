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

(function() {

    var add = function(a, b) {
        return a+b;
    }

    var RealtimeTraffic = function() {

        this.tv = 1000;
        this.last_data = null;
        this.history = {
            rx_bytes: [],
            tx_bytes: []
        };
        this.connection = null;
        this.initialize();

    }

    RealtimeTraffic.prototype.initialize = function() {

        var graph = this.graph = new Rickshaw.Graph( {
            element: document.getElementById("chart"),
            height: 300,
            width: 690,
            renderer: "multi",
            interpolation: "cardinal",
            series: new Rickshaw.Series.FixedDuration([
                { name: 'rx_tx_abs_diff', color: "wheat", renderer: "bar", disabled: true },
                { name: 'rx_tx_combined', color: "mistyrose", renderer: "line" },
                { name: 'rx_kbits', color: "mediumslateblue", renderer: "line" },
                { name: 'tx_kbits', color: "lightcoral", renderer: "line" },
            ], undefined, {
                timeInterval: this.tv,
                maxDataPoints: 100,
                timeBase: new Date().getTime() / 1000
            })
        } );

        var xAxis = new Rickshaw.Graph.Axis.Time({
            graph: graph
        });

        var yAxis = new Rickshaw.Graph.Axis.Y({
            graph: graph,
            tickFormat: Rickshaw.Fixtures.Number.formatKMBT
        });

        var legend = new Rickshaw.Graph.Legend({
            graph: graph,
            element: document.getElementById('legend')
        });

        var hoverDetail = new Rickshaw.Graph.HoverDetail({
            graph: graph
        });

        var smoother = new Rickshaw.Graph.Smoother({
            graph: graph,
            element: document.getElementById('smoother')
        });

        var shelving = new Rickshaw.Graph.Behavior.Series.Toggle({
            graph: graph,
            legend: legend
        });

        this.graph.render();

    };

    RealtimeTraffic.prototype.disconnect = function() {

        if (this.connection) {
            this.connection.close();
            this.connection = this.last_data = null;
            this.needsReset = true;
        }

    };

    RealtimeTraffic.prototype.connect = function(url, interf) {

        var ws_url = url+'?if='+interf;

        this.disconnect();

        if (this.needsReset) {
            $("#chart").empty();
            $("#legend").empty();
            this.initialize();
        }

        var connection;
        var that = this;

        console.info("Connecting to " + ws_url);
        try {
            connection = this.connection = new WebSocket(ws_url);
        } catch(e) {
            console.error("Failed to create websocket connection to " + ws_url, e);
            alert("Failed to connect. See console for details.");
            return;
        }

        connection.onopen = function () {
            // do nothing
            console.info("Connection established.");
            $(that).triggerHandler("open");
        };

        connection.onclose = function() {
            console.info("Connection closed.");
            $(that).triggerHandler("close");
        };

        // Log errors
        connection.onerror = function (error) {
            console.error('WebSocket error ' + error);
            alert("Connection error. See console for details.");
        };

        connection.onmessage = function(e) {
            var data = JSON.parse(e.data);
            var interface_data = data[data.name];
            if (typeof(interface_data) !== "undefined") {
                if (that.last_data !== null) {
                    that.history.rx_bytes.push(interface_data.rx_bytes - that.last_data.rx_bytes);
                    that.history.tx_bytes.push(interface_data.tx_bytes - that.last_data.tx_bytes);
                    var d = {
                        rx_kbits: (that.history.rx_bytes.reduce(add, 0) / that.history.rx_bytes.length) * 8 / 1024,
                        tx_kbits: (that.history.tx_bytes.reduce(add, 0) / that.history.tx_bytes.length) * 8 / 1024
                    };
                    d.rx_tx_combined = d.rx_kbits + d.tx_kbits;
                    d.rx_tx_abs_diff = Math.abs(d.rx_kbits - d.tx_kbits);
                    if (that.history.rx_bytes.length >= 5) {
                        that.history.rx_bytes.shift();
                    }
                    if (that.history.tx_bytes.length >= 5) {
                        that.history.tx_bytes.shift();
                    }
                    setTimeout(function() {
                        that.graph.series.addData(d);
                        that.graph.render();
                    }, 0);
                }
                that.last_data = interface_data;
            }
        };

    };

$(document).ready(function() {

    var control = $("#control");
    var input_url = $("#input_url");
    var input_interf = $("#input_interf");
    var button_start = $("button.start", control);
    var button_stop = $("button.stop", control);

    var url;
    var interf;

    // Read defaults from params or localStorage
    var params = jQuery.deparam.querystring();
    if (params.url || params.interf) {
        url = $.trim(params.url);
        interf = $.trim(params.interf);
    } else if (Modernizr.localstorage) {
        url = localStorage.getItem("org.longsleep.realtimetraffic.defaults.url");
        interf = localStorage.getItem("org.longsleep.realtimetraffic.defaults.interf");
    }


    // compute default URL based on current URL.
    if (!url) {
        if (/^((http|https):\/\/)/i.test(window.location.href)) {
            if (/^(https:\/\/)/i.test(window.location.href)) {
                url = "wss://"+window.location.host+"/realtimetraffic";
            } else {
                url = "ws://"+window.location.host+"/realtimetraffic";
            }
        }
    }

    if (url) {
        input_url.val(url);
    }
    if (interf) {
        input_interf.val(interf);
    }

    if (!Modernizr.websockets || !Modernizr.svg) {
        $("button").prop("disabled", true);
        alert("Your browser seems to lack required features to run this application. Launch aborted.");
        return;
    }

    var realtimetraffic = new RealtimeTraffic();
    $(realtimetraffic).on("open", function() {
        control.addClass("connected");
    });
    $(realtimetraffic).on("close", function() {
        control.removeClass("connected");
    });

    button_start.on("click", function() {

        url = $.trim(input_url.val());
        interf = $.trim(input_interf.val());

        if (!url || !interf) {
            return;
        }

        realtimetraffic.connect(url, interf);

        if (Modernizr.localstorage) {
            try {
                localStorage.setItem("org.longsleep.realtimetraffic.defaults.url", url);
                localStorage.setItem("org.longsleep.realtimetraffic.defaults.interf", interf);
            } catch(e) {
                console.warn("Failed to store settings into localStorage with error " + e);
            }
        }

    });

    button_stop.on("click", function() {

        realtimetraffic.disconnect();

    });

    if (params.autostart === "1") {
        button_start.click();
    }

});

}());
