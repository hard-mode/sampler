(ns sampler (:require [wisp.repl :as repl]
                      [wisp.runtime :refer [= and or str]]))

(def ^:private qtimers (require "qtimers"))

(set! session.persist.timers (or session.persist.timers []))

(defmacro after [t & body]
 `(let [self { :stop    (qtimers.clearTimeout this.timeout)
               :timeout (qtimers.setTimeout (fn [] ~@body) ~t) }]
    (session.persist.timers.push self)
    self))

(defmacro each [t & body]
 `(let [self { :stop (fn [] (qtimers.clearTimeout this.timeout))
               :timeout nil }
        cb   nil] 
    (set! cb (fn []
      ~@body
      (set! self.timeout (qtimers.setTimeout cb ~t))))
    (cb)
    (session.persist.timers.push self)
    self))
    ;(set! self.stop (qtimers.clearTimeout (setTimeout cb ~t)))

;(defmacro each [t & body]
 ;`(let [self     {}
        ;callback nil]uuuuuuuuuuuuuuuuuu
    ;(set! self.stop (.-cancel (after ~t ~@body (set! self.stop))))
    ;self
    ;(after ~t
      ;~@body
      ;(set! self.stop))

    ;(set! callback (fn []
      ;~@body
      ;(let [timeout (qtimers.setTimeout callback ~t)]
        ;(set! self.stop (fn [] (qtimers.clearTimeout timeout))))))
    ;(let [timeout (qtimers.setTimeout callback ~t)]
      ;(set! self.stop (fn [] (qtimers.clearTimeout timeout))))

    ;(set! cb (fn [] ~@body (set! timeout (qtimers.setTimeout cb ~t))))
    ;(qtimers.setTimeout cb ~t)
    ;self)

(defmacro match [args & body]
  `(if (and ~@args) (do ~@body)))

(let [

  sample (require "./sample.wisp")

  ; sequencer state

  tempo  170
  index  0
  kicks  [1 0 0 1 0 0 0 0]
  snares [0 0 0 0 1 0 0 0]

  ; drums
  kick  (sample.player "kick.wav")
  snare (sample.player "snare.wav")

]

  (each (* 500 (/ 60 tempo))
    ; drums
    (if (aget kicks index)  (kick.play))
    (if (aget snares index) (snare.play))
    ; advance step index
    (set! index (if (< index 7) (+ index 1) 0)))

  ;(console.log "REPL:")
  ;(console.log process.stdin)
  ;(console.log process.stdout)

  ;(repl.start)

)
