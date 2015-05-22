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
    (let [timer (NanoTimer.)]
      (timer.set-interval f [] t)
      timer))
  ([n t f]
    (let [old-timer (aget state n)]
      (if old-timer (old-timer.clear-interval)))
    (let [new-timer (each t f)]
      (set! (aget state n) new-timer)
      new-timer)))

(defn transport []
  { :each (fn [interval callback]) })
