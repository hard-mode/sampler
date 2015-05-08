(ns jack (:require [wisp.runtime :refer [str =]]))

(def ^:private sanity (require "jack-sanity"))

(set! session.persist.jack (or session.persist.jack
  (let [logger (sanity.createLogger)
        app    (sanity.createApplication logger)]
    { :app         app
      :logger      logger
      :connections []})))

(def ^:private client session.persist.jack.client)

(def connections [])

(defn connect    [port-a port-b])
(defn disconnect [port-a port-b])

;(client.on "port-registered" (fn [] (console.log "port reg")))
