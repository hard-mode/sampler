(ns web)

(def ^:private http (require "http"))

(set! persist.web (or persist.web {}))

(defn server
  [port & pages]
    (let [state  (or (aget persist.web port)
                   { :server (http.create-server)
                     :routes {} })]
      (pages.map (fn [page]
        (if (aget state.routes page.route) nil
          (set! (aget state.routes page.route) page.handler))))
      (set! (aget persist.web port) state)

      (state.server.on "request" (fn [req resp] ((aget state.routes "/") req resp)))
      (state.server.listen port)

      (log "Listening on" port)
      (log state)

      state))

(defn page [route handler]
  { :route   route
    :handler handler })
