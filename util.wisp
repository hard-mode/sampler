(ns util)

(defn range [start length]
  (.map (Array.apply null (Array length))
        (fn [_ i] (+ start i))))
