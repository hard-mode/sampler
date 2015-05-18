(ns sequencer (:require [wisp.runtime :refer [= and str]]))

(let [child (require "child_process")
      fs    (require "fs")
      path  (require "path")

      midi (require "./midi.wisp")
      osc  (require "./osc.wisp")

  octave
  (fn [i] (.map
    ; C C# D D# E  F  F# G  G# A  A# B  C
    [ 16 1 17 2 18 19 3  20 4  21 5  22 23 ])
    (fn [n] (+ (* 32 i) n)))

  ctrlr
  (midi.connect-controller "Launchpad" (fn [dt msg d1 d2]
    (console.log msg d1 d2)))

])
