(ns sample (:require [wisp.runtime :refer [str =]]))

(def ^:private child (require "child_process"))
(def ^:private path  (require "path"))
(def ^:private osc   (require "./osc.wisp"))
(def ^:private JACK  (require "node-jack"))
(def ^:private jack  (new JACK.Client "hardmode-sample-manager"))

(def postmelodic "/home/epimetheus/code/hardmode/postmelodic/bin/sample_player")

(def ^:private next-player 0)

(defn player [sample]
  (let [sample-nr        next-player
        _ (set! next-player (+ next-player 1))
        osc-client       (osc.client)
        jack-client-name (str "Sample" sample-nr "_" osc-client.port)
        jack-port-name   (str jack-client-name ":output")
        connect          (fn [port] (if (= port jack-port-name) (do
                           (jack.connect port "system:playback_1")
                           (jack.connect port "system:playback_2"))))]
    (jack.on "port-registered" connect)
    (child.spawn postmelodic [ "-n" jack-client-name
                               "-p" osc-client.port
                               sample ])
    { :play (fn [cue] (osc-client.send "/play" 0 (or cue 0))) }))

(defn kit [root files]
  (.map files (fn [f] (path.resolve (path.join root f)))))

