(ns calf (:require [wisp.runtime :refer [str = not]]))

(def ^:private jack        (require "../lib/jack.wisp"))
(def ^:private intersperse (require "intersperse"))

(def calfjackhost "calfjackhost")

(set! module.exports (fn calf [client-name plugin-list]
  (let [jack-client   (jack.client client-name)

        args          [client-name calfjackhost "--client" client-name]
        args          (args.concat (intersperse plugin-list "!"))
        jack-process  (jack.spawn.apply nil args)]
  { :client  jack-client
    :process jack-process
    :started jack-client.started
    :port    jack-client.port })))
