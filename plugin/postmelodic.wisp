(ns sample (:require [wisp.runtime :refer [str =]]))

(def ^:private jack  (require "../lib/jack.wisp"))
(def ^:private osc   (require "../lib/osc.wisp"))
(def ^:private path  (require "path"))

(def postmelodic "/home/epimetheus/code/hardmode/postmelodic/bin/sample_player")

(def ^:private next-player 0)

(set! persist.postmelodic (or persist.postmelodic {}))

(defn player
  ([sample] (player sample sample))
  ([jack-client-name sample]
    (or (aget persist.postmelodic jack-client-name)
      (let [sample-nr         next-player
            _                 (set! next-player (+ next-player 1))
            osc-client        (osc.client)

            jack-port-name    (str jack-client-name ":output")
            jack-client       (jack.client jack-client-name)
            spawn-key         (str module.filename
                                ":" (if process.main process.main.filename nil)
                                ":" jack-client-name)
            jack-process      (jack.spawn spawn-key
                                postmelodic "-n" jack-client-name "-p" osc-client.port sample)

            state             { :client  jack-client
                                :process jack-process
                                :started jack-client.started
                                :port    jack-client.port

                                :play    (fn [cue]    (osc-client.send "/play" 0 (or cue 0)))
                                :kill    (fn [signal] (jack-process.kill signal)) }]

        (set! (aget persist.postmelodic jack-client-name) state)
        state))))

(defn kit [root files]
  (.map files (fn [f] (path.resolve (path.join root f)))))

