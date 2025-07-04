function main(varargin)
% Main entry point for GA with support for different execution modes
% Usage:
%   main()                     - Run full GA with best parameters
%   main('tuning')            - Run parameter tuning only
%   main('tuning-opt')        - Run parameter tuning for GAOptimized
%   main('analysis')          - Run analysis on existing results
%   main('full')              - Run tuning + full GA execution
%   main('test')              - Quick test run with reduced parameters
%   main('compare')           - Compare standard vs optimized GA
%   main('help')              - Show help message

    % Parse arguments
    if nargin == 0
        mode = 'run';
    else
        mode = lower(varargin{1});
    end
    
    % Add paths
    addpath('core');
    addpath('analysis');
    addpath('runners');
    addpath('utilities');
    addpath('exports');
    addpath('..');  % For PerfSNS and loadData
    
    % Load configuration
    config = loadGAConfig();
    configOptimized = loadGAOptimizedConfig();
    
    % Execute based on mode
    switch mode
        case 'help'
            showHelp();
            
        case 'tuning'
            fprintf('=== GA PARAMETER TUNING MODE ===\n');
            fprintf('Date and Time: %s\n', datestr(now));
            fprintf('================================\n\n');
            runParameterTuning(config, false);  % false for standard GA
            
        case 'tuning-opt'
            fprintf('=== GA OPTIMIZED PARAMETER TUNING MODE ===\n');
            fprintf('Date and Time: %s\n', datestr(now));
            fprintf('==========================================\n\n');
            runParameterTuning(configOptimized, true);  % true for GAOptimized
            
        case 'run'
            fprintf('=== GA EXECUTION MODE ===\n');
            fprintf('Date and Time: %s\n', datestr(now));
            fprintf('=========================\n\n');
            runGA_standard(config);
            
        case 'run-opt'
            fprintf('=== GA OPTIMIZED EXECUTION MODE ===\n');
            fprintf('Date and Time: %s\n', datestr(now));
            fprintf('===================================\n\n');
            runGA_optimized(configOptimized);
            
        case 'full'
            fprintf('=== GA FULL EXECUTION MODE ===\n');
            fprintf('Date and Time: %s\n', datestr(now));
            fprintf('==============================\n\n');
            
            % First run tuning for standard GA
            fprintf('\n--- Standard GA Tuning ---\n');
            bestParams = runParameterTuning(config, false);
            config.params = bestParams;
            
            % Run standard GA with best parameters
            fprintf('\n--- Standard GA Execution ---\n');
            runGA_standard(config);
            
            % Run tuning for optimized GA
            fprintf('\n--- Optimized GA Tuning ---\n');
            bestParamsOpt = runParameterTuning(configOptimized, true);
            configOptimized.params = bestParamsOpt;
            
            % Run optimized GA with best parameters
            fprintf('\n--- Optimized GA Execution ---\n');
            runGA_optimized(configOptimized);
            
        case 'test'
            fprintf('=== GA TEST MODE ===\n');
            fprintf('Date and Time: %s\n', datestr(now));
            fprintf('====================\n\n');
            
            % Override config for quick test
            config.tuning.testTime = 5;
            config.tuning.numberOfTests = 3;
            config.execution.numRuns = 3;
            config.execution.runTime = 10;
            
            runGA_standard(config);
            
        case 'test-opt'
            fprintf('=== GA OPTIMIZED TEST MODE ===\n');
            fprintf('Date and Time: %s\n', datestr(now));
            fprintf('==============================\n\n');
            
            % Override config for quick test
            configOptimized.tuning.testTime = 5;
            configOptimized.tuning.numberOfTests = 3;
            configOptimized.execution.numRuns = 3;
            configOptimized.execution.runTime = 10;
            
            runGA_optimized(configOptimized);
            
        case 'analysis'
            fprintf('=== GA ANALYSIS MODE ===\n');
            fprintf('Date and Time: %s\n', datestr(now));
            fprintf('========================\n\n');
            
            runStandaloneAnalysis(false);
        

        case "analysis-opt"
            fprintf('=== GA OPTIMIZED ANALYSIS MODE ===\n');
            fprintf('Date and Time: %s\n', datestr(now));
            fprintf('==================================\n\n');
            
            runStandaloneAnalysis(true);
            
            
        case 'compare'
            fprintf('=== GA COMPARISON MODE ===\n');
            fprintf('Date and Time: %s\n', datestr(now));
            fprintf('==========================\n\n');
            
            runGAComparison(config, configOptimized);
            
        otherwise
            fprintf('Unknown mode: %s\n', mode);
            showHelp();
    end
