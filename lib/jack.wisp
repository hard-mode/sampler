(ns jack (:require [wisp.runtime :refer [str = not &]]))

(def ^:private bitwise  (require "./bitwise.js"))
(def ^:private dbus     (require "dbus-native"))
(def ^:private event2   (require "eventemitter2"))
(def ^:private do-spawn (require "./spawn.wisp"))

(def started false)

(defn parse-ports [data]
  (let [ports {}]
    (data.map (fn [port]
      (let [port-number (aget port 0)
            port-name   (aget port 1)
            test-bit    (fn [bit] (= bit (bitwise.and (aget port 2) bit)))]
        (set! (aget ports port-number)
          { :name       port-name
            :canMonitor (test-bit 0x8)
            :isInput    (test-bit 0x1)
            :isOutput   (test-bit 0x2)
            :isPhysical (test-bit 0x4)
            :isTerminal (test-bit 0x10)
            :signal     (if (aget port 3) "event" "audio") }))))
    ports))

(defn parse-clients [data]
  (let [clients {}]
    (data.map (fn [client]
      (set! (aget clients (aget client 0))
        { :name  (aget client 1)
          :ports (parse-ports (aget client 2)) })))
    clients))

(defn parse-connections [data]
  (let [connections {}]
    (data.map (fn [connection]
      (let [output-client (aget session.persist.jack.clients (aget connection 0))
            output-port   (aget output-client.ports          (aget connection 2))
            input-client  (aget session.persist.jack.clients (aget connection 4))
            input-port    (aget input-client.ports             (aget connection 6))]
        (set! (aget connections (aget connection 8)
          { :output output-port
            :input  input-port })))))
  connections))

(defn update [cb]
  (session.persist.jack.patchbay.GetGraph "0" (fn [err graph clients connections] 
    (if err (throw err))
    (set! session.persist.jack.clients     (parse-clients clients))
    (set! session.persist.jack.connections (parse-connections connections))
    (if cb (cb)))))

(defn bind []
  (let [patchbay session.persist.jack.patchbay
        events   session.persist.jack.events]
    (patchbay.on
      "ClientAppeared"
      (fn [& args] (let [client (aget args 1)]
        (log (str "client " client " appeared"))
        (update (fn [] (events.emit "client-online" client))))))
    (patchbay.on
      "ClientDisappeared"
      (fn [& args] (let [client (aget args 1)]
        (log (str "client " client " disappeared"))
        (update (fn [] (events.emit "client-offline" client))))))
    (patchbay.on
      "PortAppeared"
      (fn [& args] (let [client (aget args 1)
                         port   (aget args 3)]
        (log (str "port " client ":" port " appeared"))
        (update (fn [] (events.emit "port-online" client port))))))
    (patchbay.on
      "PortDisappeared"
      (fn [& args] (let [client (aget args 1)
                         port   (aget args 3)]
        (log (str "port " client ":" port " disappeared"))
        (update (fn [] (events.emit "port-offline" client port))))))
    (patchbay.on
      "PortsConnected"
      (fn [& args] (let [out-client (aget args 1)
                         out-port   (aget args 3)
                         in-client  (aget args 5)
                         in-port    (aget args 7)]
        (log (str "ports " out-client ":" out-port
                  " and "  in-client  ":" in-port  " connected"))
        (update (fn [] (events.emit "connected" out-client out-port
                                                in-client  in-port))))))
    (patchbay.on
      "PortsDisconnected"
      (fn [& args] (let [out-client (aget args 1)
                         out-port   (aget args 3)
                         in-client  (aget args 5)
                         in-port    (aget args 7)]
        (log (str "ports " out-client ":" out-port
                  " and "  in-client  ":" in-port  " disconnected"))
        (update (fn [] (events.emit "disconnected" out-client out-port
                                                   in-client  in-port))))))
    (patchbay.on "GraphChanged"
      (fn []
        (log (str "graph changed"))))
    (set! started true)
    (events.emit "started")))

(defn init []
  (let [dbus         (require "dbus-native")
        dbus-name    "org.jackaudio.service"
        dbus-path    "/org/jackaudio/Controller"
        dbus-service (.get-service (dbus.session-bus) dbus-name)]
    (set! session.persist.jack { :events (event2.EventEmitter2.) })
		(dbus-service.get-interface dbus-path "org.jackaudio.JackControl"
      (fn [err control] (if err (throw err))
        (log "connected to jack control")
        (set! session.persist.jack.control control)
        (control.StartServer (fn []
          (log "jack server started")
			    (dbus-service.get-interface dbus-path "org.jackaudio.JackPatchbay"
            (fn [err patchbay] (if err (throw err))
              (log "connected to jack patchbay")
              (set! session.persist.jack.patchbay patchbay)
              (update bind)))))))))

; persist and shorthand
(if (not session.persist.jack) (init))
(def ^:private jack session.persist.jack)

; only execute spawns after the session has opened
(defn spawn [id & args]
  (args.unshift id)
  (if started
    (do-spawn.apply nil args)
    (jack.events.once "started" (fn [] (do-spawn.apply nil args)))))

(defn connect-by-name [output-c output-p input-c input-p]
  (jack.patchbay.ConnectPortsByName output-c output-p input-c input-p))

(defn connect-by-id [output-c output-p input-c input-p]
  (jack.patchbay.ConnectPortsByID output-c output-p input-c input-p))
