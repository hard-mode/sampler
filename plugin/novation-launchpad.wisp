(ns novation-launchpad (:require [wisp.runtime :refer [=]]))

(def ^:private control (require "../lib/control.wisp"))
(def ^:private deep    (require "deep-diff"))
(def ^:private event2  (require "eventemitter2"))
(def ^:private midi    (require "../lib/midi.wisp"))
(def ^:private util    (require "../lib/util.wisp"))

;;
;; colors
;;

(defn color [red green brightness])
(defn colorize [])

;;
;; pad locations
;;

(def circles-top   (.map (util.range 104 8) (fn [col] [176 col])))
(def circles-right (.map (util.range 8)     (fn [row] [176 (+ 8 (* 16 row))])))

(defn- by [xx yy f]
  (.reduce
    (.map (util.range 8)
      (fn [y] (.map (util.range 8)
        (fn [x] (f x y)))))
    (fn [a b] (a.push b) a)
    []))

(def grids (let [grid-xy (by 8 8 (fn [x y] (+ x (* 16 y))))] {
  :xy     grid-xy 
  :xy-cw  (by 8 8 (fn [x y] (aget (aget grid-xy (- 7 x)) y)))
  :xy-ccw (by 8 8 (fn [x y] (aget (aget grid-xy x) (- 7 y))))
  :xy-180 (by 8 8 (fn [x y] (aget (aget grid-xy (- 7 y)) (- 7 x))))
  ; todo drum mode grids
}))

;;
;; widgets
;;

(defn button
  ([i o g row col] (button i o g row col 127))
  ([i o g row col color]
    { :refresh (fn [] (o.send-message [144 (g row col) color]))}))

(defn keyboard
  ([i o g row] (keyboard i o g row 127))
  ([i o g row color] (let [
      pad-map
      [ (g (+ 1 row) 0) ; C
        (g      row  1) ; C#
        (g (+ 1 row) 1) ; D
        (g      row  2) ; D#
        (g (+ 1 row) 2) ; E
        (g (+ 1 row) 3) ; F
        (g      row  4) ; F#
        (g (+ 1 row) 4) ; G
        (g      row  5) ; G#
        (g (+ 1 row) 5) ; A
        (g      row  6) ; A#
        (g (+ 1 row) 6) ; B
        (g (+ 1 row) 7) ] ; C
      widget
      { :refresh (fn [] (pad-map.map (fn [n] (o.send-message [144 n color])))) }]
    widget)))

;;
;; find controller and establish connection
;;

(def ^:private flatten (require "flatten"))

(defn connect
  ([]
    (connect { :name "Launchpad"
               :grid :xy }))
  ([options & controls]
    (let [grid     (or (aget grids options.grid) (aget grids :xy))
          grid-get (fn [x y] (aget (aget grid x) y))

          input    (midi.connect-to-input  (or options.name "Launchpad"))
          output   (midi.connect-to-output (or options.name "Launchpad"))

          events   (event2.EventEmitter2.)]

      (let [clear-pad (fn [pad] (output.send-message [144 pad 0]))
            clear     (fn [] (grid.map (fn [row] (row.map clear-pad))))]
        (output.after-online.then (fn [] (clear)))
        (events.on "clear" clear))

      (input.on "message" (fn [dt msg] (events.emit "input" (midi.parse msg))))

      { :events    events

        :clear     (fn [] (events.emit "clear"))
        :send      (fn [m d1 d2]
                     (log "-> then")
                     (output.after-online.then (fn [] (log "-> now" m d1 d2) (output.send-message [m d1 d2]))))

        :gridGet   grid-get })))
