(ns sample (:require [wisp.runtime :refer [str =]]))

(def ^:private jack  (require "../lib/jack.wisp"))
(def ^:private osc   (require "../lib/osc.wisp"))
(def ^:private path  (require "path"))

(def postmelodic "/home/epimetheus/code/hardmode/postmelodic/bin/sample_player")

(def ^:private next-player 0)

(defn player [sample]
  (let [sample-nr         next-player
        _                 (set! next-player (+ next-player 1))
        osc-client        (osc.client)

        jack-client-name  (str "Sample" sample-nr "_" osc-client.port)
        jack-port-name    (str jack-client-name ":output")
        jack-client       (jack.client jack-client-name)
        jack-process      (jack.spawn jack-client-name
                            postmelodic "-n" jack-client-name "-p" osc-client.port sample)]

    (jack-client.started.then (fn []
      (jack.connect-by-name jack-client-name "output" "system" "playback_1")
      (jack.connect-by-name jack-client-name "output" "system" "playback_2")))

    { :client  jack-client
      :process jack-process
      :started jack-client.started
      :port    jack-client.port

      :play    (fn [cue]    (osc-client.send "/play" 0 (or cue 0)))
      :kill    (fn [signal] (jack-process.kill signal)) }))

(defn kit [root files]
  (.map files (fn [f] (path.resolve (path.join root f)))))

