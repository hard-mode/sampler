(ns midi (:require [wisp.runtime :refer [=]]))

(def ^:private jack (require "./jack"))
(def ^:private midi (require "midi"))

(jack.spawn "a2jmidid" "-e")

(set! session.persist.midi (or session.persist.midi
  { :input  (new midi.input)
    :output (new midi.output) }))

(defn get-port-by-name [midi-io port-match callback]
  (let [port-count (midi-io.get-port-count)]
    (loop [port-number 0]
      (if (< port-number port-count)
        (let [port-name (midi-io.get-port-name port-number)]
          (console.log "PORT" port-number port-name port-match)
          (if (= 0 (port-name.index-of port-match))
            (callback port-number)
            (recur (+ port-number 1))))))))

(defn connect-output [port-name]
  (let [m session.persist.midi.output]
    (get-port-by-name m port-name (fn [port-number]
      (console.log "OUT ::" port-number (m.get-port-name port-number))
      (m.open-port port-number)))
    m))

(defn connect-input [port-name callback]
  (let [m session.persist.midi.input]
    (get-port-by-name m port-name (fn [port-number]
      (console.log " IN ::" port-number (m.get-port-name port-number))
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
