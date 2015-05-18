(ns sampler (:require [wisp.runtime :refer [= and str]]))

(let [

  path  (require "path")

  midi   (require "./midi.wisp")
  osc    (require "./osc.wisp")
  sample (require "./sample.wisp")
  util   (require "./util.wisp")

  chance (new (require "chance"))

  ; settings

  sample-count 16
  pads         [ [0  1]  [2  3]  [4  5]  [6  7]
                 [16 17] [18 19] [20 21] [22 23]
                 [32 33] [34 35] [36 37] [38 39]
                 [48 49] [50 51] [52 53] [54 55] 
                 [64 65] [66 67] [68 69] [70 71] 
                 [80 81] [82 83] [84 85] [86 87] 
                 [96 97] [98 99] [100 101] [102 103]
                 [112 113] [114 115] [116 117] [118 119] ]

  ; controller

  launchpad
  (midi.connect-controller "Launchpad" (fn [dt msg d1 d2]
    (if (and (= msg 144)
             (= d2  127)) (do

      (pads.map (fn [pad n]
        (if (not (= -1 (pad.indexOf d1)))
          (osc.send "127.0.0.1"
            (+ 10000 n)
            "/play" 0 0)))))

      (if (= d1 120) (do
        (console.log "STOP ALL")
        (.map (util.range 10000 (- osc.port 10000))
          (fn [port]
            (osc.send "127.0.0.1" port "/stop" 0)))))

      )))

  clear
  (fn []
    (.map (util.range 0 256) (fn [i] (launchpad.out.send-message [144 i 0])))
    (launchpad.out.send-message [144 120 70]))

  ; sound player

  sounds-dir "/home/epimetheus/Sounds"
  library    []

  load-sample
  (fn [s]
    (let [sample-nr (- (sample.player s) 10000)]
      (console.log sample-nr)
      (.map (aget pads sample-nr) (fn [pad]
        (launchpad.out.send-message [144 pad (- 127 sample-nr)])))))

  load-samples
  (fn [s] (s.map load-sample))

  load-random-samples
  (fn [n] (load-samples (chance.pick library n)))

]

  (clear)

  (load-samples (sample.kit
      (path.join sounds-dir 
        "Vengeance - Dirty Electro Vol.3/VDE3 128 BPM Ultra Kit/VDE3 Ultra Kit Oneshots/")
      [ "VDE3 128 BPM Ultra Oneshot Kick.wav"
        "VDE3 128 BPM Ultra Oneshot Clap.wav"
        "VDE3 128 BPM Ultra Oneshot Snare.wav"
        "VDE3 128 BPM Ultra Oneshot Hihat 1.wav" ]))

  ((require "recursive-readdir") (path.resolve sounds-dir)
    (fn [err files] (if err (throw err))
      (set! library files)
      (load-random-samples 24)))

)
