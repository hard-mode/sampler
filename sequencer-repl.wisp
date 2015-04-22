(ns sampler (:require [wisp.repl :as repl]
                      [wisp.runtime :refer [= and or str]]))

;(defmacro each [t & body]
 ;`(setInterval (fn [] ~@body) ~t))

(defmacro after [t & body]
 `(setTimeout (fn [] ~@body) ~t))

(defmacro each [t & body]
 `(let [cb nil] 
    (set! cb (fn [] ~@body (setTimeout cb ~t)))
    (setTimeout cb ~t)))

(defmacro match [args & body]
  `(if (and ~@args) (do ~@body)))

(require "qtimers")

(let [

  sample (require "./sample.wisp")

  ; sequencer state

  tempo  170
  index  0
  kicks  [1 0 0 1 0 1 0 0]
  snares [0 0 1 0 0 0 1 0]

  ; drums
  kick      (sample.player "kick.wav")
  snare     (sample.player "snare.wav")


]

  (each (* 500 (/ 60 tempo))

    ; drums
    (if (aget kicks index)  (kick.play))
    (if (aget snares index) (snare.play))

    ; advance step index
    (set! index (if (< index 7) (+ index 1) 0)))

  (console.log "REPL:")

  (repl.start)

)
