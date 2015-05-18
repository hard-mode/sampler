(ns sequencer (:require [wisp.runtime :refer [= not and str]]))

(let [child (require "child_process")
      fs    (require "fs")
      path  (require "path")

      midi (require "./midi.wisp")
      osc  (require "./osc.wisp")
      util (require "./util.wisp")

  ; metronome

  tempo
  140

  evmon
  (let [evmon (child.spawn "jack_evmon")]
    (evmon.stdout.on "data" (fn [data]
      (console.log data)))
    (evmon.stderr.on "data" (fn [data]
      (console.log data)))
    evmon)

  klick
  (child.spawn "klick" ["-s1" "-T" tempo])

  octave
  [ 32 37 36 41 40 44 49 48 53 52 57 56 60 ]
  ; C  C# D  D# E  F  F# G  G# A  A# B  C

  play-note
  (fn [d1]
    (if (not (= -1 (.indexOf octave d1)))
      (console.log (.indexOf octave d1))))

  ctrlr
  (midi.connect-controller "CMD" (fn [dt msg d1 d2]
    (if (and (= 151 msg) (= 127 d2))
      (play-note d1))))

]

  (.map (util.get-range 32 63)
    (fn [d1]
      (if (not (= -1 (.indexOf octave d1)))
        (ctrlr.out.send-message [151 d1 1])
        (ctrlr.out.send-message [151 d1 127]))))

)
