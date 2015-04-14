(ns sample (:require [wisp.runtime :refer [str]]))

(def ^:private child (require "child_process"))
(def ^:private path  (require "path"))
(def ^:private osc   (require "./osc.wisp"))

(def postmelodic "/home/epimetheus/code/hardmode/postmelodic/bin/sample_player")

(defn player [sample]
  (let [port        osc.port
        client-name (sample.substr 0 50)
        sample-nr   (- port 10000)
        sampler     (child.spawn postmelodic
                      [ "-n" (str "Sample" sample-nr "_" port)
                        "-p" port
                        "-c" "system:playback_1"
                        sample ] ) ]
    (set! (aget osc.clients (str "127.0.0.1" port))
          (osc.Client. "127.0.0.1" port))
    (set! osc.port (+ 1 port))
    { :play (fn [cue] (osc.send "127.0.0.1" port "/play" 0 (or cue 0))) }))

(defn kit [root files]
  (.map files (fn [f] (path.resolve (path.join root f)))))

