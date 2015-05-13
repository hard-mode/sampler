(ns spawn)

;;
;; start child processes that persist across session restarts
;;

(def ^:private child (require "child_process"))

(set! persist.spawn (or persist.spawn {}))

(defn spawn [id & args]
  (or
    (aget persist.spawn id)
    (let [p (child.spawn.apply null [ (aget args 0)       ; command
                                      (args.slice 1)      ; args
                                      { :stdio "ignore" } ; opts
                                    ] ) ]
      (set! (aget persist.spawn id) p)
      p)))

(set! module.exports spawn)
