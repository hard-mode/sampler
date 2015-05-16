#!/usr/bin/env ./node_modules/wisp/bin/wisp.js

(ns sampler (:require [wisp.runtime :refer [= and or str re-pattern]]))

(defmacro each [t & body]
 `(setInterval (fn [] ~@body) ~t))

(defmacro after [t & body]
 `(setTimeout (fn [] ~@body) ~t))

(defmacro match [args & body]
  `(if (and ~@args) (do ~@body)))

; bootstrapper
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

; session code
(defn start []
  (let [

    ; libraries
    _      (require "qtimers")
    teoria (require "teoria")
    Q      (require "q")

    jack   (require "./lib/jack.wisp")
    midi   (require "./lib/midi.wisp")
    osc    (require "./lib/osc.wisp")
    util   (require "./lib/util.wisp")

    sample (require "./plugin/postmelodic.wisp")
    calf   (require "./plugin/calf.wisp")
    ;sooper (require "./plugin/sooperlooper.wisp")

    ; sequencer state
    tempo  140
    index  0
    jumpto -1

    ; drums
    kicks     [0 0 0 0 0 0 0 0]
    kick      (sample.player "./samples/kick.wav")
    kick-fx   (calf "KickFX" ["mono" "eq5" "compressor" "stereo"])
    _         (jack.chain "Kick"
                [ (.port kick    "output")        (.port kick-fx     "mono In #1") ]
                [ (.port kick-fx "stereo Out #1") (.port jack.system "playback_1") ]
                [ (.port kick-fx "stereo Out #2") (.port jack.system "playback_2") ])

    snares    [0 0 0 0 0 0 0 0]
    snare     (sample.player "./samples/snare.wav")
    snare-fx1 (calf "SnareFX1" ["mono" "eq5" "compressor" "stereo"])
    snare-fx2 (calf "SnareFX2" ["reverb" "sidechaingate"])
    _         (jack.chain "Snare"
                [ (.port snare "output")                   (.port snare-fx1   "mono In #1")          ]
                [ (.port snare-fx1 "eq5 Out #1")           (.port snare-fx2   "reverb In #1")        ]
                [ (.port snare-fx1 "eq5 Out #2")           (.port snare-fx2   "reverb In #2")        ]
                [ (.port snare-fx1 "eq5 Out #1")           (.port snare-fx2   "sidechaingate In #3") ]
                [ (.port snare-fx1 "eq5 Out #2")           (.port snare-fx2   "sidechaingate In #4") ]
                [ (.port snare-fx2 "sidechaingate Out #1") (.port jack.system "playback_1")          ]
                [ (.port snare-fx2 "sidechaingate Out #2") (.port jack.system "playback_2")          ]
                [ (.port snare-fx1 "stereo Out #1")        (.port jack.system "playback_1")          ]
                [ (.port snare-fx1 "stereo Out #2")        (.port jack.system "playback_2")          ])

    hihats    [1 0 0 1 0 0 1 0]
    hihat     (sample.player "./samples/hh.wav")
    hihat-fx1 (calf "HihatFX1" ["mono" "eq5" "stereo"])
    hihat-fx2 (calf "HihatFX2" ["vintagedelay"])
    _         (jack.chain "Hihat"
                [ (.port hihat     "output")              (.port hihat-fx1   "mono In #1")         ]
                [ (.port hihat-fx1 "eq5 Out #1")          (.port hihat-fx2   "vintagedelay In #1") ]
                [ (.port hihat-fx1 "eq5 Out #2")          (.port hihat-fx2   "vintagedelay In #2") ]
                [ (.port hihat-fx2 "vintagedelay Out #1") (.port jack.system "playback_1")         ]
                [ (.port hihat-fx2 "vintagedelay Out #2") (.port jack.system "playback_2")         ]
                [ (.port hihat-fx1 "stereo Out #1")       (.port jack.system "playback_1")         ]
                [ (.port hihat-fx1 "stereo Out #2")       (.port jack.system "playback_2")         ])

    ; synths
    phrase    [0 0 0 0 0 0 0 0]
    decay     0.5
    bassline  { :send-message (fn []) }

    yoshimi   (jack.client "yoshimi")
    _         (yoshimi.started.then (fn []
                (jack.connect-by-name "yoshimi" "left"  "system" "playback_1")
                (jack.connect-by-name "yoshimi" "right" "system" "playback_2")
                (set! bassline (midi.connect-output "yoshimi:midi in"))))
    _         (jack.spawn "yoshimi" "yoshimi")

    ; looper
    ;looper    (sooper.looper 8)

    ; controllers
    nanokontrol (midi.connect-controller "a2j:nano" (fn [dt msg d1 d2]
      (match [(= msg 189) (> d1 -1) (< d1 8)] (set! (aget phrase d1) d2))
      (match [(= msg 189) (= d1 16)]          (set! decay (/ d2 127)))
      (match [(= msg 189) (= d1 17)]          (set! tempo (+ 120 (* 120 (/ d2 127)))))))

    launchpad   (midi.connect-controller "a2j:Launchpad" (fn [dt msg d1 d2]

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
        (set! (aget (aget looper (- d1 112)) "state") :pre-record))))

    ; snap note to scale
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

    ; sequencer step function
    step      (fn []

      ; step jumper
      (if (> jumpto -1) (do (set! index jumpto)
                            (set! jumpto -1)))

      ; launchpad -- step indicator
      (.map (util.range 0 8) (fn [i]
        (launchpad.send [144 i        0])
        (launchpad.send [144 (+ 16 i) (if (aget kicks  i) 127 0)])
        (launchpad.send [144 (+ 32 i) (if (aget snares i) 127 0)])
        (launchpad.send [144 (+ 48 i) (if (aget hihats i) 127 0)])))
      (launchpad.send [144 index 70])
      (if (> jumpto -1) (launchpad.send [144 jumpto 90]))

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

      ; sooperlooper - begin recording
      ;(looper.map (fn [l i]
        ;(if (= l.state :ready)      (launchpad.send [144 (+ 112 i) 127])))
        ;(if (= l.state :pre-record) (do (launchpad.send [144 (+ 112 i) 70])
                                        ;(set! l.state :recording)
                                        ;(l.record))))

      ; advance step index
      (set! index (if (< index 7) (+ index 1) 0)))

  ]

    (each (* 500 (/ 60 tempo)) (step))

  ))
