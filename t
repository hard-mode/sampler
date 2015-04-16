[1mdiff --git a/osc.wisp b/osc.wisp[m
[1mindex 689f1c8..24f1c7b 100644[m
[1m--- a/osc.wisp[m
[1m+++ b/osc.wisp[m
[36m@@ -15,7 +15,7 @@[m
           c  (aget clients id)][m
       (console.log "CLIENT" host port)[m
       (if (not c) (set! c (osc.Client. host port)))[m
[31m-      { :send (fn [& args] (c.send.apply c args))[m
[32m+[m[32m      { :send (fn [& args] (process.next-tick (fn [] (c.send.apply c args))))[m
         :host host[m
         :port port })))[m
 [m
[1mdiff --git a/sequencer-nanokontrol2.wisp b/sequencer-nanokontrol2.wisp[m
[1mindex 41ed122..7e68d54 100644[m
[1m--- a/sequencer-nanokontrol2.wisp[m
[1m+++ b/sequencer-nanokontrol2.wisp[m
[36m@@ -6,6 +6,9 @@[m
 (defmacro after [t & body][m
  `(setTimeout (fn [] ~@body) ~t))[m
 [m
[32m+[m[32m(defmacro match [args & body][m
[32m+[m[32m  `(if (and ~@args) (do ~@body)))[m
[32m+[m
 (require "qtimers")[m
 [m
 (let [[m
[36m@@ -30,19 +33,16 @@[m
   ; controllers[m
 [m
   nanokontrol (midi.connect-controller "nano" (fn [dt msg d1 d2][m
[31m-    (if (and (= msg 189) (> d1 -1) (< d1 8)) (do[m
[31m-      (set! (aget phrase d1) d2)))[m
[31m-    (if (and (= msg 189) (= d1 16)) (do[m
[31m-      (set! decay (/ d2 127))))[m
[31m-    (if (and (= msg 189) (= d1 17)) (do[m
[31m-      (set! tempo (+ 120 (* 120 (/ d2 127))))))))[m
[32m+[m[32m    (match [(= msg 189) (> d1 -1) (< d1 8)] (set! (aget phrase d1) d2))[m
[32m+[m[32m    (match [(= msg 189) (= d1 16)]          (set! decay (/ d2 127)))[m
[32m+[m[32m    (match [(= msg 189) (= d1 17)]          (set! tempo (+ 120 (* 120 (/ d2 127)))))))[m
 [m
   launchpad (midi.connect-controller "Launchpad" (fn [dt msg d1 d2][m
[31m-    (if (and (= msg 144) (> d1 -1) (< d1 8) (= d2 127))[m
[32m+[m[32m    (match [(= msg 144) (> d1 -1) (< d1 8)  (= d2 127)][m
       (set! jumpto d1))[m
[31m-    (if (and (= msg 144) (> d1 15) (< d1 24) (= d2 127))[m
[32m+[m[32m    (match [(= msg 144) (> d1 15) (< d1 24) (= d2 127)][m
       (set! (aget kicks (- d1 16)) (if (aget kicks (- d1 16)) 0 1)))[m
[31m-    (if (and (= msg 144) (> d1 31) (< d1 40) (= d2 127))[m
[32m+[m[32m    (match [(= msg 144) (> d1 31) (< d1 40) (= d2 127)][m
       (set! (aget snares (- d1 32)) (if (aget snares (- d1 32)) 0 1)))))[m
 [m
   ; drums[m
[36m@@ -63,6 +63,11 @@[m
 [m
   ; sequencer step function[m
   step      (fn [][m
[32m+[m
[32m+[m[32m    ; step jumper[m
[32m+[m[32m    (if (> jumpto -1) (do (set! index jumpto)[m
[32m+[m[32m                          (set! jumpto -1)))[m
[32m+[m
     ; launchpad -- step indicator[m
     (.map (util.range 0 8) (fn [i][m
       (launchpad.send [144 i        0])[m
[36m@@ -82,10 +87,7 @@[m
         (nanokontrol.send [144 note 0])))[m
 [m
     ; advance step index[m
[31m-    (if (= -1 jumpto)[m
[31m-      (set! index (if (< index 7) (+ index 1) 0))[m
[31m-      (do (set! index jumpto)[m
[31m-          (set! jumpto -1))))[m
[32m+[m[32m    (set! index (if (< index 7) (+ index 1) 0)))[m
 [m
 ][m
 [m
