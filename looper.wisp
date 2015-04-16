(ns looper (:require [wisp.runtime :refer [str]]))

(def ^:private osc   (require "./osc.wisp"))

(defn loopers [how-many]
  (let [port   osc.port
        looper (child.spawn
                 postmelodic
                 [ "-l" how-many
                   "-c" 2
                   "-t" 40
                   "-D" "yes"
                   "-p" port ])]

    
  )
