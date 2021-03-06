(ns control (:require [wisp.runtime  :refer [= and or assoc]]
                      [wisp.sequence :refer [assoc]]))


(def ^:private midi (require "../lib/midi.wisp"))


(defn group
  "Handles a number of controls, in order. "
  ([members] (group members [] []))
  ([members state output]
    { :state   state
      :output  output
      :members members
      :update
        (fn update-group [event]
          (let [next-members
                  (members.map (fn [m] (m.update event)))
                next-state
                  (next-members.reduce
                    (fn [st m] (st.concat m.state)) [])
                next-output
                  (next-members.reduce
                    (fn [out m]
                      (m.output.map (fn [o]
                        (if (= -1 (out.index-of o)) (out.push o))))
                          out) []) ]
            (group next-members next-state next-output))) }))


; TODO factor out mask/output logic which is midi-specific


(def toggle-state { :on :off :off :on })


(defn momentary
  "Lights up when pressed. "
  ([mask]
    (momentary mask :off :off))
  ([mask state]
    (momentary mask state state))
  ([mask base-state current-state]
    { :state  current-state
      :output [(assoc mask :verb current-state)]
      :mask   mask
      :update
      (fn update-momentary [msg]
        (let [on         (midi.match (assoc mask :event :note-on)  msg)
              off        (midi.match (assoc mask :event :note-off) msg)
              next-state (if on (aget toggle-state base-state)
                           (if off base-state
                             current-state))]
          (momentary mask base-state next-state))) }))


(defn toggle
  "Toggles between two states."
  ([mask] (toggle mask :off))
  ([mask state]
    { :state  state
      :output [(assoc mask :verb state)]
      :mask   mask
      :update
      (fn update-toggle [msg]
        (let [match      (midi.match (assoc mask :event :note-on) msg)
              next-state (if match (aget toggle-state state) state)]
          (toggle mask next-state))) }))


(defn lazy-toggle
  "Toggles between two states on release."
  ([mask] (lazy-toggle mask :off false))
  ([mask state] (lazy-toggle mask :off false))
  ([mask state pressed]
    { :mask    mask
      :state   state
      :pressed pressed
      :output  [(assoc mask :verb state)]
      :update
      (fn update-lazy-toggle [msg]
        (let [released     (midi.match (assoc mask :event :note-off) msg)
              next-pressed (or (and pressed (not released))
                               (midi.match (assoc mask :event :note-on) msg))
              next-state   (if (and pressed released) (aget toggle-state state) state)]
          (lazy-toggle mask next-state next-pressed))) }))


;(defn select
  ;"Only one out of several can be on at a given time. "
  ;([many] (select many (aget many 0)))
  ;([many state]
    ;{:fn (fn ! [msg]
      ;(let [matches    (filter #(= (:state %) :on)
                         ;(for [mask many] ((:fn (btn-switch mask)) msg)))
            ;next-state (or (get (first matches) :mask) state)]
        ;(btn-select many next-state)))
     ;:many many
     ;:state state
     ;:output (for [mask many] (assoc mask :verb (if (midi-match mask state)
                                                 ;:on :off)))}))


;(defn btn-switch
  ;"Toggles between two states. "
  ;([mask] (btn-switch mask :off))
  ;([mask state]
    ;{:fn (fn ! [msg]
      ;(let [match      (midi-match (assoc mask :command :note-on) msg)
            ;next-state (if match (toggle-state state) state)]
        ;(btn-switch mask next-state)))
     ;:mask mask
     ;:state state
     ;:output [(assoc mask :verb state)]}))


;(defn btn-switch-lazy
  ;"Toggles between two states on release. "
  ;([mask] (btn-switch-lazy mask :off false))
  ;([mask state] (btn-switch-lazy mask :off false))
  ;([mask state pressed]
    ;{:fn (fn ! [msg]
      ;(let [released     (midi-match (assoc mask :command :note-off) msg)
            ;next-pressed (or (and pressed (not released))
                             ;(midi-match (assoc mask :command :note-on) msg))
            ;next-state   (if (and pressed released) (toggle-state state) state)]
        ;(btn-switch-lazy mask next-state next-pressed)))
     ;:mask mask
     ;:state state
     ;:pressed pressed
     ;:output [(assoc mask :verb state)]}))


;(def btn-lazy btn-switch-lazy)


;(defn btn-select
  ;"Only one out of several can be on at a given time. "
  ;([many] (btn-select many (first many)))
  ;([many state]
    ;{:fn (fn ! [msg]
      ;(let [matches    (filter #(= (:state %) :on) 
                         ;(for [mask many] ((:fn (btn-switch mask)) msg)))
            ;next-state (or (get (first matches) :mask) state)]
        ;(btn-select many next-state)))
     ;:many many
     ;:state state
     ;:output (for [mask many] (assoc mask :verb (if (midi-match mask state)
                                                 ;:on :off)))}))