end

function showHelp()
    fprintf('\nGenetic Algorithm (GA) for Server Node Selection\n');
    fprintf('================================================\n\n');
    fprintf('Usage: main(mode)\n\n');
    fprintf('Available modes:\n');
    fprintf('  (no args)      - Run standard GA with best/default parameters\n');
    fprintf('  ''tuning''       - Run parameter tuning for standard GA\n');
    fprintf('  ''tuning-opt''   - Run parameter tuning for GAOptimized\n');
    fprintf('  ''run''          - Run standard GA\n');
    fprintf('  ''run-opt''      - Run GAOptimized\n');
    fprintf('  ''analysis''     - Analyze existing results\n');
    fprintf('  ''full''         - Run complete workflow (both algorithms)\n');
    fprintf('  ''test''         - Quick test run with standard GA\n');
    fprintf('  ''test-opt''     - Quick test run with GAOptimized\n');
    fprintf('  ''compare''      - Compare standard vs optimized GA\n');
    fprintf('  ''help''         - Show this help message\n\n');
    fprintf('Examples:\n');
    fprintf('  main()                  %% Run standard GA with best parameters\n');
    fprintf('  main(''tuning'')          %% Find best parameters for standard GA\n');
    fprintf('  main(''tuning-opt'')      %% Find best parameters for GAOptimized\n');
    fprintf('  main(''full'')            %% Complete workflow for both algorithms\n');
    fprintf('  main(''compare'')         %% Compare both algorithms\n\n');
end

function config = loadGAConfig()
    % Default configuration for standard GA
    config = struct();
    
    % Problem parameters
    config.problem.n = 12;          % Number of nodes to select
    config.problem.Cmax = 1000;     % Maximum shortest path constraint
    
    % Default GA parameters (can be overridden by tuning)
    config.params.populationSize = 100;
    config.params.mutationRate = 0.3;
    config.params.eliteCount = 5;
    
    % Tuning parameters
    config.tuning.populationSizes = [20, 50, 100, 150];
    config.tuning.mutationRates = [0.05, 0.1, 0.2, 0.3];
    config.tuning.eliteCounts = [1, 5, 10];
    config.tuning.testTime = 30;
    config.tuning.numberOfTests = 10;
    
    % Execution parameters
    config.execution.numRuns = 10;
    config.execution.runTime = 30;
    
    % Output settings
    config.output.saveResults = true;
    config.output.savePlots = true;
    config.output.verboseLevel = 1;  % 0=quiet, 1=normal, 2=verbose
    
    % Try to load best parameters if they exist
    if exist('results/GA_best_params.mat', 'file')
        load('results/GA_best_params.mat', 'bestParams');
        config.params = bestParams;
        fprintf('Loaded best parameters for standard GA from previous tuning.\n');
    end
end

function config = loadGAOptimizedConfig()
    % Default configuration for GAOptimized
    config = struct();
    
    % Problem parameters (same as standard)
    config.problem.n = 12;          % Number of nodes to select
    config.problem.Cmax = 1000;     % Maximum shortest path constraint
    
    % Default GAOptimized parameters (can be overridden by tuning)
    % May benefit from different parameters due to caching
    config.params.populationSize = 150;  % Larger population may be beneficial with caching
    config.params.mutationRate = 0.2;    % Potentially lower mutation rate
    config.params.eliteCount = 10;       % More elitism with efficient evaluation
    
    % Tuning parameters for GAOptimized
    % May want to test larger populations since evaluation is faster
    config.tuning.populationSizes = [50, 100, 150, 200, 300];
    config.tuning.mutationRates = [0.05, 0.1, 0.15, 0.2, 0.25];
    config.tuning.eliteCounts = [5, 10, 15, 20];
    config.tuning.testTime = 30;
    config.tuning.numberOfTests = 10;
    
    % Execution parameters
    config.execution.numRuns = 10;
    config.execution.runTime = 30;
    
    % Output settings
    config.output.saveResults = true;
    config.output.savePlots = true;
    config.output.verboseLevel = 1;  % 0=quiet, 1=normal, 2=verbose
    config.output.trackCacheMetrics = true;  % Track cache performance
    
    % Try to load best parameters if they exist
    if exist('results/GAOptimized_best_params.mat', 'file')
        load('results/GAOptimized_best_params.mat', 'bestParams');
        config.params = bestParams;
        fprintf('Loaded best parameters for GAOptimized from previous tuning.\n');
    end
end