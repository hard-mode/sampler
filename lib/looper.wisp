(ns looper (:require [wisp.runtime :refer [str]]))

(def ^:private child (require "child_process"))
(def ^:private osc   (require "./osc.wisp"))
(def ^:private util  (require "./util.wisp"))
(def ^:private JACK  (require "node-jack"))
(def ^:private jack  (new JACK.Client "hardmode-loop-manager"))

(defn looper [tracks]
  (let [osc-client (osc.client)
        looper     (child.spawn "sooperlooper"
                     [ "-l" tracks
                       "-c" 2
                       "-t" 40
                       "-D" "yes"
                       "-p" osc-client.port ])
        connect    (fn [port])]

    (jack.on "port-registered" connect)

    (.map (util.range tracks) (fn [i]
      (let [n (str "/sl/" i "/hit")]
        { :track   i
          :state   :ready
          :record  (fn [] (osc-client.send n "record" ))
          :oneshot (fn [] (osc-client.send n "oneshot"))
          :mute    (fn [] (osc-client.send n "mute"   )) })))
    
  ))
