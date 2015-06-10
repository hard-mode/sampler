(ns sample (:require [wisp.runtime :refer [str =]]))

(def ^:private event2 (require "eventemitter2"))
(def ^:private jack   (require "../lib/jack.wisp"))
(def ^:private osc    (require "../lib/osc.wisp"))
(def ^:private path   (require "path"))

(def postmelodic "/home/epimetheus/code/hardmode/postmelodic/bin/sample_player")

(def ^:private next-player 0)
(defn get-next-player []
  (set! next-player (+ next-player 1))
  (- next-player 1))

(set! persist.postmelodic (or persist.postmelodic {}))

(defn player
  ([sample]
    (player sample sample))
  ([jack-client-name sample]
    (or (aget persist.postmelodic jack-client-name)
      (let [sample-nr         (get-next-player)

            osc-port          (osc.get-next-port)

            osc-send          (osc.bind-to osc-port)

            jack-port-name    (str jack-client-name ":output")

            jack-client       (jack.client jack-client-name)

            spawn-key         (str module.filename
                                ":" (if process.main process.main.filename nil)
                                ":" jack-client-name)

            events             (event2.EventEmitter2.)

            state
            { :client  jack-client
              :process nil
              :started jack-client.started
              :port    jack-client.port
              :events  events

              :play    (fn [cue]    (osc-send "/play" 0 (or cue 0)))
              :stop    (fn []       (osc-send "/stop" 0)) } ]

        (set! (aget persist.postmelodic jack-client-name) state)

        (osc.on "message" (fn [msg]
          (if (= (str osc-port) (aget msg.args 0)) (do
            (cond
              (= "/loaded"  msg.address) (state.events.emit "loaded"  msg.args)
              (= "/stopped" msg.address) (state.events.emit "stopped" msg.args)
              (= "/playing" msg.address) (state.events.emit "playing" msg.args))))))

        (set! state.jack-process (jack.spawn
          spawn-key postmelodic "-n" jack-client-name
                                "-p" osc-port
                                sample))
        (set! state.kill (fn [signal] (state.jack-process.kill signal)))

        (jack-client.started.then (fn []
          (osc-send "/listen")))

        state))))

(defn kit [root files]
  (.map files (fn [f] (path.resolve (path.join root f)))))
