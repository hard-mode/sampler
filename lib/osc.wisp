(ns osc (:require [wisp.runtime :refer [str not]]))

(def next-port 10000)

;;
;; v1
;;

(def ^:private osc (require "node-osc"))
(def clients {})
(def servers {})

(defn client
  ([] (set!   next-port   (+ next-port 1))
      (client "localhost" (- next-port 1)))
  ([port] (client "localhost" port))   ; assume local
  ([host port]                         ; now we talkin
    (let [id (str host ":" port)
          c  (aget clients id)]
      (if (not c) (set! c (osc.Client. host port)))
      { :send (fn [& args] (c.send.apply c args))
        :host host
        :port port })))

(defn server [port]
  (or (aget servers port)
      (let [s (osc.Server. port "0.0.0.0")]
        (set! (aget servers port) s)
        s)))

;;
;; v2
;;

(def ^:private event2 (require "eventemitter2"))
(def ^:private osc    (require "osc"))

(def ^:private backends {
  :socket osc.WebSocketPort
  :udp    osc.UDPPort
  :serial osc.SerialPort })

(defn port
  ([]    (set! next-port        (+ next-port 1))
         (port :udp "localhost" (- next-port 1)))
  ([p]   (port :udp "localhost" p))
  ([h p] (port :udp h p))
  ([b h p]
    (let [cfg  { :localAddress  h
                 :localPort     p }
          prt  (new (aget backends b) cfg)]
      (prt.open)
      prt)))
