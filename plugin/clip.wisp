(ns clip (:require [wisp.runtime  :refer [= dictionary]]
                   [wisp.sequence :refer [assoc]]))

(def ^:private control     (require "../lib/control.wisp"))
(def ^:private jack        (require "../lib/jack.wisp"))
(def ^:private postmelodic (require "./postmelodic.wisp"))
(def ^:private util        (require "../lib/util.wisp"))

(def ^:private hw jack.system)

(defn clip [clip-name & opts]
  (let [opts   (apply dictionary opts)
        player (postmelodic.player clip-name)]
    (jack.chain clip-name
      [ [player "output"] [hw "playback_1"] ]
      [ [player "output"] [hw "playback_2"] ])
    (assoc opts
      :name   clip-name
      :loop   opts.loop
      :player player)))

(defn track [options & clips]
  (assoc options :clips clips))

;(defn init-clip [grid events track-number clip clip-number]
  ;(let [note   (grid clip-number track-number)
        ;btn    (control.toggle { :data1 note } )]
    ;(events.on "btn-on" (fn [arg]
      ;(if (= arg note) (clip.player.play))))
    ;(events.on "btn-off" (fn [arg]
      ;(if (= arg note) (clip.player.stop))))
    ;(clip.player.events.on "stopped" (fn []
      ;(clip.player.events.emit "update" { :event :note-off :data1 note })
      ;(log "STOPPED")))
    ;btn))

;(defn init-track [grid events track track-number]
  ;(control.group
    ;(track.clips.map (init-clip.bind nil grid events track-number))))

;(defn launcher [tracks]
  ;(fn [grid events]
    ;(control.group (tracks.map (init-track.bind nil grid events)))))
