enum Original {

    static func regimes(err_list candidates: [[Double]], _ can_split: [Bool]) -> [SplitIndex] {
        let num_points = candidates.first!.count
        let psums = partial_sums(candidates)
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
                        let entries: [SI] = [SI(cidx: best!, pidx: point_idx + 1)] + prev_entry.indices
                        aest = CSE(acost, entries)
                    }
                }
            }
            out.append(aest)
        }
        return out
    }

    static func initial(_ num_points: Int, _ candidates: [[Double]]) -> [CSE] {
        var out: [CSE] = []
        for point_idx in 0..<num_points {
            var options: [CSE] = []
            for (can_idx, candidate) in candidates.enumerated() {
                let cse = CSE(candidate[point_idx], [SplitIndex(cidx: can_idx, pidx: point_idx + 1)])
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
