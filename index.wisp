(ns sampler (:require [wisp.runtime :refer [= and str]]))

(let [child (require "child_process")
      fs    (require "fs")
      midi  (require "midi")
      osc   (require "node-osc")
      path  (require "path")

      ; settings

      osc-port    10000
      postmelodic "/home/epimetheus/code/hardmode/postmelodic/bin/sample_player"
      kit         "kits/ultra.json"
      pads        [[0  1]  [2  3]  [4  5]  [6  7]
                   [16 17] [18 19] [20 21] [22 23]]

      ; controllers

      get-launchpad (fn [m connect-fn]
                      (let [port-count (m.get-port-count)]
                        (loop [port-number 0]
                          (if (< port-number port-count)
                            (let [port-name (m.get-port-name port-number)]
                              (if (= 0 (port-name.index-of "Launchpad"))
                                (connect-fn port-number)
                                (recur (+ port-number 1))))))))

      midi-output (let [m (new midi.output)]
                    (get-launchpad m
                      (fn [port-number]
                        (console.log "OUT ::" port-number (m.get-port-name port-number))
                        (m.open-port port-number)))
                    m)

      midi-handle (fn [dt message]
                    (let [msg (aget message 0)
                          d1  (aget message 1)
                          d2  (aget message 2)]
                      (if (and (= msg 144)
                               (= d2  127))
                        (pads.map (fn [pad]
                          (if (not (= -1 (pad.indexOf d1)))
                            (let [client (new osc.Client "127.0.0.1"
                                           (+ 10000 (pads.indexOf pad)))]
                              (client.send "/play" 0 0))))))))

      midi-input  (let [m (new midi.input)]
                    (get-launchpad m
                      (fn [port-number]
                        (console.log " IN ::" port-number (m.get-port-name port-number))
                        (m.open-port port-number)
                        (m.on "message" midi-handle)))
                    m)

      ; sound player

      sample-path (let [s (path.resolve kit)]
                    (console.log "\nOpening kit" s)
                    s)

      jack-connect  (fn [client]
                      (let [port (str client ":output")]
                        (child.spawn "jack_connect" [ port "system:playback_1" ])
                        (child.spawn "jack_connect" [ port "system:playback_2" ])))

      jack-events (let [jack-evmon (child.spawn "jack_evmon")]
                    (jack-evmon.stdout.set-encoding "utf8")
                    (jack-evmon.stdout.on "data" (fn [d]
                      (let [d     (d.to-string)
                            lines (d.split "\n")]
                        (lines.map (fn [line]
                          (let [match (line.match "Client (.+) registered")]
                            (if match (let [client (aget match 1)]
                              (if (= -1 (client.index-of "jack_connect"))
                                (console.log client)
                                (jack-connect client))))))))))
                    jack-evmon)

      load-sample (fn load-sample [sample]
                    (let [client-name (sample.substr 0 50)
                          sample-nr   (- osc-port 10000)
                          sampler     (child.spawn postmelodic
                                        [ "-n" osc-port
                                          "-p" osc-port
                                          sample ] )]
                                        ;{ :stdio "inherit"})]
                      (console.log "\n" osc-port client-name sample)
                      (.map (aget pads sample-nr) (fn [pad]
                        (midi-output.send-message [144 pad (- 127 sample-nr)])))
                      (set! osc-port (+ 1 osc-port))))

      load-samples  (let [kit (try (JSON.parse (fs.readFileSync
                                     sample-path { :encoding "utf8" }))
                                   (catch e { :root   ""
                                              :sounds [] }))]
                      (if (.-length (or kit.sounds []))
                        (do (console.log "Loading sounds...")
                            (kit.sounds.map (fn [sample] (load-sample
                              (path.resolve (path.join kit.root sample))))))
                        (do (console.log "Oh zounds! No sounds were found.")
                            nil)))

      ;gui         (require "ui-hypertext")

      ;http-server (gui.server 4000 (gui.page "/" ""))

])
