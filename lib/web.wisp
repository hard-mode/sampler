(ns web (:require [wisp.runtime :refer [=]]))

(def ^:private fs   (require "fs"))
(def ^:private http (require "http"))
(def ^:private url  (require "url"))
(def ^:private $    (require "hyperscript"))

(set! persist.web (or persist.web {}))

(def send-html (require "send-data/html"))
(def send-json (require "send-data/json"))

(defn server [port & pages]
  (let [state (or (aget persist.web port)
                  { :server (http.create-server)
                    :routes [] })]

    (set! state.routes (pages.reduce
      (fn [routes next-page i]
        (log "Adding route" i next-page)
        (routes.push next-page)
        routes) []))
    (log "Registered routes:" state.routes)

    (if (aget persist.web port) nil
      (state.server.on "request" (fn [req resp]
        ((match-route state.routes req) req resp))))

    (set! (aget persist.web port) state)

    (state.server.listen port)
    (log "Listening on" port)

    state))

(defn respond-404 [req resp]
  (send-html req resp "404"))

(defn respond-template [template context req resp]
  (send-html req resp (.-outerHTML (template context))))

(defn match-route [routes req]
  (let [pathname (.-pathname (url.parse req.url))]
    (loop [head (aget routes 0)
           tail (routes.slice 1)]
      (if (= pathname head.route)
        head.handler
        (if (= 0 tail.length)
          respond-404
          (recur (aget tail 0) (tail.slice 1)))))))

(defn add-page [routes p]
  (set! (aget routes p.route) p)
  routes)

(defn endpoint [route handler]
  { :route   route
    :handler handler })

(defn page-template [context]
  ($ "html" [
    ($ "head" [
      ($ "meta" { :charset "utf-8" })
      ($ "title" "Boepripasi") ])
    ($ "body" [
      ($ "script" { :src  "/script" } context) ])]))

(defn page [route script]
  (log script)
  (let [handler (fn [req resp]
          (fs.read-file script { :encoding "utf8" } (fn [err data]
            (if err (throw err))
            (respond-template page-template data req resp))))]
    (endpoint route handler)))

;(defn page [& elements]
  ;(fn [state]))

;(defn button [value]
  ;(fn [page]))
