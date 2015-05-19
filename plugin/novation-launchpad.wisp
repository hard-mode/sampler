(ns novation-launchpad)

(def ^:private util (require "../lib/util.wisp"))

(defn- join [& args]
  (let [res []]
    (args.map (fn [arg] (set! res (res.concat arg))))
    res))

(def circles-top   (.map (util.range 104 8) (fn [col] [176 col])))

(def circles-right (.map (util.range 8)     (fn [row] [176 (+ 8 (* 16 row))])))

(defn- eight-by-eight [f]
  (join (.map (util.range 8)
    (fn [y] (.map (util.range 8)
      (fn [x] (f x y)))))))

(def grid-xy     (eight-by-eight (fn [x y] [144 (+ x (* 16 y))])))

(def grid-xy-cw  (eight-by-eight (fn [x y] (aget (aget grid-xy (- 7 x)) y))))

(def grid-xy-ccw (eight-by-eight (fn [x y] (aget (aget grid-xy x) (- 7 y)))))

(def grid-xy-180 (eight-by-eight (fn [x y] (aget (aget grid-xy (- 7 y)) (- 7 x)))))

(console.log grid-xy-180)

; todo

(def grid-drum     [])

(def grid-drum-cw  [])

(def grid-drum-ccw [])

(def grid-drum-180 [])

(defn color [red green brightness])


