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
(define/contract (err-lsts->split-indices err-lsts can-split-lst)
  (->i ([e (listof list)] [cs (listof boolean?)]) [result (cs) (curry valid-splitindices? cs)])
  ;; We have num-candidates candidates, each of whom has error lists of length num-points.
  ;; We keep track of the partial sums of the error lists so that we can easily find the cost of regions.
  (define num-candidates (length err-lsts))
  (define num-points (length (car err-lsts)))
  (define min-weight num-points)

  (define psums (map (compose partial-sums list->vector) err-lsts))
  (define can-split? (curry vector-ref (list->vector can-split-lst)))

  ;; Our intermediary data is a list of cse's,
  ;; where each cse represents the optimal splitindices after however many passes
  ;; if we only consider indices to the left of that cse's index.
  ;; Given one of these lists, this function tries to add another splitindices to each cse.
  (define (add-splitpoint sp-prev)
    ;; If there's not enough room to add another splitpoint, just pass the sp-prev along.
    (define out
      (for/vector #:length num-points ; P
        ([point-idx (in-naturals)] [candidate (in-vector sp-prev)])
        ;; We take the CSE corresponding to the best choice of previous split point.
        ;; The default, not making a new split-point, gets a bonus of min-weight
        (let ([acost (- (cse-cost candidate) min-weight)] [aest point-entry])
          (for ([prev-split-idx (in-range 0 point-idx)] ; P
                [prev-candidate (in-vector sp-prev)]
                #:when (can-split? (si-pidx (car (cse-indices prev-candidate)))))
            ;; For each previous split point, we need the best candidate to fill the new regime
            (let ([best #f] [bcost #f])
              (for ([cidx (in-naturals)] [psum (in-list psums)])
                (let ([cost (- (vector-ref psum point-idx) (vector-ref psum prev-split-idx))])
                  (when (or (not best) (< cost bcost))
                    (set! bcost cost)
                    (set! best cidx))))
              (when (and (< (+ (cse-cost prev-candidate) bcost) acost))
                (set! acost (+ (cse-cost prev-candidate) bcost))
                (set! aest (cse acost (cons (si best (+ point-idx 1)) (cse-indices prev-entry)))))))
          aest)))
    out)

  ;; We get the initial set of cse's by, at every point-index,
  ;; accumulating the candidates that are the best we can do
  ;; by using only one candidate to the left of that point.
  (define initial
    (for/vector #:length num-points
      ([point-idx (in-range num-points)])
      (argmin cse-cost
              ;; Consider all the candidates we could put in this region
              (map (λ (cand-idx cand-psums)
                     (let ([cost (vector-ref cand-psums point-idx)])
                       (cse cost (list (si cand-idx (+ point-idx 1))))))
                   (range num-candidates)
                   psums))))
  ;; We get the final splitpoints by applying add-splitpoints as many times as we want
  (define final
    (let loop ([prev initial])
      (let ([next (add-splitpoint prev)]) (if (equal? prev next) next (loop next)))))

  ;; Extract the splitpoints from our data structure, and reverse it.
  (reverse (cse-indices (vector-ref final (- num-points 1)))))