;;
;; old mixer example
;;

(let [

track (fn [label & devices])

mixer
(fn [& tracks]
  (spawn "jackminimix" ["-c" tracks.length])
  )

mix
(mixer

  (track "Master"
    (fx "Limiter" -3.0))

  (track "Monitor"
    (fx "Limiter" -3.0))

  (track "Kick"
    (sequencer 8)
    (sample "kick.wav")
    (sc "Bass"))

  (track "Snare"
    (sequencer 8)
    (sample "snare.wav")
    (fx "Reverb" 300))

  (track "Bass"
    (synth "Analog Bass 1")
    (fx "Delay" {:time 300 :fb 0.5})
    (fx "Compressor" { :sc "Kick" }))

  (track "Lead")
    (sequencer 8)
    (arpegiator)
    (synth "")
    (fx "Delay" {:time 150 :fb 0.3}))

])


;;
;; TODO argument parser
;; (foo :bar 1 :baz 2 3 :quux :nix 4 5 6)
;; => [[:bar 1] [:bar 2 3] [:quux] [:nix 4 5 6]]
;;
;; TODO session bindings
;; pass binding name to binding value
;; i.e. autonaming
;;


;;
;; new mixer example
;;

    ; drum sampler
    kick      (sample.player "./samples/kick.wav")
    snare     (sample.player "./samples/snare.wav")
    hh-closed (sample.player "./samples/hh.wav")
    hh-open   (sample.player "./samples/oh.wav")
    crash     (sample.player "./samples/crash.wav")
    ride      (sample.player "./samples/ride.wav")

    ; drum sequencer
    sq
    (sequencer
      kick  [1 0 0 1 0 1 0 0]
      snare [0 0 1 0 0 0 1 0]
      hh    [0 1 0 1 0 1 0 1]
      crash [1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0]
      ride  [1 0 0])

    ; mixer
    mix
    (mixer

      (track "Master"
        (mixer.output "system"))

      (track "Kick"
        kick
        (calf.mono)
        (calf.eq5)
        (calf.compressor)
        (mixer.send "Master" -6.0))

      (track "Snare"
        snare
        (calf.eq5)
        (calf.mono)
        (calf.compressor)
        (mixer.send "Reverb" -12.0)
        (mixer.send "Master"  -5.0))

      (track "HiHat"
        hh-closed
        hh-open
        (calf.mono)
        (calf.eq5)
        (calf.compressor)
        (mixer.send "Master" -9.0)))
