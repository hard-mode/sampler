(ns web (:require [wisp.runtime :refer [=]]))

(def ^:private http (require "http"))
(def ^:private url  (require "url"))

(set! persist.web (or persist.web {}))

(def send-html (require "send-data/html"))

(defn server [port & pages]
  (let [state (or (aget persist.web port)
                  { :server (http.create-server)
                    :routes [] })]

    (set! (aget persist.web port) state)

    (set! state.routes (pages.reduce
      (fn [routes next-page i]
        (log "Adding route" i next-page)
        (routes.push next-page)
        routes) []))
    (log "Registered routes:" state.routes)
    (state.server.on "request" (fn [req resp]
      ((match-route state.routes req) req resp)))

    (state.server.listen port)
    (log "Listening on" port)

    state))

(defn route-404 [req resp]
  (send-html req resp "404"))

(defn match-route [routes req]
  (let [pathname (.-pathname (url.parse req.url))]
    (loop [head (aget routes 0)
           tail (routes.slice 1)]
      (log "trying route" head)
      (if (= pathname head.route)
        head.handler
        (if (= 0 tail.length)
          route-404
          (recur (aget tail 0) (tail.slice 1)))))))

(defn add-page [routes p]
  (set! (aget routes p.route) p)
  routes)

(defn page [route handler]
  { :route   route
    :handler handler })

;(defn page [& elements]
  ;(fn [state]))

;(defn button [value]
  ;(fn [page]))
