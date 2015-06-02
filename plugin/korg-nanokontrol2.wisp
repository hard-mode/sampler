(ns korg-nanokontrol2)

(def ^:private event2 (require "eventemitter2"))
(def ^:private midi   (require "../lib/midi.wisp"))

(defn connect
  ([]
    (connect "nanoKONTROL2"))
  ([hw-name]
    (let [input    (midi.connect-to-input  hw-name)
          output   (midi.connect-to-output hw-name)
          events   (event2.EventEmitter2.)]

      (let [clear (fn [])]
        (clear)
        (events.on "clear" clear))

      (let [refresh (fn [])]
        (refresh)
        (events.on "refresh" refresh))

      (input.on "message" (fn [t m]
        (events.emit "input" t (aget m 0) (aget m 1) (aget m 2))))

      { :events    events

        :clear     (fn [] (events.emit "clear"))
        :refresh   (fn [] (events.emit "refresh"))

        :send      (fn [m1 m2 m3] (output.send-message [m1 m2 m3]))

      })))
