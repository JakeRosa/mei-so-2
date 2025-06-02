# Genetic Algorithm (GA) for Server Node Selection

## Overview

This directory contains a comprehensive implementation of a Genetic Algorithm (GA) for solving the Server Node Selection problem. The implementation features:

- **Standard GA**: Traditional genetic algorithm implementation
- **Optimized GA**: Enhanced version with fitness caching for improved performance
- **Parameter Tuning**: Automated parameter optimization
- **Comprehensive Analysis**: Detailed performance analysis and visualization
- **Modular Design**: Well-organized code structure for maintainability

## Quick Start

```matlab
% Navigate to GA directory
cd src/GA

% Run with best/default parameters
main()

% Find optimal parameters
main('tuning')

% Complete workflow
main('full')
```

## Algorithm Characteristics

### Selection
- **Tournament Selection**: Selects parents through tournament competition
- **Elitist Selection**: Preserves best individuals across generations

### Genetic Operators
- **Crossover**: Order crossover adapted for set-based representation
- **Mutation**: Only mutates the first node (smallest value) to maintain consistency

### Optimization Features
- **Fitness Caching**: Avoids redundant evaluations
- **Diversity Tracking**: Monitors genetic diversity
- **Adaptive Convergence**: Tracks improvement rates

## Key Components

1. **Core Algorithm** (`core/`)
   - Standard and optimized implementations
   - Genetic operators
   - Fitness evaluation

2. **Runners** (`runners/`)
   - Parameter tuning
   - Standard execution
   - Performance comparison

3. **Analysis** (`analysis/`)
   - Convergence analysis
   - Parameter sensitivity
   - Solution quality assessment

4. **Visualization** (`plots/`)
   - Real-time convergence plots
   - Parameter analysis heatmaps
   - Performance comparisons

## Performance Enhancements

The optimized version includes:
- **Fitness Caching**: 30-50% reduction in evaluations
- **Efficient Data Structures**: Faster operations
- **Performance Monitoring**: Cache hit rates and diversity metrics

## Results

Typical performance:
- Convergence in 100-300 generations
- Cache hit rates: 20-40%
- Solution quality: Competitive with other metaheuristics
- Execution time: 30 seconds per run (configurable)

See `USAGE.md` for detailed usage instructions and parameter configurations.