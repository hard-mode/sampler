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

(def grid-xy     (by 8 8 (fn [x y] [144 (+ x (* 16 y))])))

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
  (get2 grid      y  1) ; black keys
  (get2 grid      y  2)
  (get2 grid      y  4)
  (get2 grid      y  5)
  (get2 grid      y  6)

  (get2 grid (+ 1 y) 0) ; white keys
  (get2 grid (+ 1 y) 1)
  (get2 grid (+ 1 y) 2)
  (get2 grid (+ 1 y) 3)
  (get2 grid (+ 1 y) 4)
  (get2 grid (+ 1 y) 5)
  (get2 grid (+ 1 y) 6)
  (get2 grid (+ 1 y) 7) ])
