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
  (let [port        osc.port
        client-name (sample.substr 0 50)
        sample-nr   (- port 10000)
        sampler     (child.spawn postmelodic
                      [ "-n" (str "Sample" sample-nr "_" port)
                        "-p" port
                        sample ] ) ]
    (set! (aget osc.clients (str "127.0.0.1" port))
          (osc.Client. "127.0.0.1" port))
    (set! osc.port (+ 1 port))
    { :play (fn [cue] (osc.send "127.0.0.1" port "/play" 0 (or cue 0))) }))

(defn kit [root files]
  (.map files (fn [f] (path.resolve (path.join root f)))))

