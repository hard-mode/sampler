#!/usr/bin/env ./node_modules/wisp/bin/wisp.js

(ns sampler (:require [wisp.runtime :refer [= and or str re-pattern]]))

;;
;; TODO macro imports
;; TODO time/transport module
;;
(defmacro each [t & body]
 `(setInterval (fn [] ~@body) ~t))

(defmacro after [t & body]
 `(setTimeout (fn [] ~@body) ~t))

(defmacro match [args & body]
  `(if (and ~@args) (do ~@body)))

;;
;; bootstrapper
;;
(if (= module require.main)
  (let [log       console.log
        filename  module.filename
        session   (require filename)
        reload    (fn [] 
          (log "Loading session" filename)
          (delete (aget require.cache filename))
          (set! session (require filename))
          (log "Starting session" filename)
          (session.start))
        watcher  (.watch (require "chokidar")
          module.filename
          { :persistent true }) ]

    (.install            (require "source-map-support")) 
    (.register-handler   (require "segfault-handler"))
    (set! global.persist {})
    (set! global.log     log)
    (watcher.on "change" reload)

    (reload)))

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
    tempo  140
    index  0
    jumpto -1

    kicks  [1 0 0 0 0 1 0 0]
    snares [0 0 1 0 0 0 1 0]
    hihats [1 0 0 1 0 0 1 0]
    phrase [0 0 0 0 0 0 0 0]
    decay  0.5

    util   (require "./lib/util.wisp")
    step   (fn []

      ; step jumper
      (if (> jumpto -1) (do (set! index jumpto)
                            (set! jumpto -1)))

      ; drums
      (if (aget kicks  index)  (kick.play))
      (if (aget snares index) (snare.play))
      (if (aget hihats index) (hihat.play))

      ; yoshimi
      (if bassline.send-message
        (let [note (.midi (make-note (aget phrase index)))]
          (bassline.send-message [144 note 127])
          (after (* 2000 decay (/ 60 tempo))
            (bassline.send-message [144 note 0]))))

      ; advance step index
      (set! index (if (< index 7) (+ index 1) 0)))

  ]

    (require "qtimers")
    (each (* 500 (/ 60 tempo)) (step))

  ))
