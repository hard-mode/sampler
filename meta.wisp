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
