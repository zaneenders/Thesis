/*
(define (partial-sums vec)
  (define res (make-vector (vector-length vec)))
  (for/fold ([cur-psum 0]) ([(el idx) (in-indexed (in-vector vec))])
    (let ([new-psum (+ cur-psum el)])
      (vector-set! res idx new-psum)
      new-psum))
  res)
*/
func partial_sums(_ candidates: [[Double]]) -> [[Double]] {
    var out = Array(repeating: Array(repeating: 0.0, count: candidates.first!.count), count: candidates.count)
    for (c, candidate) in candidates.enumerated() {
        var sum = 0.0
        for (p, point) in candidate.enumerated() {
            sum += point
            out[c][p] = sum
        }
        sum = 0.0
    }
    return out
}

/// CSE
// Struct representing a candidate set of splitpoints that we are considering.
// cost = The total error in the region to the left of our rightmost splitpoint
// indices = The si's we are considering in this candidate.
typealias CSE = Alt
struct Alt {
    let cost: Double
    let indices: [SplitIndex]
}

extension CSE {
    init(_ cost: Double, _ indices: [SplitIndex]) {
        self.cost = cost
        self.indices = indices
    }
}
extension CSE: Equatable {}

typealias SI = SplitIndex
/// Split Index
struct SplitIndex {
    let cidx: Int  // candidate index
    let pidx: Int  // point index
}
extension SplitIndex {
    init(_ cidx: Int, _ pidx: Int) {
        self.cidx = cidx
        self.pidx = pidx
    }
}
extension SplitIndex: Equatable {}
