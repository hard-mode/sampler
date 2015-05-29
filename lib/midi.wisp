(ns midi (:require [wisp.runtime :refer [= and not]]))

(def ^:private jack (require "./jack.wisp"))
(def ^:private midi (require "midi"))
(def ^:private Q    (require "q"))

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


; version 2


(defn- find-a2j-port [port-name-regex]
  (let [regex (RegExp. port-name-regex)
        ports (.-ports (aget jack.state.clients a2j.name))
        ports (.filter (Object.keys ports) regex.test)
        port  (aget ports 0)]
    port))


(defn expect-hardware-port [port-name-regex]
  (let [deferred (Q.defer)
        found    (fn [port-name] (deferred.resolve port-name))
        finder   nil]
    (.then (Q.all [jack.after-session-start a2j.started]) (fn []
      (if (find-a2j-port port-name-regex)
        (found port-name)
        (do (set! finder (fn [c p]
              (if (and (= a2j.name c) (.test (RegExp. port-name-regex) p))
                (do (found p) (jack.state.events.off "port-online" finder)))))
            (jack.state.events.on "port-online" finder)))))
    deferred.promise))


(defn- find-rtmidi-port [client-name-regex port-name-regex]
  (let [c-regex (RegExp. client-name-regex)
        p-regex (RegExp. port-name-regex)
        ports (.-ports (aget jack.state.clients a2j.name))
        ports (.filter (Object.keys ports) regex.test)
        port  (aget ports 0)]
    port))


(defn expect-virtual-port [client-name-regex port-name-regex]
  (let [deferred (Q.defer)
        found    (fn [c-name p-name] (deferred.resolve c-name p-name))
        finder   nil]
    (jack.after-session-start.then (fn []
      (let [rtmidi-port (find-rtmidi-port client-name-regex port-name-regex)]
        (if rtmidi-port
          (found rtmidi-port.client rtmidi-port.port)
          (do (set! finder (fn [c p]
                (if (and (.test (RegExp. client-name-regex) c)
                         (.test (RegExp. port-name-regex)   p))
                  (do (found c p) (jack.state.events.off "port-online" finder)))))
              (jack.state.events.on "port-online" finder)))))
    deferred.promise)))


(defn connect-to-input [port-name]
  (let [m (aget persist.midi.outputs port-name)]
    (or m (let [m (new midi.output)]
      (set! (aget persist.midi.outputs port-name) m)
      (jack.after-session-start.then (fn []
        (m.open-virtual-port port-name)
        (a2j.started.then (fn []
          (let [ports (.-ports (aget jack.state.clients a2j.name))
                ports (.filter (Object.keys ports)
                  (fn [p] (and (= 0 (p.index-of port-name))
                               (not (= -1 (p.index-of "(capture)"))))))
                port  (aget ports 0)]
            (log port))))))
      m))))


(defn connect-to-output [port-name]
  (let [m (aget persist.midi.inputs port-name)]
    (or m (let [m (new midi.input)]
      (set! (aget persist.midi.inputs port-name) m)
      (jack.after-session-start.then (fn []
        (m.open-virtual-port port-name)))
      m))))
