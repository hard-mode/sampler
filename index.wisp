(ns sampler (:require [wisp.runtime :refer [= and str]]))

(let [child (require "child_process")
      fs    (require "fs")
      midi  (require "midi")
      osc   (require "node-osc")
      path  (require "path")

      postmelodic "/home/epimetheus/code/hardmode/postmelodic/bin/sample_player"
      osc-port    10000

      sample-path (let [s (path.join __dirname "sounds")]
                    (console.log "\nLooking for sounds in" s)
                    s)

      samples     (try
                    (fs.readdirSync sample-path)
                    (catch e []))

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
                                (jack-connect client))))))))))
                    jack-evmon)

      load-sample (fn load-sample [sample]
                    (let [full-path   (path.join sample-path sample)
                          client-name (sample.substr 0 50)]
                      (set! osc-port (+ 1 osc-port))
                      (child.spawn postmelodic
                        [ full-path
                          "-n" osc-port
                          "-p" osc-port ])
                      (jack-connect osc-port)))

      samples     (let [files (try (fs.readdirSync sample-path)
                                   (catch e []))]
                    (if files.length
                      (do (console.log "Loading sounds...")
                          (files.map load-sample))
                      (do (console.log "Oh zounds! No sounds were found.")
                          nil)))

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
                               (= d2  127)) (do
                        (if (< d1 (- osc-port 10000))
                          (let [osc-port (+ 10000 d1 1)
                                client   (new osc.Client "127.0.0.1" osc-port)]
                            (client.send "/play" 0 0)))))))

      midi-input  (let [m (new midi.input)]
                    (get-launchpad m
                      (fn [port-number]
                        (console.log " IN ::" port-number (m.get-port-name port-number))
                        (m.open-port port-number)
                        (m.on "message" midi-handle)))
                    m)])
