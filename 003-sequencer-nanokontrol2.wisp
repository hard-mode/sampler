#!/usr/bin/env ./node_modules/wisp/bin/wisp.js

(ns sampler (:require [wisp.runtime :refer [= and or str re-pattern]]))

((require "./lib/boot.wisp") module)

;;
;; TODO macro imports
;;
(defmacro match [args & body]
  `(if (and ~@args) (do ~@body)))

;;
;; session code
;;
(defn start []  (let [

    ;;
    ;; drums
    ;;
    sample (require "./plugin/postmelodic.wisp")
    calf   (require "./plugin/calf.wisp")
    jack   (require "./lib/jack.wisp")
    hw     jack.system

    kick  (let [inst (sample.player "./samples/kick.wav")
                fx   (calf "KickFX" [ "mono" "eq5" "compressor" "stereo" ])]

            (jack.chain "Kick"
              [ [inst "output"]      [fx "mono In #1"] ]
              [ [fx "stereo Out #1"] [hw "playback_1"] ]
              [ [fx "stereo Out #2"] [hw "playback_2"] ] )
            inst)

    snare (let [inst (sample.player "./samples/snare.wav")
                fx1  (calf "SnareFX1" [ "mono" "eq5" "compressor" "stereo"])
                fx2  (calf "SnareFX2" [ "reverb" "sidechaingate"])]

            (jack.chain "Snare"
              [ [inst "output"]              [fx1 "mono In #1"]          ]
              [ [fx1 "eq5 Out #1"]           [fx2 "reverb In #1"]        ]
              [ [fx1 "eq5 Out #2"]           [fx2 "reverb In #2"]        ]
              [ [fx1 "eq5 Out #1"]           [fx2 "sidechaingate In #3"] ]
              [ [fx1 "eq5 Out #2"]           [fx2 "sidechaingate In #4"] ]
              [ [fx2 "sidechaingate Out #1"] [hw  "playback_1"]          ]
              [ [fx2 "sidechaingate Out #2"] [hw  "playback_2"]          ]
              [ [fx1 "stereo Out #1"]        [hw  "playback_1"]          ]
              [ [fx1 "stereo Out #2"]        [hw  "playback_2"]          ] )

            inst)

    hihat (let [inst (sample.player "./samples/hh.wav")
                fx1  (calf "HihatFX1" [ "mono" "eq5" "stereo" ])
                fx2  (calf "HihatFX2" [ "vintagedelay" ])]

            (jack.chain "Hihat"
              [ [inst "output"]              [fx1 "mono In #1"]         ]
              [ [fx1  "eq5 Out #1"]          [fx2 "vintagedelay In #1"] ]
              [ [fx1  "eq5 Out #2"]          [fx2 "vintagedelay In #2"] ]
              [ [fx2  "vintagedelay Out #1"] [hw  "playback_1"]         ]
              [ [fx2  "vintagedelay Out #2"] [hw  "playback_2"]         ]
              [ [fx1  "stereo Out #1"]       [hw  "playback_1"]         ]
              [ [fx1  "stereo Out #2"]       [hw  "playback_2"]         ] )

            inst)


    ;;
    ;; synths
    ;;

    ;; how it oughtta be
    ;midi      (require "./lib/midi.wisp")
    ;bassline  { :send-message (fn []) }
    ;yoshimi   (let [inst (jack.client "yoshimi")
                    ;midi (inst.port   "midi-in")
                    ;proc (jack.spawn  "yoshimi" "yoshimi")]
                ;(inst.started.then (fn []
                  ;(set! bassline (midi.connect-output "yoshimi:midi-in"))))
                ;(jack.chain "Yoshimi"
                  ;[ [inst "left"]  [hw "playback_1"]
                    ;[inst "right"] [hw "playback_2"] ] ))

    midi      (require "./lib/midi.wisp")
    bassline  { :send-message (fn []) }
    yoshimi   (jack.client "yoshimi")
    _         (yoshimi.started.then (fn []
                (jack.connect-by-name "yoshimi" "left"  "system" "playback_1")
                (jack.connect-by-name "yoshimi" "right" "system" "playback_2")
                (set! bassline (midi.connect-output "yoshimi:midi in"))))
    _         (jack.spawn "yoshimi" "yoshimi")


    ;;
    ;; looper
    ;;
    ;sooper (require "./plugin/sooperlooper.wisp")
    ;looper (sooper.looper 8)


    ;;
    ;; scale thingy
    ;;
    teoria    (require "teoria")
    scale     (teoria.scale "g#" :minor)
    make-note (fn [n]
    (let [span   (/ 127 3)
          octave (Math.floor (/ n span))
          degree (Math.floor (* 7 (/ (mod n span) span)))
          note   (scale.get (+ 1 degree))]
      (if (< octave 1) (note.transpose "P-8"))
      (if (> octave 1) (note.transpose "P8"))
      (if (> octave 2) (note.transpose "P8"))
      note))


    ;;
    ;; sequencer
    ;;

    time (require "./lib/time.wisp")

    tempo  140
    index  0
    jumpto -1

    kicks  [1 0 0 0 0 1 0 0]
    snares [0 0 1 0 0 0 1 0]
    hihats [1 0 0 1 0 0 1 0]
    phrase [0 0 0 0 0 0 0 0]
    decay  0.5

    launchpad nil

    util   (require "./lib/util.wisp")
    step   (fn []

      ; step jumper
      (if (> jumpto -1) (do (set! index jumpto)
                            (set! jumpto -1)))

      ; launchpad -- step indicator
      (if launchpad (do
        (.map (util.range 0 8) (fn [i]
          (launchpad.send [144 i        0])
          (launchpad.send [144 (+ 16 i) (if (aget kicks  i) 127 0)])
          (launchpad.send [144 (+ 32 i) (if (aget snares i) 127 0)])
          (launchpad.send [144 (+ 48 i) (if (aget hihats i) 127 0)])))
        (launchpad.send [144 index 70])
        (if (> jumpto -1) (launchpad.send [144 jumpto 90]))))

      ; drums
      (if (aget kicks  index)  (kick.play))
      (if (aget snares index) (snare.play))
      (if (aget hihats index) (hihat.play))

      ; yoshimi
      (if bassline.send-message
        (let [note (.midi (make-note (aget phrase index)))]
          (bassline.send-message [144 note 127])
          (time.after (str (* 2000 decay (/ 60 tempo)) "m")
            (fn [] (bassline.send-message [144 note 0])))))

      ; sooperlooper - begin recording
      ;(looper.map (fn [l i]
        ;(if (= l.state :ready)      (launchpad.send [144 (+ 112 i) 127])))
        ;(if (= l.state :pre-record) (do (launchpad.send [144 (+ 112 i) 70])
                                        ;(set! l.state :recording)
                                        ;(l.record))))

      ; advance step index
      (set! index (if (< index 7) (+ index 1) 0)))


    ;;
    ;; controllers
    ;;
    nanokontrol (midi.connect-controller "a2j:nano" (fn [dt msg d1 d2]
      (match [(= msg 189) (> d1 -1) (< d1 8)] (set! (aget phrase d1) d2))
      (match [(= msg 189) (= d1 16)]          (set! decay (/ d2 127)))
      (match [(= msg 189) (= d1 17)]          (set! tempo (+ 120 (* 120 (/ d2 127)))))))

    _ (set! launchpad (midi.connect-controller "a2j:Launchpad" (fn [dt msg d1 d2]

      ; jumper
      (match [(= msg 144) (> d1 -1) (< d1 8)  (= d2 127)]
        (set! jumpto d1))

      ; drum seq
      (match [(= msg 144) (> d1 15) (< d1 24) (= d2 127)]
        (set! (aget kicks  (- d1 16)) (if (aget kicks  (- d1 16)) 0 1)))
      (match [(= msg 144) (> d1 31) (< d1 40) (= d2 127)]
        (set! (aget snares (- d1 32)) (if (aget snares (- d1 32)) 0 1)))
      (match [(= msg 144) (> d1 47) (< d1 56) (= d2 127)]
        (set! (aget hihats (- d1 48)) (if (aget hihats (- d1 48)) 0 1)))

      ; looper
      (match [(= msg 144) (> d1 111) (< d1 120 ) (= d2 127)]
        (set! (aget (aget looper (- d1 112)) "state") :pre-record)))))

  ]

    (time.each "step" (str (* 500 (/ 60 tempo)) "m") step)

  ))

;# vi:syntax=clojure
