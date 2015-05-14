(ns calf (:require [wisp.runtime :refer [str = not]]))

(def ^:private jack  (require "../lib/jack.wisp"))

(def calfjackhost "calfjackhost")

(set! module.exports (fn calf [client-name plugin-list]
  (let [jack-client   (jack.client client-name)
        jack-process  (jack.spawn  client-name
                        calfjackhost
                        "--client" client-name
                        (plugin-list.join " ")
                        "!" ; connect to system outs
                      )]
  { :name    client-name
    :started jack-client.started })))
