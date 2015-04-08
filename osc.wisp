(ns osc (:require [wisp.runtime :refer [str]]))

(def ^:private osc (require "node-osc"))

(def Client osc.Client)

(def clients {})

(defn send [addr port & args]
  (let [client (aget clients (str "127.0.0.1" port))]
    (client.send.apply client args)))
