(ns util)

(defn range
  ([length] (range 0 length))
  ([start length]
    (.map (Array.apply null (Array length))
      (fn [_ i] (+ start i)))))
