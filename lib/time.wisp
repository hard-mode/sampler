(ns time)

(def ^:private NanoTimer (require "nanotimer"))

;(defmacro each [t & body]
 ;`(setInterval (fn [] ~@body) ~t))
;(defmacro after [t & body]
 ;`(setTimeout (fn [] ~@body) ~t))

(set! persist.time (or persist.time {}))
(def state persist.time)

(defn after [t f]
  (let [timer (NanoTimer.)]
    (timer.setTimeout f [] t)
    timer))

(defn each
  ([t f]
    (f)
    (after t (fn [] (each t f))))
  ([n t f]
    (or
      (aget state n)
      (let [timer (each t f)]
        (set! (aget state n) timer)
        timer))))
