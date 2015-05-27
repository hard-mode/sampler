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

    kicks  [1 0 1 0 1 0 1 0]
    snares [0 0 0 0 1 0 0 0]
    hihats [1 1 1 1 1 1 1 1]

    util   (require "./lib/util.wisp")
    step   (fn [] (if (aget kicks  index)  (kick.play))
                  (if (aget snares index) (snare.play))
                  (if (aget hihats index) (hihat.play))
                  (set! index (if (< index 7) (+ index 1) 0)))

    ;;
    ;; web ui
    ;;
    web    (require "./lib/web.wisp")
    path   (require "path")

    ; crutch
    sequencer { "kicks" kicks "snares" snares "hihats" hihats }

    server (web.server 2097
      (web.page "/" (path.resolve "./web-ui.js"))
      (web.endpoint "/state" (fn [req resp]
        (if (= "GET" req.method)
          (web.send-json req resp
            { :kicks  kicks
              :snares snares
              :hihats hihats }))
        (if (= "POST" req.method)
          (let [data ""]
            (req.on "data" (fn [d]
              (set! data (+ data d ))))
            (req.on "end"  (fn []
              (let [data (JSON.parse data)
                    inst (aget sequencer (aget data 0))]
                (set! (aget inst (aget data 1))
                      (if (aget data 2) 1 0)))))
            (web.send-json req resp "OK")))))
      (web.endpoint "/help" (fn [req resp]
        (log req)
        (web.send-html req resp "joker"))))

  ]

    (time.each "step" (str (* 500 (/ 60 tempo)) "m") step)

  ))

;# vi:syntax=clojure
