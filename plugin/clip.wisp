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

(defn init-clip [track-number clip-number clip]
  (fn [grid-get events]
    (let [note   (grid-get clip-number track-number)
          btn    (control.toggle { :data1 note } )]
      (events.on "btn-on" (fn [arg]
        (if (= arg note) (clip.player.play))))
      (events.on "btn-off" (fn [arg]
        (if (= arg note) (clip.player.stop))))
      btn)))

(defn init-track [track track-number]
  (fn [grid-get events]
    (control.group
      (track.clips.map (fn [clip clip-number]
        ((init-clip track-number clip-number clip) grid-get events))))))

(defn launcher [tracks]
  (tracks.map init-track))
