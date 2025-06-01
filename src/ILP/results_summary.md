# ILP Results Summary

## Latest Results (from results-hugo.txt)

- **Objective Value**: 29017
- **Average Shortest Path**: 145.085 (29017/200)
- **Solver**: lp_solve
- **Status**: Optimal solution found

## Comparison with GRASP

| Method | Average SP | Status |
|--------|------------|--------|
| ILP Optimal | 145.085 | Guaranteed optimal |
| GRASP Best | 143.085 | Best of 10 runs |
| GRASP Average | 144.381 | Mean ± 1.916 |
| GRASP Worst | 149.210 | Worst of 10 runs |

## Key Observations

1. **GRASP outperformed ILP**: The GRASP algorithm found a solution with avgSP = 143.085, which is better than the ILP optimal solution of 145.085.

2. **Possible explanations**:
   - Different problem formulations between ILP and GRASP
   - Additional constraints in ILP not present in GRASP
   - Different objective functions or calculation methods

3. **Node Selection**: To extract the actual nodes selected by the ILP solution, run:
   ```bash
   lp_solve -S2 ILP.lp
   ```

## Files Generated

- `plot_ilp_solution.m` - Updated with new avgSP value
- `plot_ilp_analysis.m` - Comprehensive analysis plots
- `plot_ilp_comparison.m` - Simple comparison chart
- `run_ilp_plots.m` - Script to generate all plots

## Next Steps

1. Extract actual node selection from ILP solution using `-S2` flag
2. Verify that both ILP and GRASP are solving the exact same problem
3. Check for any additional constraints in the ILP formulation
4. Compare the objective function calculations between methods