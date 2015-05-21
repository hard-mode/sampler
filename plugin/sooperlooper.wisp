(ns looper (:require [wisp.runtime :refer [str]]))

(def ^:private child (require "child_process"))
(def ^:private jack  (require "../lib/jack.wisp"))
(def ^:private osc   (require "../lib/osc.wisp"))
(def ^:private util  (require "../lib/util.wisp"))

(def sooperlooper "slgui")

(defn looper [client-name tracks]
  (let [osc-client   (osc.client 9951)
        jack-client  (jack.client client-name)
        jack-process (jack.spawn
                       client-name
                       sooperlooper
                       "-J" client-name
                       "-l" tracks
                       "-c" 2
                       "-t" 10)
                       ;"-D" "yes"
                       ;"-p" osc-client.port)
        sl-track     (fn [i] (let [n (str "/sl/" i "/hit")]
                       { :track   i
                         :state   :ready
                         :record  (fn [] (osc-client.send n "record" ))
                         :oneshot (fn [] (osc-client.send n "oneshot"))
                         :mute    (fn [] (osc-client.send n "mute"   )) })) ]

    { :client   jack-client
      :process  jack-process
      :started  jack-client.started
      :port     jack-client.port 
      :tracks   (.map (util.range tracks) sl-track) }
    
  ))
