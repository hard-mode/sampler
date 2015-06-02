(ns novation-launchpad)

(def ^:private event2 (require "eventemitter2"))
(def ^:private midi   (require "../lib/midi.wisp"))
(def ^:private util   (require "../lib/util.wisp"))

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
          widgets  []]

      (let [clear-pad (fn [pad] (output.send-message [144 pad 0]))
            clear     (fn [] (grid.map (fn [row] (row.map clear-pad))))]
        (clear)
        (events.on "clear" clear))

      (let [refresh (fn [] (widgets.map (fn [w] (w.refresh))))]
        (refresh)
        (events.on "refresh" refresh))

      { :events    events

        :clear     (fn [] (events.emit "clear"))
        :refresh   (fn [] (events.emit "refresh"))

        :gridType  grid-type

        :page      (fn [])
        :box       (fn [])
        :switch    (fn []) 
        :keyboard  (fn
          ([row]       (widgets.push (keyboard input output grid-get row)))
          ([row color] (widgets.push (keyboard input output grid-get row color))))

      })))
