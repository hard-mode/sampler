(ns sampler (:require [wisp.runtime :refer [= and or str]]))

(defmacro each [t & body]
 `(setInterval (fn [] ~@body) ~t))

(defmacro after [t & body]
 `(setTimeout (fn [] ~@body) ~t))

(require "qtimers")

(let [

  teoria (require "teoria")

  midi   (require "./midi.wisp")
  osc    (require "./osc.wisp")
  sample (require "./sample.wisp")
  util   (require "./util.wisp")

  ; sequencer state

  tempo  180
  index  0
  index2 -1
  phrase [0 0 0 0 0 0 0 0]
  kicks  [1 0 0 1 0 1 0 0]
  snares [0 0 1 0 0 0 1 0]
  decay   0.5

  ; controllers

  nanokontrol (midi.connect-controller "nano" (fn [dt msg d1 d2]
    (if (and (= msg 189) (> d1 -1) (< d1 8)) (do
      (set! (aget phrase d1) d2)))
    (if (and (= msg 189) (= d1 16)) (do
      (set! decay (/ d2 127))))
    (if (and (= msg 189) (= d1 17)) (do
      (set! tempo (+ 120 (* 120 (/ d2 127))))))))

  launchpad (midi.connect-controller "Launchpad" (fn [dt msg d1 d2]
    (if (and (= msg 144) (> d1 15) (< d1 24) (= d2 127))
      (set! (aget kicks (- d1 16)) (if (aget kicks (- d1 16)) 0 1)))
    (if (and (= msg 144) (> d1 31) (< d1 40) (= d2 127))
      (set! (aget snares (- d1 32)) (if (aget snares (- d1 32)) 0 1)))))

  ; drums
  kick      (sample.player "kick.wav")
  snare     (sample.player "snare.wav")

  ; snap note to scale
  scale     (teoria.scale "f#" :minor)
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
    ; launchpad -- step indicator
    (.map (util.range 0 8) (fn [i]
      (launchpad.send [144 i        0])
      (launchpad.send [144 (+ 16 i) (if (aget kicks  i) 127 0)])
      (launchpad.send [144 (+ 32 i) (if (aget snares i) 127 0)])))
    (launchpad.send [144 index 70])
    (if (> index2 -1) (launchpad.send [144 index2 90]))

    ; drums
    (if (aget kicks index)  (kick.play))
    (if (aget snares index) (snare.play))

    ; yoshimi
    (let [note (.midi (make-note (aget phrase index)))]
      (nanokontrol.send [144 note 127])
      (after (* 2000 decay (/ 60 tempo))
        (nanokontrol.send [144 note 0])))

    ; advance step index
    (if (= -1 index2)
      (set! index (if (< index 7) (+ index 1) 0))
      (do (set! index index2)
          (set! index2 nil))))

]

  (each (* 500 (/ 60 tempo)) (step))

)
