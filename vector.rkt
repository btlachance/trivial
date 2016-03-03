#lang typed/racket/base

;; TODO integrate with trivial/math to get ints from identifiers

(provide
  define-vector:
  let-vector:
  vector-length:
  vector-ref:
  vector-set!:
  vector-map:
  vector-map!:
  vector-append:
  vector->list:
  vector->immutable-vector:
  vector-fill!:
  ;vector-take
  ;vector-take-right
  ;vector-drop
  ;vector-drop-right
  ;vector-split-at
  ;vector-split-at-right

  ;; --- private
  (for-syntax parse-vector-length)
)

;; -----------------------------------------------------------------------------

(require
  (only-in racket/unsafe/ops
    unsafe-vector-set!
    unsafe-vector-ref)
  racket/vector
  (for-syntax
    typed/racket/base
    syntax/id-table
    syntax/parse
    syntax/stx
    trivial/private/common
  ))

;; =============================================================================

(define-for-syntax vector-length-key 'vector:length)
(define-for-syntax id+vector-length (make-free-id-table))

(begin-for-syntax (define-syntax-class vector/length
  #:attributes (expanded length)
  (pattern e
   #:with e+ (expand-expr #'e)
   #:with len (parse-vector-length #'e+)
   #:when (syntax-e #'len)
   #:attr expanded #'e+
   #:attr length #'len)
))

(define-syntax (define-vector: stx)
  (syntax-parse stx
   [(_ name:id v:vector/length)
    (free-id-table-set! id+vector-length #'name (syntax-e #'v.length))
    #'(define name v.expanded)]
   [(_ e* ...)
    #'(define e* ...)]))

(define-syntax (let-vector: stx)
  (syntax-parse stx
   [(_ ([name*:id v*:vector/length] ...) e* ...)
    #'(let ([name* v*.expanded] ...)
        (let-syntax ([name* (make-rename-transformer
                              (syntax-property #'name*
                                               vector-length-key
                                               'v*.length))] ...)
          e* ...))]
   [(_ e* ...)
    #'(let e* ...)]))

(define-for-syntax (vector-bounds-error sym v-stx i)
  (raise-syntax-error
    sym
    "Index out-of-bounds"
    (syntax->datum v-stx)
    i
    (list v-stx)))

(define-syntax (vector-length: stx)
  (syntax-parse stx
   [(_ v:vector/length)
    (syntax/loc stx 'v.length)]
   [_:id
    (syntax/loc stx vector-length)]
   [(_ e* ...)
    (syntax/loc stx (vector-length e* ...))]))

(define-syntax (vector-ref: stx)
  (syntax-parse stx
   [(_ v:vector/length i:nat)
    (unless (< (syntax-e #'i) (syntax-e #'v.length))
      (vector-bounds-error 'vector-ref: #'v (syntax-e #'i)))
    (syntax/loc stx (unsafe-vector-ref v.expanded i))]
   [_:id
    (syntax/loc stx vector-ref)]
   [(_ e* ...)
    (syntax/loc stx (vector-ref e* ...))]))

(define-syntax (vector-set!: stx)
  (syntax-parse stx
   [(_ v:vector/length i:nat val)
    (unless (< (syntax-e #'i) (syntax-e #'v.length))
      (vector-bounds-error 'vector-set!: #'v (syntax-e #'i)))
    (syntax/loc stx (unsafe-vector-set! v.expanded i val))]
   [_:id
    (syntax/loc stx vector-set!)]
   [(_ e* ...)
    (syntax/loc stx (vector-set! e* ...))]))

(define-syntax (vector-map: stx)
  (syntax-parse stx
   [(_ f v:vector/length)
    #:with (i* ...) (for/list ([i (in-range (syntax-e #'v.length))]) i)
    #:with f+ (gensym 'f)
    #:with v+ (gensym 'v)
    #:with v++ (syntax-property
                 (if (small-vector-size? (syntax-e #'v.length))
                   (syntax/loc stx
                     (let ([f+ f] [v+ v.expanded])
                       (vector (f+ (unsafe-vector-ref v+ 'i*)) ...)))
                   (syntax/loc stx
                     (let ([f+ f] [v+ v.expanded])
                       (build-vector 'v.length (lambda ([i : Integer])
                                                 (f+ (vector-ref: v+ i)))))))
                 vector-length-key
                 (syntax-e #'v.length))
    (syntax/loc stx v++)]
   [_:id
    (syntax/loc stx vector-map)]
   [(_ e* ...)
    (syntax/loc stx (vector-map e* ...))]))

(define-syntax (vector-map!: stx)
  (syntax-parse stx
   [(_ f v:vector/length)
    #:with f+ (gensym 'f)
    #:with v+ (gensym 'v)
    #:with v++ (syntax-property
                 #'(let ([f+ f]
                         [v+ v.expanded])
                     (for ([i (in-range 'v.length)])
                       (unsafe-vector-set! v+ i (f+ (unsafe-vector-ref v+ i))))
                     v+)
                 vector-length-key
                 (syntax-e #'v.length))
    (syntax/loc stx v++)]
   [_:id
    (syntax/loc stx vector-map!)]
   [(_ e* ...)
    (syntax/loc stx (vector-map! e* ...))]))

(define-syntax (vector-append: stx)
  (syntax-parse stx
   [(_ v1:vector/length v2:vector/length)
    #:with v1+ (gensym 'v1)
    #:with v2+ (gensym 'v2)
    (define l1 (syntax-e #'v1.length))
    (define l2 (syntax-e #'v2.length))
    (syntax-property
      (if (and (small-vector-size? l1)
               (small-vector-size? l2))
        (with-syntax ([(i1* ...) (for/list ([i (in-range l1)]) i)]
                      [(i2* ...) (for/list ([i (in-range l2)]) i)])
          (syntax/loc stx
            (let ([v1+ v1.expanded]
                  [v2+ v2.expanded])
              (vector (vector-ref: v1+ i1*) ...
                      (vector-ref: v2+ i2*) ...))))
        (quasisyntax/loc stx
          (let ([v1+ v1.expanded]
                [v2+ v2.expanded])
            (build-vector
              #,(+ l1 l2)
              (lambda (i)
                (if (< i '#,l1)
                  (unsafe-vector-ref v1+ i)
                  (unsafe-vector-ref v2+ i)))))))
      vector-length-key
      (+ l1 l2))]
   [_:id
    (syntax/loc stx vector-append)]
   [(_ e* ...)
    (syntax/loc stx (vector-append e* ...))]))

(define-syntax (vector->list: stx)
  (syntax-parse stx
   [(_ v:vector/length)
    #:with v+ (gensym 'v)
    (define len (syntax-e #'v.length))
    (if (small-vector-size? len)
      (with-syntax ([(i* ...) (for/list ([i (in-range len)]) i)])
        (syntax/loc stx
          (let ([v+ v.expanded])
            (list (unsafe-vector-ref v+ i*) ...))))
      (syntax/loc stx
        (let ([v+ v.expanded])
          (build-list 'v.length (lambda (i) (unsafe-vector-ref v+ i))))))]
   [_:id
    (syntax/loc stx vector->list)]
   [(_ e* ...)
    (syntax/loc stx (vector->list e* ...))]))

(define-syntax (vector->immutable-vector: stx)
  (syntax-parse stx
   [(_ v:vector/length)
    (syntax-property
      (syntax/loc stx (vector->immutable-vector v.expanded))
      vector-length-key
      (syntax-e #'v.length))]
   [_:id
    (syntax/loc stx vector->immutable-vector)]
   [(_ e* ...)
    (syntax/loc stx (vector->immutable-vector e* ...))]))

(define-syntax (vector-fill!: stx)
  (syntax-parse stx
   [(_ v:vector/length val)
    #:with v+ (gensym 'v)
    (define len (syntax-e #'v.length))
    (syntax-property
      (syntax/loc stx
        (let ([v+ v.expanded])
          (for ([i (in-range 'v.length)])
            (unsafe-vector-set! v+ i val))))
      vector-length-key
      (syntax-e #'v.length))]
   [_:id
    (syntax/loc stx vector->fill!)]
   [(_ e* ...)
    (syntax/loc stx (vector->fill! e* ...))]))

;; -----------------------------------------------------------------------------

(define-for-syntax (small-vector-size? n)
  (< n 20))

;; Assume `stx` is creating a vector; get the length of the vector to-be-made
(define-for-syntax (parse-vector-length stx)
  (cond
   [(syntax-property stx vector-length-key)
    => (lambda (x) x)]
   [(identifier? stx)
    (free-id-table-ref id+vector-length stx #f)]
   [else
     (syntax-parse stx #:literals (vector make-vector build-vector)
      [(~or '#(e* ...)
            #(e* ...)
            ;; TODO #{} #[] #6{} ...
            (_ vector e* ...) ;; TODO the _ should be matching #%app
            (vector e* ...))
       (length (syntax->list #'(e* ...)))]
      [(~or (make-vector n e* ...)
            (_ make-vector n e* ...)
            (build-vector n e* ...)
            (_ build-vector n e* ...))
       (if (syntax-transforming?)
         (quoted-stx-value? (expand-expr #'n))
         (and (exact-nonnegative-integer? (syntax-e #'n)) (syntax-e #'n)))]
      [_
       #f])]))
