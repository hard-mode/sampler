(ns mixer (:require [wisp.runtime :refer [str =]]))

(def ^:private jack (require "../lib/jack.wisp"))
(def ^:private osc  (require "../lib/osc.wisp"))

(def jackminimix "jackminimix")

(defn- track [mixer-port])

(defn mixer [track-number & tracks]
  (let [osc-client        (osc.client)

        jack-client-name  "Mixer"
        jack-client       (jack.client jack-client-name)
        jack-process      (jack.spawn jackminimix
                             "-c" tracks
                             "-p" osc-client.port
                             "-n" jack-client-name
                             "-l" "system:playback_1"
                             "-r" "system:playback_2") ]

    ;(jack.on "client-registered" (fn [client]
      ;(if (= client "Mixer") (do
        ;(osc-client.send "/mixer/channel/set-label" 0 "Master")
        ;(osc-client.send "/mixer/channel/set-label" 0 "Monitor")))))

    { :osc    osc-client 
      :track  (track.bind null osc-client.port) }))
