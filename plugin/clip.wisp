(ns clip (:require [wisp.runtime  :refer [=]]
                   [wisp.sequence :refer [assoc]]))

(def ^:private control     (require "../lib/control.wisp"))
(def ^:private jack        (require "../lib/jack.wisp"))
(def ^:private postmelodic (require "./postmelodic.wisp"))
(def ^:private util        (require "../lib/util.wisp"))

(def ^:private hw jack.system)

(defn init-clip [track-number clip-number clip-name]
  (let [note   (launchpad.grid-get clip-number track-number)
        btn    (control.btn-push { :data1 note } )
        player (postmelodic.player clip-name)]
    (launchpad.widgets.members.push btn)
    (launchpad.events.on "btn-on" (fn [arg]
      (if (= arg note) (player.play))))
    (launchpad.events.on "btn-off" (fn [arg]
      (if (= arg note) (player.stop))))
    (jack.chain clip-name
      [ [player "output"] [hw "playback_1"] ]
      [ [player "output"] [hw "playback_2"] ])
    player))

(defn clip [clip-name]
  { :name clip-name })

(defn track [options & clip-names]
  (let [next-clip    (util.counter)]
    (assoc options
      :clips
        (clip-names.map clip))))
