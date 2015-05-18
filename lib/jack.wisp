(ns jack (:require [wisp.runtime :refer [str = and not]]))

;;
;; interact with jack-audio-connection-kit's patchbay
;;

(def ^:private bitwise  (require "./bitwise.js"))
(def ^:private dbus     (require "dbus-native"))
(def ^:private do-spawn (require "./spawn.wisp"))
(def ^:private event2   (require "eventemitter2"))
(def ^:private Q        (require "q"))

; initialize state

(set! persist.jack (or persist.jack
  { :started     false
    :events      (event2.EventEmitter2.)
    :clients     {}
    :connections {} }))

; shorthands
(def state       persist.jack)
(def events      persist.jack.events)
(def clients     persist.jack.clients)
(def connections persist.jack.connections)

; parsers
(defn parse-ports [data]
  (let [ports {}]
    (data.map (fn [port]
      (let [port-id   (aget port 0)
            port-name (aget port 1)
            test-bit  (fn [bit] (= bit (bitwise.and (aget port 2) bit)))]
        (set! (aget ports port-name)
          { :id         port-id
            :name       port-name
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
      (set! (aget clients (aget client 1))
        { :id    (aget client 0)
          :name  (aget client 1)
          :ports (parse-ports (aget client 2)) })))
    clients))

(defn parse-connections [data]
  (let [connections {}]
    (data.map (fn [connection]
      (let [out-client (aget clients          (aget connection 1))
            out-port   (aget out-client.ports (aget connection 3))
            in-client  (aget clients          (aget connection 5))
            in-port    (aget in-client.ports  (aget connection 7))]
        (set! (aget connections (aget connection 8)
          { :output out-port
            :input  in-port })))))
  connections))

; state updater
(defn update [cb]
  (persist.jack.patchbay.GetGraph "0" (fn [err graph client-list connection-list]
    (if err (throw err))
    (set! clients     (parse-clients     client-list))
    (set! connections (parse-connections connection-list))
    (if cb (cb)))))

; event handlers
(defn bind []
  (let [patchbay persist.jack.patchbay]
    (patchbay.on
      "ClientAppeared"
      (fn [& args] (let [client (aget args 2)]
        (log (str "client appeared:    " client))
        (update (fn [] (events.emit "client-online" client))))))
    (patchbay.on
      "ClientDisappeared"
      (fn [& args] (let [client (aget args 2)]
        (log (str "client disappeared: " client))
        (update (fn [] (events.emit "client-offline" client))))))
    (patchbay.on
      "PortAppeared"
      (fn [& args] (let [client (aget args 2)
                         port   (aget args 4)]
        (log (str "port appeared:      " client ":" port))
        (update (fn [] (events.emit "port-online" client port))))))
    (patchbay.on
      "PortDisappeared"
      (fn [& args] (let [client (aget args 2)
                         port   (aget args 4)]
        (log (str "port disappeared:   " client ":" port))
        (update (fn [] (events.emit "port-offline" client port))))))
    (patchbay.on
      "PortsConnected"
      (fn [& args] (let [out-client (aget args 2)
                         out-port   (aget args 4)
                         in-client  (aget args 6)
                         in-port    (aget args 8)]
        (log (str "ports connected:    " out-client ":" out-port
                                  " -> "  in-client ":"  in-port))
        (update (fn [] (events.emit "connected" out-client out-port
                                                in-client  in-port))))))
    (patchbay.on
      "PortsDisconnected"
      (fn [& args] (let [out-client (aget args 2)
                         out-port   (aget args 4)
                         in-client  (aget args 6)
                         in-port    (aget args 8)]
        (log (str "ports disconnected: " out-client ":" out-port
                                 " >< "  in-client ":"  in-port))
        (update (fn [] (events.emit "disconnected" out-client out-port
                                                   in-client  in-port))))))
    (patchbay.on "GraphChanged"
      (fn []))
        ;(log (str "graph changed"))))
    (set! started true)
    (events.emit "started")))

; initializer
(defn init []
  (let [dbus         (require "dbus-native")
        dbus-name    "org.jackaudio.service"
        dbus-path    "/org/jackaudio/Controller"
        dbus-service (.get-service (dbus.session-bus) dbus-name)]
		(dbus-service.get-interface dbus-path "org.jackaudio.JackControl"
      (fn [err control] (if err (throw err))
        (log "connected to jack control")
        (set! persist.jack.control control)
        (control.StartServer (fn []
          (log "jack server started")
			    (dbus-service.get-interface dbus-path "org.jackaudio.JackPatchbay"
            (fn [err patchbay] (if err (throw err))
              (log "connected to jack patchbay")
              (set! persist.jack.patchbay patchbay)
              (update bind)))))))))

; autostart
(if (not persist.jack.started) (init))

; execute as soon as the session has started
(def after-session-start
  (let [deferred (Q.defer)]
    (if persist.jack.started
      (deferred.resolve)
      (events.on "started" deferred.resolve))
    deferred.promise))

; spawn a child process once the session has started
; so that a ClientAppeared notification can be received
(defn spawn [id & args]
  (log "jack.spawn" id args)
  (args.unshift id)
  (after-session-start.then (fn [] (do-spawn.apply nil args))))


;;
;; client and port operations
;;

(defn connect-by-name [output-c output-p input-c input-p]
  (log "connecting:        "
    (str output-c ":" output-p)
    (str input-c  ":" input-p))
  (persist.jack.patchbay.ConnectPortsByName
    output-c output-p input-c input-p)
  (persist.cleanup.push (fn []
    (log "Disconnecting" output-c output-p input-c input-p)
    (persist.jack.patchbay.DisconnectPortsByName
      output-c output-p input-c input-p))))

(defn connect-by-id [output-c output-p input-c input-p]
  (persist.jack.patchbay.ConnectPortsByID output-c output-p input-c input-p))

(defn find-client [client-name]
  (.indexOf (Object.keys clients) client-name))

(defn client-found [client-name]
  (not (= -1 (find-client client-name))))

(defn find-port [client-name port-name]
  (let [client  (or (aget clients client-name)
                    { :ports {} })
        ports   (Object.keys client.ports)]
    (.indexOf ports port-name)))

(defn port-found [client-name port-name]
  (not (= -1 (find-port client-name port-name))))

(defn port [client-name port-name]
  (let [deferred  (Q.defer)

        state     { :name    port-name  
                    :client  client-name
                    :started deferred.promise
                    :online  false }

        start     (fn [] (set! state.online true)
                         (deferred.resolve))

        starter   nil ]

    (set! starter (fn [c p]
      (if (and (= c client-name) (= p port-name)) (do
        (start)
        (events.off "port-online" starter)))))

    (after-session-start.then (fn []
      (if (port-found client-name port-name)
        (start)
        (events.on "port-online" starter))))
    
    state))

(defn client [client-name]
  (let [deferred  (Q.defer)

        state     { :name     client-name
                    :online   false
                    :started  deferred.promise
                    :events   (event2.EventEmitter2.)
                    :port     (port.bind null client-name) }

        start     (fn [] (set! state.online true)
                         (deferred.resolve))

        starter   nil]

    (set! starter (fn [c]
      (if (= c client-name) (do
        (start)
        (events.off "client-online" starter)))))

    (after-session-start.then (fn []
      (if (client-found client-name)
        (start)
        (events.on "client-online" starter))))

    state))

(def system (client "system"))

(defn chain [chain-name & links]
  (links.map (fn [link]
    (let [out (aget link 0)
          out (.port (aget out 0) (aget out 1))
          inp (aget link 1)
          inp (.port (aget inp 0) (aget inp 1))]
      (.then (Q.all [ out.started
                      inp.started ])
        (fn [] (connect-by-name out.client out.name
                                inp.client inp.name)))))))
