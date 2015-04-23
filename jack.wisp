(ns jack (:require [wisp.runtime :refer [str =]]))

(def ^:private native (require "node-jack"))
(set! session.persist.jack (or session.persist.jack
  { :client      (native.Client. "hardmode-session") 
    :connections []}))

(def ^:private client session.persist.jack.client)

(def connections [])

(defn connect    [port-a port-b])
(defn disconnect [port-a port-b])

(client.on "port-registered" (fn [] (console.log "port reg")))
