#!/usr/bin/env ./node_modules/wisp/bin/wisp.js
(ns sampler (:require [wisp.runtime :refer [= and or str re-pattern assoc]]))
((require "./lib/boot.wisp") module)

;; TODO macro imports

(defmacro match [args & body]
  `(if (and ~@args) (do ~@body)))

(defmacro session [& body]
  `(defn start [] (let [~@body])))

(session

    ;; transport ----------------------------------------------------

    tempo 140
    time  (require "./lib/time.wisp")
    time  (time.transport tempo [4 4])


    ;; available controllers ----------------------------------------

    lpd         (require "./plugin/novation-launchpad.wisp")
    launchpad   (.connect lpd)

    lpd-kbd-1   (lpd.keyboard lpd.grid-xy 3)
    lpd-kbd-2   (lpd.keyboard lpd.grid-xy 5)
    _ (launchpad.on "refresh" (fn [] launchpad
        (lpd-kbd-1.map (fn [i] (launchpad.send [144 i 60])))
        (lpd-kbd-2.map (fn [i] (launchpad.send [144 i 60])))))

    _ (time.each :16th (fn [] (launchpad.emit "refresh")))


    ;; beat jumper --------------------------------------------------

    index   0
    jumpto -1

    _ (time.each :8th (fn []
        (if (> jumpto -1)
          (do (set! index jumpto) (set! jumpto -1))
          (set! index (if (< index 7) (+ index 1) 0)))))

    _ (launchpad.on "press" (fn [db msg d1 d2]
        (match [(= msg 176) (> d1 103) (< d1 112)  (= d2 127)]
          (set! jumpto (- d1 104)))))


    ;; drums --------------------------------------------------------

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

    kicks  [1 0 0 0 0 1 0 0]
    _ (time.each :8th (fn [] (if (aget kicks index) (kick.play))))

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

    snares [0 0 1 0 0 0 1 0]
    _ (time.each :8th (fn [] (if (aget snares index) (snare.play))))

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

    hihats [1 0 0 1 0 0 1 0]
    _ (time.each :16th (fn [] (if (aget hihats index) (hihat.play))))

    _ (launchpad.on "press" (fn [db msg d1 d2]
        (match [(= msg 144) (> d1 -1) (< d1 8) (= d2 127)]
          (set! (aget kicks  (- d1 0))  (if (aget kicks  (- d1 0))  0 1)))
        (match [(= msg 144) (> d1 15) (< d1 24) (= d2 127)]
          (set! (aget snares (- d1 16)) (if (aget snares (- d1 16)) 0 1)))
        (match [(= msg 144) (> d1 31) (< d1 40) (= d2 127)]
          (set! (aget hihats (- d1 32)) (if (aget hihats (- d1 32)) 0 1)))))

    util        (require "./lib/util.wisp")
    _ (launchpad.on "draw" (fn []
        (.map (util.range 0 8) (fn [i]
          (let [btn (aget lpd.circles-top i)]
            (launchpad.send [(aget btn 0) (aget btn 1) (if (= index i) 70 0)]))
          (launchpad.send [144 (+ 0 i)  (if (aget kicks  i) 127 0)])
          (launchpad.send [144 (+ 16 i) (if (aget snares i) 127 0)])
          (launchpad.send [144 (+ 32 i) (if (aget hihats i) 127 0)])))))


    ;; synths -------------------------------------------------------

    midi  (require "./lib/midi.wisp")
    carla (require "./plugin/carla.wisp")

    synth    (carla.lv2  "Noize Mak3r" "http://kunz.corrupt.ch/products/tal-noisemaker")
    synth-fx (calf       "SynFX" [ "mono" "eq5" "compressor" "stereo" ])
    _        (jack.chain "Synth"
               [ [synth    "Audio Output 1"] [synth-fx "mono In #1"] ]
               [ [synth-fx "stereo Out #1"]  [hw       "playback_1"] ]
               [ [synth-fx "stereo Out #2"]  [hw       "playback_2"] ] )

    synth-octave    4
    synth-midi      nil
    synth-note-on   (fn [])
    synth-note-off  (fn [])

    _ (synth.client.started.then (fn []
        (set! synth-midi     (midi.connect-output "Noize Mak3r"))
        (set! synth-note-on  (fn [note] (synth-midi.send-message [144 (+ note (* 12 synth-octave)) 127])))
        (set! synth-note-off (fn [note] (synth-midi.send-message [144 (+ note (* 12 synth-octave)) 0  ])))))

    _ (launchpad.on "press" (fn [db msg d1 d2]
        (let [kbd-key (lpd-kbd-1.index-of d1)]
          (if (> kbd-key -1)
            (if (= d2 127)
              (synth-note-on  kbd-key)
              (synth-note-off kbd-key))))
        (let [kbd-key (lpd-kbd-2.index-of d1)]
          (if (> kbd-key -1)
            (if (= d2 127)
              (synth-note-on  (- kbd-key 12))
              (synth-note-off (- kbd-key 12)))))))


    ;; looper -------------------------------------------------------

    sooper  (require "./plugin/sooperlooper.wisp")
    looper  (sooper.looper "Looper" 8)

    _ (jack.chain "Looper"
        [ [synth-fx "stereo Out #1"] [looper "common_in_1"] ]
        [ [synth-fx "stereo Out #2"] [looper "common_in_2"] ]
        [ [looper   "common_out_1"]  [hw "playback_1"]      ]
        [ [looper   "common_out_2"]  [hw "playback_2"]      ])

    _ (time.each :8th (fn []
        (looper.tracks.map (fn [l i]
          (if (= l.state :ready)      (launchpad.send [144 (+ 112 i) 127]))
          (if (= l.state :pre-record) (do (launchpad.send [144 (+ 112 i) 70])
                                          (set! l.state :recording)
                                          (l.record)))))))

    _ (launchpad.on "press" (fn [db msg d1 d2]
        (match [(= msg 144) (> d1 111) (< d1 120 ) (= d2 127)]
          (set! (aget (aget looper.tracks (- d1 112)) "state") :pre-record))))

)

;# vi:syntax=clojure