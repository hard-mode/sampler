(ns spawn)

(def ^:private child (require "child_process"))

(set! persist.spawn (or persist.spawn {}))

(defn spawn [id & args]
  (or
    (aget persist.spawn id)
    (let [p (child.spawn.apply null [(aget args 0) (args.slice 1)])]
      (set! (aget persist.spawn id) p)
      p)))

(set! module.exports spawn)
