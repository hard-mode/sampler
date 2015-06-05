(ns clip (:require [wisp.runtime  :refer [=]]
                   [wisp.sequence :refer [assoc]]))

(def ^:private control     (require "../lib/control.wisp"))
(def ^:private jack        (require "../lib/jack.wisp"))
(def ^:private postmelodic (require "./postmelodic.wisp"))
(def ^:private util        (require "../lib/util.wisp"))

(def ^:private hw jack.system)

(defn clip [clip-name]
  (let [player (postmelodic.player clip-name)]
    (jack.chain clip-name
      [ [player "output"] [hw "playback_1"] ]
      [ [player "output"] [hw "playback_2"] ])
    { :name   clip-name
      :player player }))

(defn track [options & clip-names]
  (let [next-clip    (util.counter)]
    (assoc options
      :clips
        (clip-names.map clip))))
