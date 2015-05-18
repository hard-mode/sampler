(ns time (:require [wisp.runtime :refer [and]]))

(def ^:private NanoTimer (require "nanotimer"))

;(defmacro each [t & body]
 ;`(setInterval (fn [] ~@body) ~t))
;(defmacro after [t & body]
 ;`(setTimeout (fn [] ~@body) ~t))

(set! persist.time (or persist.time {}))
(def state persist.time)

(defn after [t f]
  (let [timer (NanoTimer.)]
    (timer.set-timeout f [] t)
    timer))

(defn each
  ([t f]
    (f)
    (after t (fn [] (each t f))))
  ([n t f]
    (let [old-timer (aget state n)]
      (console.log "\n\n\nTIMER" old-timer "\n\n\n")
      (if (and old-timer old-timer.time-out-t1)
        (old-timer.clear-timeout)))
    (let [new-timer (each t f)]
      (set! (aget state n) new-timer)
      new-timer)))
