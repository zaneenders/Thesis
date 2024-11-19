(struct si (cidx pidx) #:prefab)
;; Struct representing a candidate set of splitpoints that we are considering.
;; cost = The total error in the region to the left of our rightmost splitpoint
;; indices = The si's we are considering in this candidate.
(struct cse (cost indices) #:transparent)
;; TODO messy, delete me only used to setup data in (initial)
(struct cand (acost idx point-idx prev-idx) #:transparent)
;; Given error-lsts, returns a list of sp objects representing where the optimal splitpoints are.

;; This is the core main loop of the regimes algorithm.
;; Takes in a list of alts in the form of there error at a given point
;; as well as a list of split indices to determine when it's ok to split
;; for another alt.
;; Returns a list of split indices saying which alt to use for which
;; range of points. Starting at 1 going up to num-points.
;; Alts are indexed 0 and points are index 1.
(define/contract (err-lsts->split-indices err-lsts can-split)
  (->i ([e (listof list)] [cs (listof boolean?)]) [result (cs) (curry valid-splitindices? cs)])
  ;; Coverts the list to vector form for faster processing
  (define can-split-vec (list->vector can-split))
  ;; Converting list of list to list of flvectors
  ;; flvectors are used to remove pointer chasing
  (define (make-vec-psum lst)
    (flvector-sums (list->flvector lst)))
  (define flvec-psums (vector-map make-vec-psum (list->vector err-lsts)))

  ;; Set up data needed for algorithm

  (define number-of-points (vector-length can-split-vec))
  ;; min-weight is used as penalty to favor not adding split points
  (define min-weight (fl number-of-points))

  ;; These 3 vectors are will contain the output data and be used for
  ;; determining which alt is best for a given point
  (define result-error-sums (make-flvector number-of-points +inf.0))
  (define result-alt-idxs (make-vector number-of-points 0))
  (define result-prev-idxs (make-vector number-of-points number-of-points))

  (for ([alt-idx (in-naturals)]
        [alt-errors (in-vector flvec-psums)])
    (for ([point-idx (in-range number-of-points)]
          [err (in-flvector alt-errors)]
          #:when (< err (flvector-ref result-error-sums point-idx)))
      (flvector-set! result-error-sums point-idx err)
      (vector-set! result-alt-idxs point-idx alt-idx)))

  ;; Vectors are now filled with starting data. Beginning main loop of the
  ;; regimes algorithm.

  ;; Vectors used to determine if our current alt is better than our running
  ;; best alt.
  (define best-alt-idxs (make-vector number-of-points))
  (define best-alt-costs (make-flvector number-of-points))

  ; P
  (for ([point-idx (in-range 0 number-of-points)]
        [current-alt-error (in-flvector result-error-sums)]
        [current-alt-idx (in-vector result-alt-idxs)]
        [current-prev-idx (in-vector result-prev-idxs)])
    ;; Set and fill temporary vectors with starting data
    ;; #f for best index and positive infinite for best cost
    (vector-fill! best-alt-idxs #f)
    (set! best-alt-costs (make-flvector number-of-points +inf.0))

    ;; For each alt loop over its vector of errors ; A
    (for ([alt-idx (in-naturals)]
          [alt-error-sums (in-vector flvec-psums)])
      ;; Loop over the points up to our current point
      (for ([prev-split-idx (in-range 0 point-idx)]; P
            [prev-alt-error-sum (in-flvector alt-error-sums)]
            [best-alt-idx (in-vector best-alt-idxs)]
            [best-alt-cost (in-flvector best-alt-costs)]
            [can-split (in-vector can-split-vec 1)]
            #:when can-split)
        ;; Check if we can add a split point
        ;; compute the difference between the current error-sum and previous
        (let ([current-error (fl- (flvector-ref alt-error-sums point-idx) prev-alt-error-sum)])
          ;; if we have not set the best alt yet or
          ;; the current alt-error-sum is less then previous
          (when (or (not best-alt-idx) (fl< current-error best-alt-cost))
            ;; update best cost and best index
            (flvector-set! best-alt-costs prev-split-idx current-error)
            (vector-set! best-alt-idxs prev-split-idx alt-idx)))))
    ;; We have now have the index of the best alt and its error up to our
    ;; current point-idx.
    ;; Now we compare against our current best saved in the 3 vectors above
    (for ([prev-split-idx (in-range 0 point-idx)]
          [r-error-sum (in-flvector result-error-sums)]
          [best-alt-idx (in-vector best-alt-idxs)]
          [best-alt-cost (in-flvector best-alt-costs)]
          [can-split (in-vector can-split-vec 1)]
          #:when can-split)
      ;; Re compute the error sum for a potential better alt
      (define alt-error-sum (fl+ r-error-sum best-alt-cost min-weight))
      ;; Check if the new alt-error-sum is better then the current
      (define set-cond
        ;; give benefit to previous best alt
        (cond
          [(fl< alt-error-sum current-alt-error) #t]
          ;; Tie breaker if error are the same favor first alt
          [(and (fl= alt-error-sum current-alt-error) (> current-alt-idx best-alt-idx)) #t]
          ;; Tie breaker for if error and alt is the same
          [(and (fl= alt-error-sum current-alt-error)
                (= current-alt-idx best-alt-idx)
                (> current-prev-idx prev-split-idx))
           #t]
          [else #f]))
      (when set-cond
        (set! current-alt-error alt-error-sum)
        (set! current-alt-idx best-alt-idx)
        (set! current-prev-idx prev-split-idx)))
    (flvector-set! result-error-sums point-idx current-alt-error)
    (vector-set! result-alt-idxs point-idx current-alt-idx)
    (vector-set! result-prev-idxs point-idx current-prev-idx))

  ;; Loop over results vectors in reverse and build the output split index list
  (define next number-of-points)
  (define split-idexs #f)
  (for ([i (in-range (- number-of-points 1) -1 -1)]
        #:when (= (+ i 1) next))
    (define alt-idx (vector-ref result-alt-idxs i))
    (define split-idx (vector-ref result-prev-idxs i))
    (set! next (+ split-idx 1))
    (set! split-idexs
          (cond
            [(false? split-idexs) (cons (si alt-idx number-of-points) '())]
            [else (cons (si alt-idx (+ i 1)) split-idexs)])))
  split-idexs)