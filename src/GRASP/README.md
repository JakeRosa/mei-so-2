# GRASP Implementation for Server Node Selection

## 📁 Folder Structure

```
GRASP/
├── 📂 core/                    # Core GRASP algorithm implementations
│   ├── GRASP.m                # Original GRASP algorithm
│   ├── GRASPOptimized.m       # Optimized version with caching & early termination
│   ├── greedyRandomized.m     # Original greedy randomized construction
│   ├── greedyRandomizedOptimized.m  # Optimized construction with caching
│   └── steepestAscentHillClimbing.m # Local search phase
│
├── 📂 analysis/                # Analysis and visualization functions
│   ├── analyzeExistingResults.m      # Quick analysis of saved results
│   ├── analyzeNodeFrequency.m        # Node importance analysis
│   ├── analyzePhaseContribution.m    # Construction vs local search analysis
│   ├── compareOptimizations.m        # Original vs optimized comparison
│   ├── plotGRASPPhaseAnalysis.m      # Phase analysis visualization
│   ├── plotParameterSensitivityHeatMap.m  # Parameter tuning heat maps
│   └── plotParameterVariation.m      # Parameter variation plots
│
├── 📂 runners/                 # Main execution scripts
│   ├── runGRASP.m             # Main GRASP execution with all options
│   ├── runStandaloneAnalysis.m     # Fresh analysis functions
│   └── runStandaloneAnalysisWithResults.m  # Analysis using existing results
│
├── 📂 utilities/               # Helper functions
│   └── debugGRASPData.m       # Data debugging utility
│
├── 📂 exports/                 # Export functions
│   ├── exportGraspResults.m   # Export results to CSV
│   └── exportParameterStats.m # Export parameter statistics
│
├── 📂 lib/                     # Library functions
│   └── writeCSV.m             # CSV writing utility
│
├── 📂 output/                  # Algorithm execution logs
├── 📂 plots/                   # Generated visualizations
├── 📂 results/                 # Saved results and analysis data
├── main.m                      # Main entry point
└── README.md                   # This file
```

## 🚀 Quick Start

### Run Complete Analysis
```matlab
main()                          % Interactive menu
main('optimized', 'analysis')   % Optimized GRASP with all analysis
```

### Run Specific Analysis
```matlab
main('existing')                % Analyze existing results only
main('fresh')                   # Run fresh GRASP + analysis
main('comparison')              # Compare implementations
```

### Terminal Usage
```bash
cd "path/to/mei-so-2/src/GRASP"
matlab -nodisplay -nosplash -r "main('optimized', 'analysis'); exit"
```

## 📊 Analysis Functions

| Function | Purpose | Data Source |
|----------|---------|-------------|
| `analyzeExistingResults()` | Quick stats from saved results | `results/GRASP_results.mat` |
| `analyzeNodeFrequency()` | Node importance analysis | Fresh GRASP runs |
| `analyzePhaseContribution()` | Construction vs local search | Fresh GRASP runs |
| `compareOptimizations()` | Original vs optimized performance | Fresh runs both versions |
| `plotParameterSensitivityHeatMap()` | Parameter tuning | Fresh GRASP grid search |

## 🔧 Algorithm Versions

### Original GRASP (`core/GRASP.m`)
- Standard two-phase GRASP
- Basic progress tracking
- Simple iteration counting

### Optimized GRASP (`core/GRASPOptimized.m`)
- **Caching**: Avoids redundant PerfSNS evaluations
- **Early Termination**: Stops on stagnation
- **Enhanced Tracking**: Phase-wise statistics
- **Memory Optimization**: Pre-allocated arrays

## 📈 Performance Improvements

| Feature | Expected Speedup | Benefit |
|---------|------------------|---------|
| Caching | 20-40% | Reduces redundant calculations |
| Early Termination | Up to 50% | Stops when no improvement |
| Memory Pre-allocation | 5-10% | Reduces allocation overhead |
| Vectorized Operations | Minor | Cleaner, more efficient code |

## 🎯 Key Outputs

### Plots Generated
- Parameter sensitivity heat maps
- Node frequency analysis
- Phase contribution analysis
- Implementation comparison charts
- Solution quality distributions
- Network visualizations

### Results Saved
- `results/GRASP_results.mat` - Main results file
- `results/*_analysis_*.mat` - Analysis results
- `plots/*.png` - All visualizations
- `output/*.txt` - Execution logs

## 📋 Requirements

- MATLAB with Graph Theory Toolbox
- Network data files in `../../data/`
- Functions: `loadData()`, `PerfSNS()`, `plotNetworkSolution()`

## 🔍 Troubleshooting

### Common Issues
1. **Path errors**: Run from GRASP directory
2. **Missing data**: Ensure `loadData()` works
3. **Memory issues**: Reduce `numRuns` parameters
4. **Long execution**: Use `'existing'` analysis mode

### Quick Diagnostics
```matlab
utilities/debugGRASPData()      % Check data loading
analysis/analyzeExistingResults() % Verify saved results
```