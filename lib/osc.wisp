(ns osc (:require [wisp.runtime :refer [str not]]))

(def ^:private osc (require "node-osc"))

(def ^:private next-port 10000)

(def clients {})

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
  (osc.Server. port "0.0.0.0"))

(set! client.next-port 10000)
