(ns mixer (:require [wisp.runtime :refer [str =]]))

(def ^:private child (require "child_process"))
(def ^:private osc   (require "./osc.wisp"))
(def ^:private JACK  (require "node-jack"))
(def ^:private jack  (new JACK.Client "hardmode-mixer-manager"))

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
      (if (= client "Mixer") (do
        (osc-client.send "/mixer/channel/set-label" 0 "Master")
        (osc-client.send "/mixer/channel/set-label" 0 "Monitor")))))

    { :osc osc-client }
    
  ))
