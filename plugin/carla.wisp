(ns carla)

(def ^:private jack (require "../lib/jack.wisp"))

(defn lv2 [client-name plugin-uri]
  (let [jack-client  (jack.client client-name)
        args         [client-name "carla-single" "lv2" plugin-uri]
        jack-process (jack.spawn.apply nil args)]
  { :client  jack-client
    :process jack-process
    :started jack-client.started
    :port    jack-client.port }))
