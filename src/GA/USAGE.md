# GA (Genetic Algorithm) Usage Guide

## Overview
This directory contains an organized implementation of a Genetic Algorithm for the Server Node Selection problem. The implementation includes standard and optimized versions with caching, comprehensive parameter tuning, and detailed analysis capabilities.

## Quick Start

### Basic Usage
```matlab
% Navigate to the GA directory
cd src/GA

% Run GA with default/best parameters
main()

% Run parameter tuning to find best configuration
main('tuning')

% Run full workflow (tuning + execution)
main('full')

% Run analysis on existing results
main('analysis')

% Compare standard vs optimized implementation
main('compare')

% Quick test run
main('test')

% Show help
main('help')
```

## Directory Structure

```
GA/
├── main.m                 # Main entry point with flag support
├── core/                  # Core GA algorithms
│   ├── GA.m              # Standard GA implementation
│   ├── GAOptimized.m     # Optimized GA with caching
│   ├── crossover.m       # Crossover operator
│   ├── mutation.m        # Mutation operator (first node only)
│   ├── evaluateFitness.m # Fitness evaluation
│   ├── tournamentSelection.m # Tournament selection
│   └── elitistSelection.m    # Elitist selection
├── runners/              # Execution runners
│   ├── runGA_standard.m  # Standard execution runner
│   ├── runParameterTuning.m # Parameter tuning runner
│   └── runGAComparison.m    # Comparison runner
├── analysis/             # Analysis functions
│   ├── createParameterAnalysisPlots.m
│   ├── createConvergencePlot.m
│   ├── createGASummaryPlots.m
│   ├── createPhaseAnalysisPlots.m
│   ├── createComparisonPlots.m
│   └── runStandaloneAnalysis.m
├── exports/              # Export functions
│   ├── exportGAResults.m
│   └── exportParameterTuningResults.m
├── output/               # Output logs
├── plots/                # Generated plots
│   ├── convergence/
│   ├── parameters/
│   ├── phases/
│   ├── comparison/
│   ├── summary/
│   └── analysis/
└── results/              # Result files (.mat, .csv)
```

## Execution Modes

### 1. Standard Run (default)
```matlab
main()
```
- Runs GA with best known parameters or defaults
- Executes 10 runs of 30 seconds each
- Generates summary plots and exports results

### 2. Parameter Tuning
```matlab
main('tuning')
```
- Tests different parameter combinations:
  - Population sizes: [20, 50, 100, 150]
  - Mutation rates: [0.05, 0.1, 0.2, 0.3]
  - Elite counts: [1, 5, 10, 15]
- Runs multiple tests per configuration
- Identifies best parameters
- Creates parameter analysis plots

### 3. Full Execution
```matlab
main('full')
```
- First runs parameter tuning
- Then executes GA with the best found parameters
- Complete workflow for optimal results

### 4. Test Mode
```matlab
main('test')
```
- Quick test with reduced parameters:
  - 3 test runs
  - 10 seconds per run
  - Useful for debugging

### 5. Analysis Mode
```matlab
main('analysis')
```
- Analyzes existing results
- Creates comprehensive plots:
  - Convergence analysis
  - Solution quality distribution
  - Node frequency analysis
  - Phase performance
- Exports detailed report

### 6. Comparison Mode
```matlab
main('compare')
```
- Compares standard GA vs optimized GA
- Shows performance improvements from caching
- Creates comparison plots

## Algorithm Details

### Key Features
1. **Elitist Selection**: Preserves best individuals across generations
2. **Tournament Selection**: For parent selection
3. **Crossover**: Order crossover adapted for set representation
4. **Mutation**: Only mutates the first node (smallest value) as specified
5. **Caching**: Optimized version caches fitness evaluations

### Parameters
- **Population Size**: Number of individuals per generation
- **Mutation Rate**: Probability of mutation (0-1)
- **Elite Count**: Number of best individuals to preserve
- **Time Limit**: Maximum execution time in seconds

## Output Files

### Logs
- `output/GA_output_<timestamp>.txt`: Execution log
- `output/GA_tuning_<timestamp>.txt`: Tuning log
- `output/GA_comparison_<timestamp>.txt`: Comparison log

### Results
- `results/GA_results_<timestamp>.mat`: Complete results
- `results/GA_summary_<timestamp>.csv`: Summary statistics
- `results/GA_convergence_run<n>_<timestamp>.csv`: Convergence data
- `results/GA_best_solution_<timestamp>.csv`: Best solution found
- `results/GA_best_params.mat`: Best parameters from tuning

### Plots
- **Convergence**: Generation-by-generation progress
- **Parameters**: Effect of different parameters
- **Phases**: Selection, crossover, mutation analysis
- **Summary**: Overall performance statistics
- **Comparison**: Standard vs optimized performance

## Configuration

Edit the `loadGAConfig()` function in `main.m` to modify default settings:

```matlab
config.problem.n = 12;          % Number of nodes to select
config.problem.Cmax = 1000;     % Max shortest path constraint

config.params.populationSize = 100;
config.params.mutationRate = 0.1;
config.params.eliteCount = 10;

config.tuning.testTime = 30;    % Seconds per tuning test
config.execution.runTime = 30;  % Seconds per execution run
```

## Tips for Best Results

1. **Start with tuning**: Run `main('tuning')` first to find optimal parameters
2. **Multiple runs**: GA is stochastic, multiple runs provide statistical confidence
3. **Monitor convergence**: Check if solutions plateau or continue improving
4. **Cache efficiency**: Optimized version shows significant speedup with high cache hit rates
5. **Diversity**: Monitor population diversity to avoid premature convergence

## Troubleshooting

- **No valid solutions**: Increase population size or mutation rate
- **Slow convergence**: Decrease elite count or increase mutation rate
- **High variability**: Increase elite count for more stability
- **Out of memory**: Reduce population size

## Example Workflow

```matlab
% 1. Find best parameters
main('tuning')

% 2. Run with best parameters
main()

% 3. Analyze results
main('analysis')

% 4. Compare implementations
main('compare')
```

## Notes

- The algorithm uses purely random initialization (no constraint checking)
- Mutation only affects the first node (smallest value) as specified
- Fitness evaluation uses penalty for constraint violations
- Results are automatically saved with timestamps