(ns midi (:require [wisp.runtime :refer [=]]))

(def ^:private jack (require "./jack.wisp"))
(def ^:private midi (require "midi"))

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
(defn do-get-port-by-name [midi-io port-match callback]
  (let [port-count (midi-io.get-port-count)]
    (loop [port-number 0]
      (if (< port-number port-count)
        (let [port-name (midi-io.get-port-name port-number)]
          (if (= 0 (port-name.index-of port-match))
            (callback port-number)
            (recur (+ port-number 1))))))))

(defn open-virtual-port [m port-name]
  (m.open-virtual-port port-name)
  m)

(defn connect-to-input [port-name]
  (let [m (aget persist.midi.outputs port-name)]
    (if m m
      (let [m  (open-virtual-port (new midi.output) port-name)
            hw (.port (aget jack.clients "a2j") port-name)]
        (set! (aget persist.midi.outputs port-name) m)
        (a2j.started.then (fn []))
        m))))

(defn connect-to-output [port-name]
  (let [m (aget persist.midi.inputs port-name)]
    (if m m
      (let [m  (open-virtual-port (new midi.input) port-name)
            hw (.port (aget jack.clients "a2j") port-name)]
        (set! (aget persist.midi.inputs port-name) m)
        (a2j.started.then (fn []))
        m))))
