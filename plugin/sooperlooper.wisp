(ns looper (:require [wisp.runtime :refer [str]]))

(def ^:private child (require "child_process"))
(def ^:private osc   (require "../lib/osc.wisp"))
(def ^:private util  (require "../lib/util.wisp"))

(defn sooperlooper "sooperlooper")

(defn looper [tracks]
  (let [osc-client (osc.client)
        looper     (jack.spawn
                      sooperlooper
                      "-l" tracks
                      "-c" 2
                      "-t" 40
                      "-D" "yes"
                      "-p" osc-client.port)]

    (.map (util.range tracks) (fn [i]
      (let [n (str "/sl/" i "/hit")]
        { :track   i
          :state   :ready
          :record  (fn [] (osc-client.send n "record" ))
          :oneshot (fn [] (osc-client.send n "oneshot"))
          :mute    (fn [] (osc-client.send n "mute"   )) })))
    
  ))
