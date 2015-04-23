(ns spawn)

(def ^:private child (require "child_process"))

(set! session.persist.spawn (or session.persist.spawn {}))

(defn spawn [id & args]
  (or
    (aget session.persist.spawn id)
    (let [p (child.spawn.apply null args)]
      (set! (aget session.persist.spawn id) p)
      p)))

(set! module.exports spawn)
