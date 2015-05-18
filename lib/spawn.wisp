(ns spawn)

;;
;; start child processes that persist across session restarts
;;

(def ^:private child (require "child_process"))

(set! persist.spawn (or persist.spawn {}))

(defn spawn [id & args]
  (or
    (aget persist.spawn id)
    (let [p (child.spawn.apply null [ (aget args 0)        ; command
                                      (args.slice 1)       ; args
                                      { :stdio "inherit" } ; opts
                                    ] ) ]
      (set! (aget persist.spawn id) p)
      (persist.cleanup.push (fn []
        (log "Killing" (aget args 0))
        (p.kill "SIGKILL")))
      p)))

(set! module.exports spawn)
