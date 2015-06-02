(ns time (:require [wisp.runtime :refer [and =]]))

(def ^:private Long      (require "osc/node_modules/long"))
(def ^:private NanoTimer (require "nanotimer"))
(def ^:private jack      (require "./jack.wisp"))
(def ^:private osc       (require "./osc.wisp"))

(def jack-osc "/home/epimetheus/code/hardmode/rju/jack-osc")
(def klick    "klick")

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

(defn transport [tempo meter]
  (let [osc          persist.osc.default-client

        jack-osc     (jack.spawn "jack-osc" jack-osc "-p" 57130)
        klick        (jack.spawn "klick" klick "-T" meter tempo)

        bitmask      (Long.fromString "FFFFFFF" false 16)
        osc-connect  (fn [] (osc.send { :address "/receive" :args [bitmask] }
                                      "127.0.0.1" 57130))
        finder       nil

        on-pulse     (fn [ntp utc frm p-ntp p-utc p-frm pulse] (log "pulse" pulse))
        on-tick      (fn [ntp utc frm frame pulse])
        on-drift     (fn [ntp utc frm ntp-diff utc-diff])
        on-transport (fn [ntp utc frm fps ppm ppc pt state] (log "transport" state))]

    (set! finder (fn [client-name] (if (= 0 (client-name.index-of "jack-osc"))
      (do (osc-connect) (jack.state.events.off "client-online" finder)))))

    (jack.state.events.on "client-online" finder)

    (osc.on "message" (fn [msg] (cond
      (= msg.address "/pulse")     (on-pulse.apply     nil msg.args)
      (= msg.address "/tick")      (on-tick.apply      nil msg.args)
      (= msg.address "/drift")     (on-drift.apply     nil msg.args)
      (= msg.address "/transport") (on-transport.apply nil msg.args)
      :else nil)))

    { :each each }))
