# Thesis

```racket
(module+ test
  (define candidates
    (list (list 40.0 43.0 44.0 69.0 420.0) ; index 0
          (list 15.0 18.0 47.0 200.0 469.0) ; index 1
          (list 0.0 46.0 420.0 690.0 999.0))) ; index 2
  (define can-split? (list #f #t #t #t #t))
  (define split-indices (err-lsts->split-indices candidates can-split?))
  (eprintf "can-split: ~a\n" split-indices)
  (check-equal? split-indices (list (si 2 1) (si 1 2) (si 0 5))))
```
initial data
```
row: #(struct:cse 40 (#s(si 0 1)))
row: #(struct:cse 0 (#s(si 1 1)))
row: #(struct:cse 15 (#s(si 2 1)))

row: #(struct:cse 83 (#s(si 0 2)))
row: #(struct:cse 46 (#s(si 1 2)))
row: #(struct:cse 33 (#s(si 2 2)))

row: #(struct:cse 127 (#s(si 0 3)))
row: #(struct:cse 466 (#s(si 1 3)))
row: #(struct:cse 80 (#s(si 2 3)))

row: #(struct:cse 196 (#s(si 0 4)))
row: #(struct:cse 1156 (#s(si 1 4)))
row: #(struct:cse 280 (#s(si 2 4)))

inital: #(#(struct:cse 0 (#s(si 1 1))) #(struct:cse 33 (#s(si 2 2))) #(struct:cse 80 (#s(si 2 3))) #(struct:cse 196 (#s(si 0 4))))
```

Add split point input and output data
```
#(
    #(struct:cse 0 (#s(si 1 1)))
    #(struct:cse 33 (#s(si 2 2)))
    #(struct:cse 80 (#s(si 2 3)))
    #(struct:cse 196 (#s(si 0 4)))
    #(struct:cse 616 (#s(si 0 5))))
#(
    #(struct:cse 0 (#s(si 1 1)))
    #(struct:cse 18 (#s(si 2 2) #s(si 1 1)))
    #(struct:cse 65 (#s(si 2 3) #s(si 1 1)))
    #(struct:cse 146 (#s(si 0 4) #s(si 2 2)))
    #(struct:cse 566 (#s(si 0 5) #s(si 2 2))))

#(
    #(struct:cse 0 (#s(si 1 1)))
    #(struct:cse 18 (#s(si 2 2) #s(si 1 1)))
    #(struct:cse 65 (#s(si 2 3) #s(si 1 1)))
    #(struct:cse 146 (#s(si 0 4) #s(si 2 2)))
    #(struct:cse 566 (#s(si 0 5) #s(si 2 2))))
#(
    #(struct:cse 0 (#s(si 1 1)))
    #(struct:cse 18 (#s(si 2 2) #s(si 1 1)))
    #(struct:cse 65 (#s(si 2 3) #s(si 1 1)))
    #(struct:cse 131 (#s(si 0 4) #s(si 2 2) #s(si 1 1)))
    #(struct:cse 551 (#s(si 0 5) #s(si 2 2) #s(si 1 1))))

#(
    #(struct:cse 0 (#s(si 1 1)))
    #(struct:cse 18 (#s(si 2 2) #s(si 1 1)))
    #(struct:cse 65 (#s(si 2 3) #s(si 1 1)))
    #(struct:cse 131 (#s(si 0 4) #s(si 2 2) #s(si 1 1)))
    #(struct:cse 551 (#s(si 0 5) #s(si 2 2) #s(si 1 1))))
#(
    #(struct:cse 0 (#s(si 1 1)))
    #(struct:cse 18 (#s(si 2 2) #s(si 1 1)))
    #(struct:cse 65 (#s(si 2 3) #s(si 1 1)))
    #(struct:cse 131 (#s(si 0 4) #s(si 2 2) #s(si 1 1)))
    #(struct:cse 551 (#s(si 0 5) #s(si 2 2) #s(si 1 1))))
```
```
(eprintf "out: errors ~a\n" result-error-sums)
(eprintf "out: alt ~a\n" result-alt-idxs)
(eprintf "out: prev ~a\n" result-prev-idxs)
```
```
out: errors #fl(0.0 23.0 70.0 141.0 561.0)
out: alt #(1 2 2 0 0)
out: prev #(5 0 0 1 1)
```
```
; (is-better total-error current-cum-error (vector-ref result-alt-idxs point-idx)  (vector-ref result-alt-idxs prev-split-idx) (vector-ref result-prev-idxs point-idx) prev-split-idx)
(define (is-better total-error current-cum-error alt prev-alt point prev-point)
  (cond
    [(fl< total-error current-cum-error) #t]
    [(and (fl= total-error current-cum-error) (> alt prev-alt)) #t]
    [(and (fl= total-error current-cum-error) (= alt prev-alt) (> point prev-point)) #t]
    [else #f]))
```
current new-alogthim
```
(is-better alt-error-sum
                       current-alt-error
                       current-alt-idx
                       best-alt-idx
                       current-prev-idx
                       prev-split-idx)
```

```sh
racket -y src/main.rkt report --threads 1 --seed 0 zane/regimes.fpcore zane/thesis
```

`(define *num-points* (make-parameter 4))` Number of points set to 4

```
(FPCore (R lambda1 lambda2 phi1 phi2)
 :precision binary64
 (let* ((t_0 (sin (/ (- lambda1 lambda2) 2.0)))
        (t_1
         (+
          (pow (sin (/ (- phi1 phi2) 2.0)) 2.0)
          (* (* (* (cos phi1) (cos phi2)) t_0) t_0))))
   (* R (* 2.0 (atan2 (sqrt t_1) (sqrt (- 1.0 t_1)))))))
```
```
; data
candidates: ((51.73568596790282 49.822030173660636 51.31420959276469 51.96847903282816) (41.318643601299854 49.822030173660636 51.31420959276469 51.99892682317375) (42.3256126189509 46.70539859821504 56.62134690410728 51.96847903282816))
can-split-lst: (#f #t #t #t)
```

## Matching on Doubles
https://godbolt.org/z/G1soPnvPM
func idk(_ d: Double) {
    switch d {
        case -1...1: // use ucomisd
        fast(d)
        case -2..<1:
        fast(d)
        default:
        slow(d)
    }
}

@inline(__always)
func fast(_ d: Double) {
    let x = d + 1
    print(x)
}

@inline(__always)
func slow(_ d: Double) {
    let x = d / 100000
    print(x)
}

commit `927e7f73` for original