(ns util)


(defn range
  ([length] (range 0 length))
  ([start length]
    (.map (Array.apply null (Array length))
      (fn [_ i] (+ start i)))))


(defn counter
  ([] (counter 0))
  ([i]
    (let [ state { :value i } ]
      (fn []
        (set! state.value (+ 1 state.value))
        (- state.value 1)))))
