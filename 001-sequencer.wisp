#!/usr/bin/env ./node_modules/wisp/bin/wisp.js

(ns sampler (:require [wisp.runtime :refer [= and or str re-pattern]]))

((require "./lib/boot.wisp") module)

;;
;; session code
;;
(defn start []  (let [

    ;;
    ;; drum sounds
    ;;
    sample (require "./plugin/postmelodic.wisp")
    jack   (require "./lib/jack.wisp")

    kick   (sample.player "./samples/kick.wav")
    snare  (sample.player "./samples/snare.wav")
    hihat  (sample.player "./samples/hh.wav")

    _      (jack.chain "Kick"
             [ [kick  "output"] [jack.system "playback_1"] ]
             [ [kick  "output"] [jack.system "playback_2"] ]
             [ [hihat "output"] [jack.system "playback_1"] ]
             [ [snare "output"] [jack.system "playback_2"] ] )

    ;;
    ;; sequencer
    ;;
    time (require "./lib/time.wisp")

    tempo  220
    index  0

    kicks  [0 0 0 0 0 0 0 0]
    snares [0 0 0 0 0 0 0 0]
    hihats [0 0 0 0 0 0 0 0]

    util   (require "./lib/util.wisp")
    step   (fn [] (if (aget kicks  index)  (kick.play))
                  (if (aget snares index) (snare.play))
                  (if (aget hihats index) (hihat.play))
                  (set! index (if (< index 7) (+ index 1) 0)))

    ;;
    ;; web ui
    ;;
    web       (require "./lib/web.wisp")

    server (web.server 2097
      (web.page "/" (fn [req resp]
        (web.send-html req resp "foo")))
      (web.page "/help" (fn [req resp]
        (log req)
        (web.send-html req resp "joker"))))

  ]

    (time.each "step" (str (* 500 (/ 60 tempo)) "m") step)

  ))

;# vi:syntax=clojure
