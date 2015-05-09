(ns sample (:require [wisp.runtime :refer [str =]]))

(def ^:private path  (require "path"))
(def ^:private osc   (require "./osc.wisp"))
(def ^:private jack  (require "./jack.wisp"))
(def ^:private spawn (require "./spawn.wisp"))

(def postmelodic "/home/epimetheus/code/hardmode/postmelodic/bin/sample_player")

(def ^:private next-player 0)

(defn player [sample]
  (let [sample-nr        next-player
        _                (set! next-player (+ next-player 1))
        osc-client       (osc.client)
        jack-client-name (str "Sample" sample-nr "_" osc-client.port)
        jack-port-name   (str jack-client-name ":output")
        jack-client      (jack.client jack-client-name) 
        jack-process     nil]
    (jack-client.on "online" (fn []
      (console.log "postmelodic" sample-nr "online as" jack-client-name "online")
      (jack-client.connect jack.system)))
    (set! jack-process (jack.spawn postmelodic "-n" jack-client-name "-p" osc-client.port sample))
    ;(jack-process.open)
    ;(set! jack-process
      ;(spawn (str "postmelodic-" sample-nr)
        ;postmelodic [ "-n" jack-client-name "-p" osc-client.port sample ]))
    { :play (fn [cue]    (osc-client.send "/play" 0 (or cue 0)))
      :kill (fn [signal] (jack-process.kill signal)) }))

(defn kit [root files]
  (.map files (fn [f] (path.resolve (path.join root f)))))

