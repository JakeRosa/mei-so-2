function main(varargin)
% GRASP Main Entry Point - Organized Implementation
% 
% This is the main entry point for the organized GRASP implementation.
% It handles path management and provides a unified interface to all functions.
%
% Usage:
%   main()                          % Interactive menu
%   main('optimized', 'analysis')   % Optimized GRASP with all analysis
%   main('existing')                % Analyze existing results only
%   main('fresh')                   % Run fresh GRASP + analysis
%   main('comparison')              % Compare implementations
%   main('phase')                   % Phase contribution analysis
%   main('nodes')                   % Node frequency analysis
%   main('sensitivity')             % Parameter sensitivity analysis
%   main('help')                    % Show help and available options

    fprintf('=== GRASP Implementation - Organized Version ===\n\n');
    
    % Setup paths
    setupPaths();
    
    % Parse arguments
    if nargin == 0 || (nargin == 1 && strcmpi(varargin{1}, 'help'))
        showHelp();
        return;
    end
    
    % Handle specific modes
    if nargin >= 1
        switch lower(varargin{1})
            case 'existing'
                runExistingAnalysis();
                return;
            case 'fresh'
                runFreshAnalysis();
                return;
            case 'menu'
                showInteractiveMenu();
                return;
            case 'comparison'
                runComparisonOnly();
                return;
            case 'phase'
                runPhaseAnalysisOnly();
                return;
            case 'nodes'
                runNodeAnalysisOnly();
                return;
            case 'sensitivity'
                runSensitivityOnly();
                return;
        end
    end
    
    % Default: run full GRASP with options
    fprintf('Running GRASP with options: %s\n', strjoin(varargin, ', '));
    runGRASP(varargin{:});
end

function setupPaths()
    % Add all necessary paths for organized structure
    currentDir = pwd;
    
    % Add core algorithm paths
    addpath(fullfile(currentDir, 'core'));
    addpath(fullfile(currentDir, 'analysis'));
    addpath(fullfile(currentDir, 'runners'));
    addpath(fullfile(currentDir, 'utilities'));
    addpath(fullfile(currentDir, 'exports'));
    addpath(fullfile(currentDir, 'lib'));
    
    % Add parent directory for shared functions
    addpath('..');
    
    fprintf('✓ Paths configured for organized GRASP structure\n');
end

function showHelp()
    fprintf('GRASP Implementation - Available Commands:\n\n');
    
    fprintf('📊 QUICK ANALYSIS:\n');
    fprintf('  main(''existing'')     - Analyze existing results (fast)\n');
    fprintf('  main(''fresh'')        - Run fresh GRASP + analysis\n\n');
    
    fprintf('🔬 SPECIFIC ANALYSIS:\n');
    fprintf('  main(''phase'')        - Phase contribution analysis\n');
    fprintf('  main(''nodes'')        - Node frequency analysis\n');
    fprintf('  main(''comparison'')   - Implementation comparison\n');
    fprintf('  main(''sensitivity'')  - Parameter sensitivity (slow)\n\n');
    
    fprintf('🚀 FULL RUNS:\n');
    fprintf('  main(''optimized'', ''analysis'')  - Optimized GRASP + all analysis\n');
    fprintf('  main(''analysis'')                 - Original GRASP + all analysis\n');
    fprintf('  main(''optimized'')                - Optimized GRASP only\n\n');
    
    fprintf('💡 INTERACTIVE:\n');
    fprintf('  main(''menu'')         - Interactive menu\n');
    fprintf('  main(''help'')         - Show this help\n\n');
    
    fprintf('📂 FILE ORGANIZATION:\n');
    fprintf('  core/       - GRASP algorithm implementations\n');
    fprintf('  analysis/   - Analysis and visualization functions\n');
    fprintf('  runners/    - Main execution scripts\n');
    fprintf('  results/    - Saved results and data\n');
    fprintf('  plots/      - Generated visualizations\n');
    fprintf('  output/     - Execution logs\n\n');
end

