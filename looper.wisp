(ns looper (:require [wisp.runtime :refer [str]]))

(def ^:private child (require "child_process"))
(def ^:private osc   (require "./osc.wisp"))

(defn looper [how-many]
  (let [osc-client (osc.client)
        looper     (child.spawn postmelodic
                     [ "-l" how-many
                       "-c" 2
                       "-t" 40
                       "-D" "yes"
                       "-p" port ])
        connect    (fn [port] (if (= port jack-port-name)) )]

    (jack.on "port-registered" connect) 

    
  ))
