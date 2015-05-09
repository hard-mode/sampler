(ns jack (:require [wisp.runtime :refer [str =]]))

(set! session.persist.jack (or session.persist.jack
  (let [sanity (require "jack-sanity")
        dbus   (require "dbus-native")]
    (sanity.create-session-controller
      (.get-service (dbus.session-bus) sanity.JackBusName)))))\

; only execute spawns after the session has opened
(def ^:private jack session.persist.jack)
(def ^:private is-open false)
(jack.on "open" (fn [] (set! is-open true)))
(jack.open)

(defn- do-spawn [cmd args]
  (let [proc (jack.create-process cmd args)]
    (proc.open)
    proc))

(defn spawn [cmd & args]
  (console.log "jack.spawn" cmd args is-open)
  (if is-open
    (do-spawn cmd args)
    (jack.once "open" (fn [] (do-spawn cmd args)))))

(defn client [client-name]
  (jack.create-client client-name))

(defn combine [client proc]
  (jack.combine client proc))

(def system (jack.create-client "system"))

;(client.on "port-registered" (fn [] (console.log "port reg")))
