(ns jack (:require [wisp.runtime :refer [str = not &]]))

(def ^:private bitwise (require "./bitwise.js"))
(def ^:private event2  (require "eventemitter2"))
(def ^:private dbus    (require "dbus-native"))

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
      (fn [& args] (let [client-name (aget args "2")]
        (log (str "client " client-name " appeared"))
        (update (fn [] (events.emit "client-online" client-name))))))
    (patchbay.on
      "ClientDisappeared"
      (fn [& args] (let [client-name (aget args "2")]
        (log (str "client " client-name " disappeared"))
        (update (fn [] (events.emit "client-offline" client-name))))))
    (patchbay.on
      "PortAppeared"
      (fn [& args] (let [client-name (aget args "2")
                         port-name   (aget args "4")]
        (log (str "port " client-name ":" port-name " appeared"))
        (update (fn [] (events.emit "port-online" client-name port-name))))))
    (patchbay.on
      "PortDisappeared"
      (fn [& args] (let [client-name (aget args "2")
                         port-name   (aget args "4")]
        (log (str "port " client-name ":" port-name " disappeared"))
        (update (fn [] (events.emit "port-offline" client-name port-name))))))
    (patchbay.on
      "PortsConnected"
      (fn [& args] (let [out-client-name (aget args "2")
                         out-port-name   (aget args "4")
                         in-client-name  (aget args "6")
                         in-port-name    (aget args "8")]
        (log (str "ports " out-client-name ":" out-port-name
                  " and "  in-client-name  ":" in-port-name  " connected"))
        (update (fn [] (events.emit "connected" out-client-name out-port-name
                                                in-client-name  in-port-name))))))
    (patchbay.on
      "PortsDisconnected"
      (fn [& args] (let [out-client-name (aget args "2")
                         out-port-name   (aget args "4")
                         in-client-name  (aget args "6")
                         in-port-name    (aget args "8")]
        (log (str "ports " out-client-name ":" out-port-name
                  " and "  in-client-name  ":" in-port-name  " disconnected"))
        (update (fn [] (events.emit "disconnected" out-client-name out-port-name
                                                   in-client-name  in-port-name))))))
    (patchbay.on "GraphChanged"
      (fn []
        (log (str "graph changed"))))))

(defn init []
  (let [dbus         (require "dbus-native")
        dbus-name    "org.jackaudio.service"
        dbus-path    "/org/jackaudio/Controller"
        dbus-service (.get-service (dbus.session-bus) dbus-name)]
		(dbus-service.get-interface dbus-path "org.jackaudio.JackControl"
      (fn [err control] (if err (throw err))
        (log "connected to jack control")
        (set! session.persist.jack { :control control :events (event2.EventEmitter2.) })
        (control.StartServer (fn []
          (log "jack server started")
			    (dbus-service.get-interface dbus-path "org.jackaudio.JackPatchbay"
            (fn [err patchbay] (if err (throw err))
              (log "connected to jack patchbay")
              (set! session.persist.jack.patchbay patchbay)
              (update bind)))))))))

(if (not session.persist.jack) (init))

; only execute spawns after the session has opened
;(def ^:private jack session.persist.jack)
(def ^:private jack {
  :open (fn []) :once (fn []) :on (fn []) :createClient (fn [] { :once (fn []) :createClient (fn [] {}) })
  :spawn (fn []) :force-connect (fn []) })
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

(defn force-connect [output-c output-p input-c input-p]
  (console.log "jack.force-connect" output-c output-p input-c input-p)
  (jack.dbus.ConnectPortsByName output-c output-p input-c input-p))

(def system (jack.create-client "system"))

;(client.on "port-registered" (fn [] (console.log "port reg")))
