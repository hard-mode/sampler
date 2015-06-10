(ns time (:require [wisp.runtime :refer [and =]]))

(def ^:private Long      (require "osc/node_modules/long"))
(def ^:private NanoTimer (require "nanotimer"))
(def ^:private event2    (require "eventemitter2"))
(def ^:private expect    (.-expect (require "./util.wisp")))
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

(defn frame->second [fps frame]
  (/ frame fps))

(defn second->beat [bpm seconds]
  (Math.floor (+ 1 (* seconds (/ bpm 60)))))

(defn beat->bar [meter-top beats]
  (Math.floor (+ 0.75 (/ beats meter-top))))

(defn make-transport [tempo meter]
  (let [jack-osc      (jack.spawn "jack-osc" jack-osc "-p" 57130)

        klick         (jack.spawn "klick" klick "-T" meter tempo)

        osc-send      (osc.bind-to 57130) ; jack-osc default port

        bitmask       (Long.fromString "FFFFFFF" false 16)

        state         { :rolling nil
                        :bpm nil :meter-top nil :meter-bottom nil
                        :fps nil :frames nil :seconds nil :beats nil :bars nil }

        events        (event2.EventEmitter2. { :maxListeners 64 })

        on-status     (fn [fps ppm ppc pt rolling]
                        (set! state.fps          fps    )
                        (set! state.bpm          ppm    )
                        (set! state.meter-top    ppc    )
                        (set! state.meter-bottom pt     )
                        (set! state.rolling      rolling))

        on-pulse      (fn [ntp utc frm p-ntp p-utc p-frm pulse]
                        (events.emit "pulse"))

        on-tick       (fn [ntp utc frm frame pulse]

                        ; hack: swap bytes
                        ; TODO: fix this in osc.js?
                        (let [h frame.high l frame.low]
                          (set! frame.high l) (set! frame.low h))

                        (set! state.frames  frame)
                        (set! state.seconds (frame->second state.fps frame))
                        (set! state.beats   (second->beat  state.bpm state.seconds))
                        (set! state.bars    (beat->bar     state.meter-top state.beats))

                        (events.emit "tick"))

        on-drift      (fn [ntp utc frm ntp-dif utc-dif])

        on-transport  (fn [ntp utc frm fps ppm ppc pt rolling]  (log "transport" rolling))]

    ; as soon as a client with name starting with jack-osc comes online
    ; connect to it via osc and ask it to send jack transport updates
    (expect jack.state.events "client-online"
      (fn [c-name] (= 0 (c-name.index-of "jack-osc")))
      (fn [] (osc-send "/receive" bitmask)
             (osc-send "/status")
             (osc-send "/current")))

    (osc.on "message" (fn [msg] (cond
      (= msg.address "/status.reply")  (on-status.apply    nil msg.args)
      (= msg.address "/pulse")         (on-pulse.apply     nil msg.args)
      (= msg.address "/tick")          (on-tick.apply      nil msg.args)
      (= msg.address "/drift")         (on-drift.apply     nil msg.args)
      (= msg.address "/transport")     (on-transport.apply nil msg.args)
      :else nil)))

    { :tempo tempo
      :meter meter

      :stop (fn [] (osc-send "/stop"))
      :play (fn [] (osc-send "/start"))

      :events events

      :each each }))

(defn update-transport [transport tempo meter]
  (set! transport.tempo tempo)
  (set! transport.meter meter)
  transport)

(defn transport [tempo meter]
  (if persist.transport
    (update-transport persist.transport tempo meter)
    (let [transport (make-transport tempo meter)]
      (set! persist.transport transport)
      transport)))
