;; this macro is meant to lay the foundation for
;; a declarative, more purely functional variant
;; of session descriptions.
;;
;; it splits the list of forms into keys and values,
;; building a dictionary out of the let-like syntax
;; of the session declaration; this dictionary is the
;; session description, which consists of pure data,
;; and does not cause side effects while being generated.
;;
;; a start method sets up the actual session according
;; to the description; stop tears it down likewise.
;; the description can be subjected to metadata-assisted
;; analysis, allowing for diff-based live coding (similar
;; to "virtual dom" implementations for incremental html
;; modification)
;;
;; with every form in the session being aware of what name
;; it is bound to, things that are costly to set up or tear
;; down such as external processes, connections, etc, can
;; be persisted across session restarts caused by edits in
;; other parts of the code, making for a smooth live coding
;; experience. metadata-aware forms can also define a gui for
;; manipulating their state, enabling highly interactive
;; debugging and blurring the line between code and user interface.
;;
;; otherwise the macro is pretty shitty


(defmacro session [& body]
  (let [
    body-split
      (loop [
        i
          0
        k
          []
        v
          []
        head
          (body.slice 1)
        tail
          body
      ] (console.log)
        (console.log "I" i "\nK" k "\nH" head "\nT" tail)
        (if (= head undefined)
          { :keys k :vals v}
          (if (= i 0)
            (recur 1 (k.concat [head]) v (aget tail 0) (tail.slice 1))
            (recur 0 k (v.concat [head]) (aget tail 0) (tail.slice 1)))))
    body-map
      (let [body-map {}]
        (body-split.keys.map (fn [k i]
          (set! (aget body-map k.name) (aget body-split.vals i))))
        body-map)
    ] `(defn start [] (let [~@body] (console.log (unquote body-map))))))

