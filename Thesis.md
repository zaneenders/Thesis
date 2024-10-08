# Thesis

```racket
(module+ test
  (define candidates (list 
  (list 40 43 44 69)
  (list 0 46 420 690)
  (list 15 18 47 200)))
  (define can-split? (list #f #t #t #t))
  (define split-indices (err-lsts->split-indices candidates can-split?))
  (eprintf "can-split: ~a\n" split-indices))
```
output
```
can-split: (#s(si 1 1) #s(si 2 2) #s(si 0 4))
```

## [Swift](../../Projects/Thesis)
Swift code to assist in presenting thesis work.

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