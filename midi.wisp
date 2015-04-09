(ns midi (:require [wisp.runtime :refer [=]]))

(def ^:private midi (require "midi"))

(defn get-port-by-name [midi-io port-match callback]
  (let [port-count (midi-io.get-port-count)]
    (loop [port-number 0]
      (if (< port-number port-count)
        (let [port-name (midi-io.get-port-name port-number)]
          (if (= 0 (port-name.index-of port-match))
            (callback port-number)
            (recur (+ port-number 1))))))))

(defn connect-output [port-name]
  (let [m (new midi.output)]
    (get-port-by-name m port-name (fn [port-number]
      (console.log "OUT ::" port-number (m.get-port-name port-number))
      (m.open-port port-number)))
    m))

(defn connect-input [port-name callback]
  (let [m (new midi.input)]
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
  { :in  (connect-input  controller-name callback)
    :out (connect-output controller-name) })