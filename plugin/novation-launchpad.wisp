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

(defn connect
  ([]
    (connect "Launchpad" :xy))
  ([grid-type]
    (connect "Launchpad" grid-type))
  ([hw-name grid-type]
    (let [grid     (aget grids grid-type)
          grid-get (fn [x y] (aget (aget grid x) y))

          input    (midi.connect-to-input  hw-name)
          output   (midi.connect-to-output hw-name)

          events   (event2.EventEmitter2.)
          widgets  (control.group)]

      (let [clear-pad (fn [pad] (output.send-message [144 pad 0]))
            clear     (fn [] (grid.map (fn [row] (row.map clear-pad))))]
        (clear)
        (events.on "clear" clear))

      ;(let [refresh (fn [] (widgets.map (fn [w] (w.refresh))))]
        ;(refresh)
        ;(events.on "refresh" refresh))

      (input.on "message" (fn [t m]
        (let [next-widgets (widgets.update (midi.parse m))]
          (deep.observable-diff widgets.output next-widgets.output (fn [d]
            (let [out (cond (= d.kind "A") d.item.rhs
                            (= d.kind "E") (aget next-widgets.output (aget d.path 0)))]
              (cond (= out.verb :on)  (output.send-message [144 out.data1 70])
                    (= out.verb :off) (output.send-message [144 out.data1 127])))))
          (set! widgets next-widgets))))

      { :events    events
        :widgets   widgets

        :clear     (fn [] (events.emit "clear"))
        :refresh   (fn [] (events.emit "refresh"))

        :gridGet   grid-get

      })))
