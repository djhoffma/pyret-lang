#lang racket

;; This sketch comes from Matthias Felleisen:
;; http://lists.racket-lang.org/users/archive/2013-April/057407.html

(require
  profile
  "../runtime.rkt"
  "../ffi-helpers.rkt")
(provide (rename-out [export %PYRET-PROVIDE]))


(define ((profile-wrapper loc) pyret-fun)
  (define (wrapped)
    ((p:check-fun pyret-fun loc)))
  (profile-thunk wrapped #:threads #t))

(define profile-pfun (p:mk-internal-fun profile-wrapper))

(define export (p:mk-object
  (make-immutable-hash (list (cons "profile" profile-pfun)))))
