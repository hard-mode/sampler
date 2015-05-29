(ns novation-launchpad)

(def ^:private midi (require "../lib/midi.wisp"))
(def ^:private util (require "../lib/util.wisp"))

; hardware

(defn connect
  ([]         (connect (fn [])))
  ([on-input] (midi.connect-controller "a2j:Launchpad" on-input)))

; round buttons

(def circles-top   (.map (util.range 104 8) (fn [col] [176 col])))

(def circles-right (.map (util.range 8)     (fn [row] [176 (+ 8 (* 16 row))])))

; square buttons

(defn join [& args]
  (let [res []]
    (args.map (fn [arg] (set! res (res.concat arg))))
    res))

(defn- by [xx yy f]
  (join (.map (util.range 8)
    (fn [y] (.map (util.range 8)
      (fn [x] (f x y)))))))

; grid mode

(def grid-xy     (by 8 8 (fn [x y] (+ x (* 16 y)))))

(def grid-xy-cw  (by 8 8 (fn [x y] (aget (aget grid-xy (- 7 x)) y))))

(def grid-xy-ccw (by 8 8 (fn [x y] (aget (aget grid-xy x) (- 7 y)))))

(def grid-xy-180 (by 8 8 (fn [x y] (aget (aget grid-xy (- 7 y)) (- 7 x)))))

; TODO drum mode

(def grid-drum     [])

(def grid-drum-cw  [])

(def grid-drum-ccw [])

(def grid-drum-180 [])

; colors

(defn color [red green brightness])

(defn colorize [])

; widgets

(defn- get2 [a x y] (aget (aget a x) y))

(defn keyboard [grid y] [

  (get2 grid (+ 1 y) 0) ; C
  (get2 grid      y  1) ; C#
  (get2 grid (+ 1 y) 1) ; D
  (get2 grid      y  2) ; D#
  (get2 grid (+ 1 y) 2) ; E
  (get2 grid (+ 1 y) 3) ; F
  (get2 grid      y  4) ; F#
  (get2 grid (+ 1 y) 4) ; G
  (get2 grid      y  5) ; G#
  (get2 grid (+ 1 y) 5) ; A
  (get2 grid      y  6) ; A#
  (get2 grid (+ 1 y) 6) ; B
  (get2 grid (+ 1 y) 7) ; C

])

; find controller and establish connection

(def ^:private event2 (require "eventemitter2"))

(defn connect
  ([]          (connect "Launchpad" :xy))
  ([grid-mode] (connect "Launchpad" grid-mode))
  ([hw-name grid-mode]
    (let [input  (midi.connect-to-input  hw-name)
          output (midi.connect-to-output hw-name)
          events (event2.EventEmitter2.)]

      (events.on "refresh" (fn []
        (output.send-message [144 1 70])))

      { :events    events

        :grid-mode grid-mode

        :box       (fn []) 
        :keyboard  (fn []) })))
