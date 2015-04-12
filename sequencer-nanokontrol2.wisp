(ns sampler (:require [wisp.runtime :refer [= and or str]]))

(defmacro each [t & body]
 `(setInterval (fn [] ~@body) ~t))

(defmacro after [t & body]
 `(setTimeout (fn [] ~@body) ~t))

(let [

  midi   (require "./midi.wisp")
  osc    (require "./osc.wisp")
  sample (require "./sample.wisp")
  util   (require "./util.wisp")

  ; sequencer state

  tempo  180
  index   0
  phrase [0 0 0 0 0 0 0 0]
  kicks  [1 0 0 1 0 1 0 0]
  snares [0 0 1 0 0 0 1 0]
  decay   0.5

  ; controllers

  nanokontrol
  (midi.connect-controller "nano" (fn [dt msg d1 d2]
    (if (and (= msg 189) (> d1 -1) (< d1 8)) (do
      (set! (aget phrase d1) d2)))
    (if (and (= msg 189) (= d1 16)) (do
      (set! decay (/ d2 127))))
    (if (and (= msg 189) (= d1 17)) (do
      (set! tempo (+ 120 (* 120 (/ d2 127))))))
    (console.log dt msg d1 d2)))

  launchpad
  (midi.connect-controller "Launchpad" (fn [dt msg d1 d2]
    (if (and (= msg 144) (> d1 15) (< d1 24) (= d2 127)) (do
      (set! (aget kicks (- d1 16)) (if (aget kicks (- d1 16)) 0 1))
      (console.log "KICK" (- 16 d1) (aget kicks (- d1 16)))))
    (if (and (= msg 144) (> d1 31) (< d1 40) (= d2 127)) (do
      (set! (aget snares (- d1 32)) (if (aget snares (- d1 32)) 0 1))
      (console.log "KICK" (- 16 d1) (aget kicks (- d1 16)))))
    (console.log msg d1 d2)))

  ; drums
  kick  (sample.player "kick.wav")
  snare (sample.player "snare.wav")
  play  (fn [port] (osc.send "127.0.0.1" port "/play" 0 0))

  ; sequencer step function

  step
  (fn []
    ; advance step index
    (set! index (if (< index 7) (+ index 1) 0))

    ; launchpad -- step indicator
    (.map (util.range 0 8) (fn [i]
      (launchpad.send [144 i        0])
      (launchpad.send [144 (+ 16 i) (if (aget kicks  i) 127 0)])
      (launchpad.send [144 (+ 32 i) (if (aget snares i) 127 0)])))
    (launchpad.send [144 index 70])

    ; drums
    (if (aget kicks index)  (play kick))
    (if (aget snares index) (play snare))

    ; yoshimi
    (let [note (aget phrase index)]
      (nanokontrol.send [144 note 127])
      (after (* 1000 decay (/ 60 tempo))
        (nanokontrol.send [144 note 0]))))

]

  (each (* 1000 (/ 60 tempo)) (step))

)
