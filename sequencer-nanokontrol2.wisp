(ns sampler (:require [wisp.runtime :refer [= and str]]))

(defmacro each [t & body]
 `(setInterval (fn [] ~@body) ~t))

(defmacro after [t & body]
 `(setTimeout (fn [] ~@body) ~t))

(let [

  midi   (require "./midi.wisp")
  util   (require "./util.wisp")
  chance (new (require "chance"))

  ; sequence

  tempo  180
  phrase [0 0 0 0 0 0 0 0]
  index   0
  decay   0.5

  ; controller

  nanokontrol
  (midi.connect-controller "nano" (fn [dt msg d1 d2]
    (if (and (= msg 189) (> d1 -1) (< d1 8)) (do
      (set! (aget phrase d1) d2)))
    (if (and (= msg 189) (= d1 16)) (do
      (set! decay (/ d2 127))))
    (if (and (= msg 189) (= d1 17)) (do
      (set! tempo (+ 120 (* 120 (/ d2 127))))))
    (console.log dt msg d1 d2)))

]

  (each (* 6 tempo)
    (set! index (if (< index 7) (+ index 1) 0))
    (let [note (aget phrase index)]
      (nanokontrol.out.send-message [144 note 127])
      (after (* 6 tempo decay) (nanokontrol.out.send-message [144 note 0]))))
      ;(after 150 (nanokontrol.out.send-message [98 note 127]))))

{

  :init  (fn [])
  :start (fn [])
  :stop  (fn [])

}

)
