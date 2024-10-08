enum New {
    static func regimes(err_list candidates: [[Double]], _ can_splits: [Bool]) -> [SplitIndex] {
        let psums = partial_sums(candidates)
        let number_of_points = can_splits.count
        let min_weight = Double(number_of_points)
        var result_error_sums = Array(repeating: Double.infinity, count: number_of_points)
        var result_alt_idxs = Array(repeating: 0, count: number_of_points)
        var result_prev_idxs = Array(repeating: number_of_points, count: number_of_points)

        for (alt_idx, alt_errors) in psums.enumerated() {
            for (point_idx, err) in zip(0..<number_of_points, alt_errors) {
                if err < result_error_sums[point_idx] {
                    result_error_sums[point_idx] = err
                    result_alt_idxs[point_idx] = alt_idx
                }
            }
        }
        // Vectors are now filled with starting data. Beginning main loop of the
        // regimes algorithm.
        for ((point_idx, current_alt_error), (current_alt_idx, current_prev_idx)) in zip(
            zip(0..<number_of_points, result_error_sums), zip(result_alt_idxs, result_prev_idxs))
        {
            var copy_current_alt_error = current_alt_error
            var copy_current_alt_idx = current_alt_idx
            var copy_current_prev_idx = current_prev_idx
            // Vectors used to determine if our current alt is better than our running
            // best alt.
            // Set and fill temporary vectors with starting data
            // nil for best index and positive infinite for best cost
            var best_alt_idxs: [Int?] = Array(repeating: nil, count: number_of_points)
            var best_alt_costs = Array(repeating: Double.infinity, count: number_of_points)

            //  For each alt loop over its vector of errors
            for (alt_idx, alt_error_sums) in psums.enumerated() {
                // Loop over the points up to our current point
                for (
                    (  // LOL formatting
                        (prev_split_idx, prev_alt_error_sum),
                        (best_alt_idx, best_alt_cost)
                    ), can_split
                ) in zip(
                    zip(  // lol variadic zip please
                        zip(0..<point_idx, alt_error_sums),
                        zip(best_alt_idxs, best_alt_costs)), can_splits.dropFirst()
                        // TODO check can split index, should start with second
                ) {
                    if can_split {
                        let current_error = alt_error_sums[point_idx] - prev_alt_error_sum
                        if best_alt_idx == nil || current_error < best_alt_cost {
                            best_alt_costs[prev_split_idx] = current_error
                            best_alt_idxs[prev_split_idx] = alt_idx
                        }

                    }
                }
            }
            // We have now have the index of the best alt and its error up to our
            // current point-idx.
            // Now we compare against our current best saved in the 3 vectors above
            for (
                (  // LOL formatting
                    (prev_split_idx, result_error_sum),
                    (best_alt_idx, best_alt_cost)
                ), can_split
            ) in zip(
                zip(  // lol variadic zip please
                    zip(0..<point_idx, result_error_sums),
                    zip(best_alt_idxs, best_alt_costs)), can_splits.dropFirst()
            ) {

                if can_split {
                    // Re compute the error sum for a potential better alt
                    // Check if the new alt-error-sum is better then the current
                    /*
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
                    */
                    let alt_error_sum = result_error_sum + best_alt_cost + min_weight
                    let c1 = alt_error_sum < copy_current_alt_error
                    let c2 = alt_error_sum == current_alt_error && copy_current_alt_idx > best_alt_idx!
                    let c3 =
                        alt_error_sum == copy_current_alt_error && copy_current_alt_idx == best_alt_idx!
                        && copy_current_prev_idx > prev_split_idx
                    if c1 || c2 || c3 {
                        copy_current_alt_error = alt_error_sum
                        copy_current_alt_idx = best_alt_idx!
                        copy_current_prev_idx = prev_split_idx
                    }
                }
            }
            result_error_sums[point_idx] = copy_current_alt_error
            result_alt_idxs[point_idx] = copy_current_alt_idx
            result_prev_idxs[point_idx] = copy_current_prev_idx
        }

        // Loop over results vectors in reverse and build the output split index list
        var next = number_of_points
        var split_indexs: [SplitIndex] = []
        for i in stride(from: number_of_points - 1, to: -1, by: -1) {
            if i + 1 == next {
                let alt_idx = result_alt_idxs[i]
                let split_index = result_prev_idxs[i]
                next = split_index + 1
                if split_indexs.isEmpty {
                    split_indexs.append(SI(cidx: alt_idx, pidx: number_of_points))
                } else {
                    split_indexs.insert(SI(cidx: alt_idx, pidx: i + 1), at: 0)
                }
            }
        }
        return split_indexs
    }
}
