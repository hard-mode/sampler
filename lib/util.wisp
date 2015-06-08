(ns util)


(defn range
  ([length] (range 0 length))
  ([start length]
    (.map (Array.apply null (Array length))
      (fn [_ i] (+ start i)))))


(defn counter
  ([] (counter 0))
  ([i]
    (let [ state { :value i } ]
      (fn []
        (set! state.value (+ 1 state.value))
        (- state.value 1)))))


(defn expect
  " Unbinds an event handler as soon as a condition is fulfilled;
    optionally waits for a promise beforehand. Came to be because
    Wisp's syntax doesn't seem to let an event handler unbind itself.
    Looks somewhat like a combination of promises and events; maybe
    the deferred should also be part of this construct, and a promise
    should always be returned? Also, how difficult would a circular
    expect be, and would it be the way to go for achieving automatic
    re-initialization of unplugged and then re-plugged controllers? "
  ([emitter event finder found]
    (let [finder- nil]
      (set! finder- (fn [& args]
        (if (finder.apply null args)
          (do (found.apply null args)
              (emitter.off event finder-)))))
      (emitter.on event finder-)))
  ([pre-promise pre-finder emitter event finder found]
    (pre-promise.then (fn [& args]
      (let [pre-found (pre-finder.apply null args)]
        (if pre-found
          (found.apply null [pre-found])
          (expect emitter event finder found)))))))
