(ns boot (:require [wisp.runtime :refer [= and or str]]))

;;
;; bootstrapper
;;

(set! module.exports (fn [session-module]
  (if (= session-module require.main)
    (let [log       console.log

          persist   { :cleanup [ (fn [] (log "\nExiting..."))] }
          cleanup   (fn [] (persist.cleanup.map (fn [f] (f))))
          exit      (fn [] (cleanup) (process.exit))


          filename  session-module.filename
          session   nil
          start     (fn []
            (log "Loading session" filename)
            (delete (aget require.cache filename))
            (set! session (require filename))
            (log "Starting session" filename "\n")
            (session.start))

          mtime     nil
          on-change (fn [fname stat]
            (let [duplicate false]
              (if stat (do
                (if (= mtime stat.mtime) (set! duplicate true))
                (set! mtime stat.mtime)))
              (if (not duplicate) (do
                (log "\n")
                (if fname (log "File changed:" fname))
                (start)))))

          chokidar  (require "chokidar")
          chok-opts { :persistent true
                      :alwaysStat true }
          watcher   (chokidar.watch filename chok-opts) ]

      (.install            (require "source-map-support")) 
      (.register-handler   (require "segfault-handler"))
      (set! global.persist persist)
      (set! global.log     log)
      (process.on "SIGINT" exit)
      (watcher.on "change" on-change)

      (start)))))
