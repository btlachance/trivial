#lang racket/base

;; Ill-typed `regexp:` expressions
;;
;; TODO why can't I catch errors for (ann ... (List String))? WhydoI need #f?

(define (expr->typed-module expr)
  #`(module t typed/racket/base
      (require trivial/regexp)
      #,expr))

(define TEST-CASE* (map expr->typed-module '(
  (ann (regexp-match: "hi" "hi")
       (U #f (List String String String)))
  (ann (regexp-match: #rx"(h)(i)" "hi")
       (U #f (List String)))
  (ann (regexp-match: #px"(?<=h)(?=i)" "hi")
       (U #f (List String String String)))
  ;;bg; ill-typed in untyped Racket
  (byte-regexp: #rx#"yolo")
  (ann (regexp-match: #rx#"hi" "hi")
       (U #f (List String String)))
  (ann (regexp-match: #px#"hi" "hi")
       (U #f (List Bytes Bytes)))
  (ann (regexp-match: (regexp "he") "hellooo")
       (U #f (List String)))
  (ann (let ()
         (define-regexp: rx (regexp "he(l*)(o*)"))
         (regexp-match: rx "hellooo"))
       (U #f (List String String String)))
  ;; `define` doesn't propagate group information
  (ann (let ()
         (define rx "he(l*)(o*)")
         (regexp-match: rx "helloooooooo"))
       (U #f (List String String String)))
  ;; --- Can't handle |, yet
  (ann (regexp-match: "this(group)|that" "that")
       (U #f (List String String)))
)))

;; -----------------------------------------------------------------------------

(module+ test
  (require
    rackunit)

  (define (regexp-eval stx)
    (lambda () ;; For `check-exn`
      (compile-syntax stx)))

  (for ([rkt (in-list TEST-CASE*)])
    (check-exn #rx"Type Checker"
      (regexp-eval rkt)))

)