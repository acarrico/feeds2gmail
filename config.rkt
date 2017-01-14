#lang racket

(provide user pwd address lock-path feeds-path)

(define user (make-parameter ""))
(define pwd  (make-parameter ""))
(define address  (make-parameter ""))
(define lock-path (make-parameter ""))
(define feeds-path (make-parameter ""))

(define (getenv/default name default)
  (match (getenv name)
    ((or #f "") default)
    ((var val) val)))

(define (config-dot path)
  (read-config path)
  (feeds-path (build-path (find-system-path 'home-dir) ".feeds2gmail.cache.rktd"))
  (lock-path (build-path (find-system-path 'home-dir) ".feeds2gmail.LOCK")))

(define (config-xdg)
  ;; Use XDG Base Directory Specification:
  ;;   https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
  (define xdg-config-home
    (getenv/default
     "XDG_CONFIG_HOME"
     (build-path (find-system-path 'home-dir) ".config")))
  (read-config (build-path xdg-config-home "feeds2gmail" "config"))

  (define xdg-data-home
    (getenv/default
     "XDG_DATA_HOME"
     (build-path (find-system-path 'home-dir) ".local" "share")))
  (define data-home (build-path xdg-data-home "feeds2gmail"))
  (unless (directory-exists? data-home)
    (make-directory data-home))
  (feeds-path (build-path data-home "cache.rktd"))

  ;; ISSUE: must touch lock file in runtime dir at least every 6 hours.
  (define xdg-runtime-dir
    (getenv/default "XDG_RUNTIME_DIR" ""))
  (lock-path (build-path xdg-runtime-dir "feeds2gmail.LOCK")))

(define (config)
  (define path (build-path (find-system-path 'home-dir) ".feeds2gmail"))
  (if (file-exists? path)
      (config-dot path)
      (config-xdg)))

(define (read-config path)
  (define xs (file->lines path))
  (for ([x xs])
    (match x
      [(pregexp "^email\\s*=\\s*(\\S+)\\s*$" (list _ s)) (user s)]
      [(pregexp "^password\\s*=\\s*(\\S+)\\s*$" (list _ s)) (pwd s)]
      [(pregexp "^address\\s*=\\s*(\\S+)\\s*$" (list _ s)) (address s)]
      [_ (void)])))

(config)