function showInteractiveMenu()
    fprintf('=== Interactive GRASP Menu ===\n\n');
    
    % Check for existing results
    hasResults = exist('results/GRASP_results.mat', 'file') == 2;
    if hasResults
        fprintf('✓ Found existing GRASP results\n');
    else
        fprintf('⚠ No existing results found\n');
    end
    
    fprintf('\nSelect an option:\n');
    fprintf('1. Run optimized GRASP with full analysis\n');
    fprintf('2. Run original GRASP with analysis\n');
    if hasResults
        fprintf('3. Analyze existing results only (fast)\n');
    end
    fprintf('4. Compare original vs optimized implementations\n');
    fprintf('5. Phase contribution analysis\n');
    fprintf('6. Node frequency analysis\n');
    fprintf('7. Parameter sensitivity analysis (slow)\n');
    fprintf('8. Show help\n');
    fprintf('9. Exit\n\n');
    
    choice = input('Enter choice (1-9): ');
    
    switch choice
        case 1
            fprintf('\nRunning optimized GRASP with full analysis...\n');
            runGRASP('optimized', 'analysis');
        case 2
            fprintf('\nRunning original GRASP with analysis...\n');
            runGRASP('analysis');
        case 3
            if hasResults
                fprintf('\nAnalyzing existing results...\n');
                analyzeExistingResults();
            else
                fprintf('No existing results to analyze.\n');
            end
        case 4
            fprintf('\nComparing implementations...\n');
            runComparisonOnly();
        case 5
            fprintf('\nRunning phase contribution analysis...\n');
            runPhaseAnalysisOnly();
        case 6
            fprintf('\nRunning node frequency analysis...\n');
            runNodeAnalysisOnly();
        case 7
            fprintf('\nRunning parameter sensitivity analysis...\n');
            runSensitivityOnly();
        case 8
            showHelp();
        case 9
            fprintf('Exiting...\n');
        otherwise
            fprintf('Invalid choice. Exiting...\n');
    end
end

function runExistingAnalysis()
    fprintf('=== Quick Analysis of Existing Results ===\n');
    
    if exist('results/GRASP_results.mat', 'file') ~= 2
        fprintf('❌ No existing results found.\n');
        fprintf('Run main(''fresh'') to generate results first.\n');
        return;
    end
    
    fprintf('Analyzing existing GRASP results...\n');
    analyzeExistingResults();
    fprintf('✓ Analysis complete! Check plots/ directory for visualizations.\n');
end

function runFreshAnalysis()
    fprintf('=== Fresh GRASP Run with Analysis ===\n');
    fprintf('This will run GRASP and perform comprehensive analysis.\n');
    
    useOptimized = input('Use optimized GRASP? (y/n): ', 's');
    if strcmpi(useOptimized, 'y')
        runGRASP('optimized', 'analysis');
    else
        runGRASP('analysis');
    end
end

function runComparisonOnly()
    fprintf('=== Implementation Comparison ===\n');
    
    % Load data for parameters
    [G, n, Cmax] = loadData();
    r = 5;
    maxTime = 60;
    numRuns = 8;
    
    fprintf('Comparing original vs optimized GRASP...\n');
    fprintf('Parameters: n=%d, Cmax=%d, r=%d, maxTime=%ds, numRuns=%d\n', ...
            n, Cmax, r, maxTime, numRuns);
    
    compareOptimizations(G, n, Cmax, r, maxTime, numRuns);
    fprintf('✓ Comparison complete!\n');
end

function runPhaseAnalysisOnly()
    fprintf('=== Phase Contribution Analysis ===\n');
    
    [G, n, Cmax] = loadData();
    r = 5;
    numRuns = 25;
    
    fprintf('Analyzing construction vs local search phases...\n');
    fprintf('Parameters: n=%d, Cmax=%d, r=%d, numRuns=%d\n', n, Cmax, r, numRuns);
    
    analyzePhaseContribution(G, n, Cmax, r, numRuns);
    fprintf('✓ Phase analysis complete!\n');
end

function runNodeAnalysisOnly()
    fprintf('=== Node Frequency Analysis ===\n');
    
    % Check if user wants to use existing results
    if exist('results/GRASP_results.mat', 'file') == 2
        useExisting = input('Use existing results? (y/n): ', 's');
        if strcmpi(useExisting, 'y')
            analyzeExistingResults();
            return;
        end
    end
    
    % Run fresh analysis
    [G, n, Cmax] = loadData();
    r = 3;
    numRuns = 20;
    topPercentile = 10;
    
    fprintf('Running fresh node frequency analysis...\n');
    fprintf('Parameters: n=%d, Cmax=%d, r=%d, numRuns=%d, topPercentile=%d\n', ...
            n, Cmax, r, numRuns, topPercentile);
    
    analyzeNodeFrequency(G, n, Cmax, r, numRuns, topPercentile);
    fprintf('✓ Node analysis complete!\n');
end

function runSensitivityOnly()
    fprintf('=== Parameter Sensitivity Analysis ===\n');
    fprintf('⚠ Warning: This analysis may take 10-20 minutes to complete.\n');
    
    proceed = input('Continue? (y/n): ', 's');
    if ~strcmpi(proceed, 'y')
        fprintf('Analysis cancelled.\n');
        return;
    end
    
    [G, n, Cmax] = loadData();
    
    fprintf('Running parameter sensitivity analysis...\n');
    fprintf('Testing multiple r values and time limits...\n');
    
    plotParameterSensitivityHeatMap(G, n, Cmax);
    fprintf('✓ Sensitivity analysis complete!\n');
end