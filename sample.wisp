(ns sample (:require [wisp.runtime :refer [str]]))

(def ^:private child (require "child_process"))
(def ^:private path  (require "path"))
(def ^:private osc   (require "./osc.wisp"))
(def ^:private JACK  (require "node-jack"))
(def ^:private jack  (new JACK.Client "hardmode-sample-manager"))

(def postmelodic "/home/epimetheus/code/hardmode/postmelodic/bin/sample_player")

(defn player [sample]
  (jack.on "port-registered" (fn [port]
    (jack.connect port "system:playback_1")
    (jack.connect port "system:playback_2")))
  (let [osc-client  (osc.client)
        sample-nr   osc-client.port
        sampler     (child.spawn postmelodic [
                      "-n" (str "Sample" sample-nr "_" osc-client.port)
                      "-p" osc-client.port
                      sample ]) ]
    { :play (fn [cue] (osc-client.send "/play" 0 (or cue 0))) }))

(defn kit [root files]
  (.map files (fn [f] (path.resolve (path.join root f)))))

