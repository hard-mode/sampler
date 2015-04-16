(ns mixer (:require [wisp.runtime :refer [str]]))

(def ^:private child (require "child_process"))
(def ^:private osc   (require "./osc.wisp"))

(defn mixer []
  (let [osc-client (osc.client)
        mixer      (child.spawn "jackminimix"
                     [ "-c" 2
                       "-p" osc-client.port
                       "-n" "Mixer"
                       "-l" "system:playback_1"
                       "-r" "system:playback_2" ])
        connect    (fn [port] (console.log port)) ]

    (jack.on "client-registered" (fn [client]
      (console.log client)))

    { :osc osc-client }
    
  ))
