enum Original {

    static func regimes(err_list candidates: [[Double]], _ can_split: [Bool]) -> [SplitIndex] {
        // (define num-candidates (length err-lsts))
        let num_candidates = candidates.count
        // (define num-points (length (car err-lsts)))
        let num_points = candidates.first!.count
        // (define min-weight num-points)
        var min_weight = num_points
        // (define psums (map (compose partial-sums list->vector) err-lsts))
        let psums = partial_sums(candidates)
        // (define can-split? (curry vector-ref (list->vector can-split-lst)))
        /*
        initial: #(#(struct:cse 0 (#s(si 1 1))) #(struct:cse 33 (#s(si 2 2))) #(struct:cse 80 (#s(si 2 3))) #(struct:cse 196 (#s(si 0 4))))
        */
        let initial = initial(psums.first!.count, psums)
        func final(_ prev: [CSE]) -> [CSE] {
            let next = addSplitPoint(num_points, prev, Double(num_points), psums, can_split)
            if prev == next {
                return next
            } else {
                return final(next)
            }
        }
        return final(initial).last!.indices.reversed()
    }

    static func addSplitPoint(
        _ num_points: Int, _ prev: [CSE], _ min_weight: Double,
        _ partial_sums: [[Double]], _ can_split: [Bool]
    ) -> [CSE] {
        var out: [CSE] = []
        for (point_idx, point) in prev.enumerated() {
            var acost = point.cost - min_weight
            var aest = point
            for (prev_split_idx, prev_entry) in zip(0..<point_idx, prev) {
                if can_split[prev_entry.indices.first!.pidx] {
                    var best: Int? = nil
                    var best_cost: Double? = nil
                    for (cidx, psum) in partial_sums.enumerated() {
                        let cost = psum[point_idx] - psum[prev_split_idx]
                        if best_cost == nil || cost < best_cost! {
                            best_cost = cost
                            best = cidx
                        }
                    }
                    if prev_entry.cost + best_cost! < acost {
                        acost = prev_entry.cost + best_cost!
                        let entries: [SI] = [SI(best!, point_idx + 1)] + prev_entry.indices
                        aest = CSE(acost, entries)
                    }
                }
            }
            out.append(aest)
        }
        return out
    }

/*
cand-idx: 0, cand-psums: #(40 83 127 196), cse: #(struct:cse 40 (#s(si 0 1)))
cand-idx: 1, cand-psums: #(0 46 466 1156), cse: #(struct:cse 0 (#s(si 1 1)))
cand-idx: 2, cand-psums: #(15 33 80 280), cse: #(struct:cse 15 (#s(si 2 1)))

cand-idx: 0, cand-psums: #(40 83 127 196), cse: #(struct:cse 83 (#s(si 0 2)))
cand-idx: 1, cand-psums: #(0 46 466 1156), cse: #(struct:cse 46 (#s(si 1 2)))
cand-idx: 2, cand-psums: #(15 33 80 280), cse: #(struct:cse 33 (#s(si 2 2)))

cand-idx: 0, cand-psums: #(40 83 127 196), cse: #(struct:cse 127 (#s(si 0 3)))
cand-idx: 1, cand-psums: #(0 46 466 1156), cse: #(struct:cse 466 (#s(si 1 3)))
cand-idx: 2, cand-psums: #(15 33 80 280), cse: #(struct:cse 80 (#s(si 2 3)))

cand-idx: 0, cand-psums: #(40 83 127 196), cse: #(struct:cse 196 (#s(si 0 4)))
cand-idx: 1, cand-psums: #(0 46 466 1156), cse: #(struct:cse 1156 (#s(si 1 4)))
cand-idx: 2, cand-psums: #(15 33 80 280), cse: #(struct:cse 280 (#s(si 2 4)))
*/
    /*
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
*/
    static func initial(_ num_points: Int, _ candidates: [[Double]]) -> [CSE] {
        var out: [CSE] = []
        for point_idx in 0..<num_points {
            var options: [CSE] = []
            for (can_idx, candidate) in candidates.enumerated() {
                let cse = CSE(candidate[point_idx], [SplitIndex(can_idx, point_idx + 1)])
                options.append(cse)
            }
            var min: Double = Double.infinity
            var min_idx = 0
            for (i, option) in options.enumerated() {
                if option.cost < min {
                    min = option.cost
                    min_idx = i
                }
            }
            out.append(options[min_idx])
        }
        return out
    }
}
