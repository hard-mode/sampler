(ns osc (:require [wisp.runtime :refer [str not]]))

(def next-port 10000)

(def ^:private event2 (require "eventemitter2"))
(def ^:private osc    (require "osc"))

(def ^:private backends {
  :socket osc.WebSocketPort
  :udp    osc.UDPPort
  :serial osc.SerialPort })

(defn get-next-port []
  (set! next-port (+ next-port 1))
  (- next-port 1))

(defn client
  ([]
    (client :udp "localhost" (get-next-port)))
  ([p]
    (client :udp "localhost" p))
  ([h p]
    (client :udp h p))
  ([b h p]
    (let [cfg  { :localAddress  h
                 :localPort     p }
          prt  (new (aget backends b) cfg)]
      (prt.open)
      prt)))

(set! persist.osc { :defaultClient (client) })

(defn bind-to
  ([port]
    (bind-to persist.osc.default-client "localhost" port))
  ([host port]
    (bind-to persist.osc.default-client host port))
  ([client host port]
    (fn send-osc-to [addr & args]
      (client.send { :address addr :args args} host port))))
