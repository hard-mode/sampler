(ns osc (:require [wisp.runtime :refer [str]]))

(def ^:private osc (require "node-osc"))

(def port 10000)

(def Client osc.Client)

(def clients {})

(defn send [addr port & args]
  (let [client (aget clients (str "127.0.0.1" port))]
    (if client
      (client.send.apply client args)
      (let [client (osc.Client. "127.0.0.1" port)]
        (console.log "new client" port)
        (set! (aget clients (str "127.0.0.1" port)) client)
        (client.send.apply client args)))))
