(ns midi (:require [wisp.runtime :refer [= and not str]]))

(def ^:private bitwise (require "./bitwise.js"))
(def ^:private jack    (require "./jack.wisp"))
(def ^:private midi    (require "midi"))
(def ^:private Q       (require "q"))

(def ^:private a2j (jack.client "a2j"))
(jack.spawn "a2j" "a2jmidid" "-e")

(set! persist.midi (or persist.midi
  { :inputs  {}
    :outputs {} }))

(defn do-get-port-by-name [midi-io port-match callback]
  (let [port-count (midi-io.get-port-count)]
    (loop [port-number 0]
      (if (< port-number port-count)
        (let [port-name (midi-io.get-port-name port-number)]
          (if (= 0 (port-name.index-of port-match))
            (callback port-number)
            (recur (+ port-number 1))))))))

(defn get-port-by-name [midi-io port-match callback]
  (a2j.started.then (fn [] (do-get-port-by-name midi-io port-match callback))))

(defn connect-output [port-name]
  (let [m (or (aget persist.midi.outputs port-name)
              (new midi.output))]
    (get-port-by-name m port-name
      (fn [port-number] (m.open-port port-number)))
    m))

(defn connect-input [port-name callback]
  (let [m (or (aget persist.midi.inputs port-name)
              (new midi.input))]
    (get-port-by-name m port-name (fn [port-number]
      (m.open-port port-number)
      (m.on "message" (fn [dt message]
        (let [msg (aget message 0)
              d1  (aget message 1)
              d2  (aget message 2)]
          (callback dt msg d1 d2))))))
    m))

(defn connect-controller [controller-name callback]
  (let [i (connect-input  controller-name callback)
        o (connect-output controller-name)]
    { :in   i
      :out  o
      :send (.bind o.send-message o) }))

;;
;; version 2
;; a.k.a. needlessly hairy code
;;

; TODO make these port-finders promises
; also make them useful
(defn- find-a2j-port [port-name-regex]
  (let [regex (RegExp. port-name-regex)
        ports (.-ports (aget jack.state.clients a2j.name))
        ports (.filter (Object.keys ports) (fn [p] (regex.test p)))
        port  (aget ports 0)]
    port))


(defn- find-rtmidi-port [client-name-regex port-name-regex]
  (let [client-regex  (RegExp. client-name-regex)
        client-list   (.filter (Object.keys jack.state.clients)
                        (fn [c] (client-regex.test c)))
        port-regex    (RegExp. port-name-regex)]
    (client-list.map (fn [client]
      (let [client-ports (.-ports (aget jack.state.clients client))]
        (log "->" client-ports)))))
  nil)


(defn expect-hardware-port [port-name-regex]
  (let [deferred (Q.defer)
        found    (fn [port-name] (deferred.resolve [a2j.name port-name]))
        finder   nil]
    (.then (Q.all [jack.after-session-start a2j.started]) (fn []
      (let [hw-port (find-a2j-port port-name-regex)]
        (if hw-port
          (found hw-port)
          (do (set! finder (fn [c p]
                (if (and (= a2j.name c) (.test (RegExp. port-name-regex) p))
                  (do (found p) (jack.state.events.off "port-online" finder)))))
              (jack.state.events.on "port-online" finder))))))
    deferred.promise))


(defn expect-virtual-port [client-name-regex port-name-regex]
  (let [deferred (Q.defer)
        found    (fn [c-name p-name] (deferred.resolve [c-name p-name]))
        finder   nil]
    (jack.after-session-start.then (fn []
      (let [rtmidi-port (find-rtmidi-port client-name-regex port-name-regex)]
        (if rtmidi-port
          (found rtmidi-port.client rtmidi-port.port)
          (do (set! finder (fn [c p]
                (if (and (.test (RegExp. client-name-regex) c)
                         (.test (RegExp. port-name-regex)   p))
                  (do (found c p) (jack.state.events.off "port-online" finder)))))
              (jack.state.events.on "port-online" finder))))))
    deferred.promise))


(defn connect-to-input [port-name]
  (let [m (aget persist.midi.inputs port-name)]
    (or m (let [m       (new midi.input)
                vpcname "^RtMidi Input Client"
                vppname (str "^" port-name)
                hppname (str "^" port-name ".+(capture)")
                ports-online
                  (Q.all [ (expect-hardware-port hppname)
                           (expect-virtual-port vpcname vppname) ])
                connected (Q.deferred)]
      (set! m.after-online ports-online)
      (set! m.after-connect connected.promise)
      (set! (aget persist.midi.inputs port-name) m)
      (jack.after-session-start.then (fn []
        (m.open-virtual-port port-name)
        (.then ports-online 
          (fn [ports] (let [out-port (aget ports 0)
                            in-port  (aget ports 1)]
            (jack.connect-by-name
              (aget out-port 0) (aget out-port 1)
              (aget in-port  0) (aget in-port  1)))))))
      m))))


(defn connect-to-output [port-name]
  (let [m (aget persist.midi.outputs port-name)]
    (or m (let [m       (new midi.output)
                vpcname "^RtMidi Output Client"
                vppname (str "^" port-name)
                hppname (str "^" port-name ".+(playback)")
                ports-online
                  (Q.all [ (expect-virtual-port vpcname vppname)
                           (expect-hardware-port hppname) ]
                connected (Q.deferred))]
      (set! m.after-online ports-online)
      (set! m.after-connect connected.promise)
      (set! (aget persist.midi.outputs port-name) m)
      (jack.after-session-start.then (fn []
        (m.open-virtual-port port-name)
        (.then ports-online
          (fn [ports] (let [out-port (aget ports 0)
                            in-port  (aget ports 1)]
            (jack.connect-by-name
              (aget out-port 0) (aget out-port 1)
              (aget in-port  0) (aget in-port  1)))))))
      m))))

(def event-types
  { 128 :note-off
    144 :note-on
    160 :key-pressure
    176 :control
    192 :program
    208 :pressure
    224 :pitch-bend })

(defn parse
  ([msg] (parse (aget msg 0) (aget msg 1) (aget msg 2)))
  ([d1 d2 d3]
    (let [channel (bitwise.and d1 15)
          event   (aget event-types (bitwise.and d1 240))]
      {:channel channel :event event :data1 d2 :data2 d3})))

(defn match
  [mask msg]
  (.reduce
    (Object.keys mask)
    (fn [prev curr]
      (and prev (= (aget mask curr) (aget msg curr))))
    true))
