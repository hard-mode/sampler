(ns sampler (:require [wisp.runtime :refer [= and str]]))

(let [

  child (require "child_process")
  fs    (require "fs")
  path  (require "path")

  midi (require "./midi.wisp")
  osc  (require "./osc.wisp")
  clients osc.clients
  util (require "./util.wisp")
  get-range util.get-range

  _ (console.log "FOOOOO" osc)

  ; settings

  osc-port     10000
  sample-count 16
  postmelodic  "/home/epimetheus/code/hardmode/postmelodic/bin/sample_player"
  sounds-dir   "/home/epimetheus/Sounds"
  pads         [ [0  1]  [2  3]  [4  5]  [6  7]
                 [16 17] [18 19] [20 21] [22 23]
                 [32 33] [34 35] [36 37] [38 39]
                 [48 49] [50 51] [52 53] [54 55] ]

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

      (if (= d1 120)
        (.map (get-range 10000 sample-count)
          (fn [port]
            (console.log "STOP" port) 
            (osc.send "127.0.0.1" port "/stop" 0))))

      )))

  clear
  (fn []
    (.map (get-range 0 256) (fn [i] (launchpad.out.send-message [144 i 0])))
    (launchpad.out.send-message [144 120 70]))

  ; sound player

  load-sample
  (fn load-sample [sample]
    (let [client-name (sample.substr 0 50)
          sample-nr   (- osc-port 10000)
          sampler     (child.spawn postmelodic
                        [ "-n" sample-nr
                          "-p" osc-port
                          "-c" "system:playback_1"
                          sample ] ) ]
                        ;{ :stdio "inherit" } ) ]
      (console.log osc-port sample "\n")
      (.map (aget pads sample-nr) (fn [pad]
        (launchpad.out.send-message [144 pad (- 127 sample-nr)])))
      (set! (aget osc.clients (str "127.0.0.1" osc-port))
            (osc.Client. "127.0.0.1" osc-port))
      (set! osc-port (+ 1 osc-port))))

  load-samples
  (fn [kit]
    (if (.-length (or kit.sounds []))
      (do (console.log "Loading sounds...")
          (kit.sounds.map (fn [sample] (load-sample
            (path.resolve (path.join kit.root sample))))))
      (do (console.log "Oh zounds! No sounds were found.")
          nil)))
 
  load-random-samples
  (fn [n]
    ((require "recursive-readdir") (path.resolve sounds-dir)
      (fn [err files] (if err (throw err))
        (console.log (require "chance"))
        (let [sounds (.pick (new (require "chance")) files n)]
          (sounds.map load-sample)))))

  kit-path
  "kits/ultra.json"

  kit
  (try
    (JSON.parse
      (fs.readFileSync (path.resolve kit-path) { :encoding "utf8" }))
    (catch e { :root "" :sounds [] }))

]

  (clear)
  (load-samples kit)
  (load-random-samples 8)

)
