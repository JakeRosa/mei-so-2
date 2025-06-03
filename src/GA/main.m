function main(varargin)
% Main entry point for GA with support for different execution modes
% Usage:
%   main()                     - Run full GA with best parameters
%   main('tuning')            - Run parameter tuning only
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
    
    % Execute based on mode
    switch mode
        case 'help'
            showHelp();
            
        case 'tuning'
            fprintf('=== GA PARAMETER TUNING MODE ===\n');
            fprintf('Date and Time: %s\n', datestr(now));
            fprintf('================================\n\n');
            runParameterTuning(config);
            
        case 'run'
            fprintf('=== GA EXECUTION MODE ===\n');
            fprintf('Date and Time: %s\n', datestr(now));
            fprintf('=========================\n\n');
            runGA_standard(config);
            
        case 'full'
            fprintf('=== GA FULL EXECUTION MODE ===\n');
            fprintf('Date and Time: %s\n', datestr(now));
            fprintf('==============================\n\n');
            
            % First run tuning
            bestParams = runParameterTuning(config);
            
            % Update config with best parameters
            config.params = bestParams;
            
            % Run standard GA with best parameters
            runGA_standard(config);
            
            % Run optimized GA with best parameters  
            runGA_optimized(config);
            
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
            
        case 'analysis'
            fprintf('=== GA ANALYSIS MODE ===\n');
            fprintf('Date and Time: %s\n', datestr(now));
            fprintf('========================\n\n');
            
            if exist('results/GA_results.mat', 'file')
                runStandaloneAnalysis();
            else
                fprintf('Error: No results found. Please run GA first.\n');
            end
            
        case 'compare'
            fprintf('=== GA COMPARISON MODE ===\n');
            fprintf('Date and Time: %s\n', datestr(now));
            fprintf('==========================\n\n');
            
            runGAComparison(config);
            
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
    fprintf('  (no args)   - Run GA with best/default parameters\n');
    fprintf('  ''tuning''    - Run parameter tuning only\n');
    fprintf('  ''analysis''  - Analyze existing results\n');
    fprintf('  ''full''      - Run tuning followed by full execution\n');
    fprintf('  ''test''      - Quick test run with reduced parameters\n');
    fprintf('  ''compare''   - Compare standard vs optimized GA\n');
    fprintf('  ''help''      - Show this help message\n\n');
    fprintf('Examples:\n');
    fprintf('  main()                  %% Run with best parameters\n');
    fprintf('  main(''tuning'')          %% Find best parameters\n');
    fprintf('  main(''full'')            %% Complete workflow\n');
    fprintf('  main(''analysis'')        %% Analyze saved results\n\n');
end

function config = loadGAConfig()
    % Default configuration
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
    config.tuning.mutationRates = [0.05, 0.1, 0.2];
    config.tuning.eliteCounts = [1, 5, 10];
    config.tuning.testTime = 30;
    config.tuning.numberOfTests = 5;
    
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
        fprintf('Loaded best parameters from previous tuning.\n');
    end
end