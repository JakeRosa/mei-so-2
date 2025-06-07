function runGRASP(varargin)
% Main script to run GRASP algorithm with different parameter settings
% and find the best configuration
% 
% Usage:
%   runGRASP()                    - Run full analysis
%   runGRASP('optimized')         - Use optimized GRASP version
%   runGRASP('analysis')          - Run additional analysis functions
%   runGRASP('comparison')        - Compare original vs optimized
%   runGRASP('phase')             - Run phase contribution analysis
%   runGRASP('nodes')             - Run node frequency analysis
%   runGRASP('sensitivity')       - Run parameter sensitivity analysis

    % Parse input arguments
    useOptimized = false;
    runAnalysis = false;
    runComparison = false;
    runPhaseAnalysis = false;
    runNodeAnalysis = false;
    runSensitivityAnalysis = false;
    
    for i = 1:length(varargin)
        switch lower(varargin{i})
            case 'optimized'
                useOptimized = true;
            case 'analysis'
                runAnalysis = true;
            case 'comparison'
                runComparison = true;
            case 'phase'
                runPhaseAnalysis = true;
            case 'nodes'
                runNodeAnalysis = true;
            case 'sensitivity'
                runSensitivityAnalysis = true;
        end
    end

    % Create timestamped log filename
    timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
    logFilename = sprintf('output/GRASP_output_%s.txt', timestamp);
    
    fprintf('Starting GRASP run - output will be saved to: %s\n', logFilename);
    if useOptimized
        fprintf('Using optimized GRASP implementation\n');
    end
    
    % Start logging to file
    diary(logFilename);
    diary on;

    % Setup paths for organized structure
    % Get current directory and set up paths relative to runners/
    currentDir = fileparts(mfilename('fullpath'));
    graspDir = fileparts(currentDir);  % Go up one level to GRASP/
    
    % Add all necessary paths
    addpath(fullfile(graspDir, 'core'));
    addpath(fullfile(graspDir, 'analysis'));
    addpath(fullfile(graspDir, 'exports'));
    addpath(fullfile(graspDir, 'lib'));
    addpath(fullfile(graspDir, 'utilities'));
    
    % Add parent directory for shared functions (loadData, PerfSNS, etc.)
    addpath(fullfile(graspDir, '..'));
    
    fprintf('Paths configured for organized GRASP structure\n');

    % Load network data
    [G, nNodes, nLinks] = loadData();

    % Problem parameters
    n = 12;        % Number of nodes to select
    Cmax = 1000;   % Maximum shortest path constraint

    % Test different parameter values to find best settings
    fprintf('=== PARAMETER TUNING ===\n');

    % Test different r values with multiple runs per parameter
    rValues = [2, 3, 5, 8, 10];
    testTime = 30; % seconds for each test run
    runsPerParameter = 5; % Number of runs per r value

    bestR = 2;
    bestTestAvgSP = inf;
    bestOverallAvgSP = inf;

    % Initialize results storage
    parameterResults = struct();
    
    for i = 1:length(rValues)
        r = rValues(i);
        fprintf('\nTesting r = %d (%d runs)...\n', r, runsPerParameter);
        
        % Store results for this parameter
        runResults = zeros(runsPerParameter, 1);
        validRuns = 0;
        
        for run = 1:runsPerParameter
            fprintf('  Run %d/%d...', run, runsPerParameter);
            
            try
                if useOptimized
                    options = struct('useCaching', true, 'stagnationLimit', 20, ...
                                   'trackNodeFreq', false, 'verbose', false);
                    [~, avgSP, maxSP, ~] = GRASPOptimized(G, n, Cmax, r, testTime, options);
                else
                    [~, avgSP, maxSP, ~] = GRASP(G, n, Cmax, r, testTime);
                end
                
                % Only count valid solutions
                if ~isempty(avgSP) && ~isinf(avgSP) && maxSP <= Cmax
                    validRuns = validRuns + 1;
                    runResults(validRuns) = avgSP;
                    fprintf(' %.4f\n', avgSP);
                else
                    fprintf(' invalid\n');
                end
                
            catch ME
                fprintf(' error: %s\n', ME.message);
            end
        end
        
        % Trim to valid results
        runResults = runResults(1:validRuns);
        
        if validRuns > 0
            % Calculate statistics
            parameterResults(i).r = r;
            parameterResults(i).validRuns = validRuns;
            parameterResults(i).allResults = runResults;
            parameterResults(i).meanAvgSP = mean(runResults);
            parameterResults(i).stdAvgSP = std(runResults);
            parameterResults(i).bestAvgSP = min(runResults);
            parameterResults(i).worstAvgSP = max(runResults);
            parameterResults(i).successRate = 100 * validRuns / runsPerParameter;
            
            fprintf('  r=%d: Mean=%.4f±%.4f, Best=%.4f, Success=%d/%d (%.1f%%)\n', ...
                    r, parameterResults(i).meanAvgSP, parameterResults(i).stdAvgSP, ...
                    parameterResults(i).bestAvgSP, validRuns, runsPerParameter, ...
                    parameterResults(i).successRate);
            
            % Track overall best parameter (based on mean performance)
            if parameterResults(i).meanAvgSP < bestTestAvgSP
                bestTestAvgSP = parameterResults(i).meanAvgSP;
                bestR = r;
            end
            
            % Track best individual result
            if parameterResults(i).bestAvgSP < bestOverallAvgSP
                bestOverallAvgSP = parameterResults(i).bestAvgSP;
            end
        else
            fprintf('  r=%d: No valid solutions found\n', r);
            parameterResults(i).r = r;
            parameterResults(i).validRuns = 0;
            parameterResults(i).meanAvgSP = inf;
            parameterResults(i).successRate = 0;
        end
    end

    % Create comprehensive parameter analysis plot
    createParameterAnalysisPlot(parameterResults, timestamp);

    fprintf('\n=== PARAMETER TUNING RESULTS ===\n');
    fprintf('Best parameter: r = %d (mean avgSP = %.4f)\n', bestR, bestTestAvgSP);
    fprintf('Best individual result: %.4f\n', bestOverallAvgSP);
    
    % Print summary table
    fprintf('\nParameter Summary:\n');
    fprintf('%-4s %-8s %-8s %-8s %-8s %-10s\n', 'r', 'Mean', 'Std', 'Best', 'Worst', 'Success%');
    fprintf('%-4s %-8s %-8s %-8s %-8s %-10s\n', repmat('-', 1, 4), repmat('-', 1, 8), ...
            repmat('-', 1, 8), repmat('-', 1, 8), repmat('-', 1, 8), repmat('-', 1, 10));
    
    for i = 1:length(parameterResults)
        if parameterResults(i).validRuns > 0
            fprintf('%-4d %-8.4f %-8.4f %-8.4f %-8.4f %-10.1f\n', ...
                    parameterResults(i).r, parameterResults(i).meanAvgSP, ...
                    parameterResults(i).stdAvgSP, parameterResults(i).bestAvgSP, ...
                    parameterResults(i).worstAvgSP, parameterResults(i).successRate);
        else
            fprintf('%-4d %-8s %-8s %-8s %-8s %-10.1f\n', ...
                    parameterResults(i).r, 'N/A', 'N/A', 'N/A', 'N/A', 0.0);
        end
    end

    % Now run 10 times with best parameters and 30 seconds each
    fprintf('\n=== RUNNING 10 TIMES WITH BEST SETTINGS ===\n');

    numRuns = 10;
    runTime = 30; % seconds per run

    allResults = [];

    for run = 1:numRuns
        fprintf('\n--- RUN %d/%d ---\n', run, numRuns);

        if useOptimized
            options = struct('useCaching', true, 'stagnationLimit', 50, ...
                           'trackNodeFreq', true, 'verbose', true);
            [solution, avgSP, maxSP, results] = GRASPOptimized(G, n, Cmax, bestR, runTime, options);
        else
            [solution, avgSP, maxSP, results] = GRASP(G, n, Cmax, bestR, runTime);
        end

        allResults(run).solution = solution;
        allResults(run).avgSP = avgSP;
        allResults(run).maxSP = maxSP;
        allResults(run).results = results;

        fprintf('Run %d completed: avgSP = %.4f, maxSP = %.4f\n', ...
                run, avgSP, maxSP);
    end

    % Analyze results
    fprintf('\n=== FINAL RESULTS ANALYSIS ===\n');

    avgSPs = [allResults.avgSP];
    maxSPs = [allResults.maxSP];

    % Remove invalid results (inf values)
    validIdx = ~isinf(avgSPs);
    validAvgSPs = avgSPs(validIdx);
    validMaxSPs = maxSPs(validIdx);

    if ~isempty(validAvgSPs)
        fprintf('Valid runs: %d/%d\n', sum(validIdx), numRuns);
        fprintf('Minimum avgSP: %.4f\n', min(validAvgSPs));
        fprintf('Average avgSP: %.4f\n', mean(validAvgSPs));
        fprintf('Maximum avgSP: %.4f\n', max(validAvgSPs));
        fprintf('Standard deviation: %.4f\n', std(validAvgSPs));

        fprintf('\nMaximum shortest path statistics:\n');
        fprintf('Minimum maxSP: %.4f\n', min(validMaxSPs));
        fprintf('Average maxSP: %.4f\n', mean(validMaxSPs));
        fprintf('Maximum maxSP: %.4f\n', max(validMaxSPs));

        % Find best run
        [bestAvgSP, bestIdx] = min(validAvgSPs);
        validIndices = find(validIdx);
        bestRunIdx = validIndices(bestIdx);

        fprintf('\nBest run (#%d):\n', bestRunIdx);
        fprintf('Solution: [%s]\n', num2str(allResults(bestRunIdx).solution));
        fprintf('Average shortest path: %.4f\n', allResults(bestRunIdx).avgSP);
        fprintf('Max shortest path: %.4f\n', allResults(bestRunIdx).maxSP);

        % Create special plot for best solution
        if ~isempty(allResults(bestRunIdx).solution)
            plotNetworkSolution(G, allResults(bestRunIdx).solution, ...
                              allResults(bestRunIdx).avgSP, ...
                              allResults(bestRunIdx).maxSP, ...
                              'GRASP_BEST', bestRunIdx, 'plots/');
        end

        % Save results
        save('results/GRASP_results.mat', 'allResults', 'bestR', 'G', 'n', 'Cmax');
        fprintf('\nResults saved to GRASP_results.mat\n');

        exportGraspResults(allResults, bestR, timestamp);
    else
        fprintf('No valid solutions found!\n');
    end

    % Stop logging
    diary off;
    
    fprintf('\nOutput successfully saved to: %s\n', logFilename);
    fprintf('Plots saved to plots/ directory\n');

    % Create summary visualization if we have valid results
    if ~isempty(validAvgSPs)
        fprintf('\n=== CREATING RESULTS SUMMARY ===\n');
        try
            % Create a simple results summary plot
            figure('Position', [100, 100, 800, 600]);
            
            subplot(2,2,1);
            histogram(validAvgSPs, 'Normalization', 'probability');
            title('Solution Quality Distribution');
            xlabel('Average Shortest Path');
            ylabel('Probability');
            grid on;
            
            subplot(2,2,2);
            plot(1:length(validAvgSPs), validAvgSPs, 'bo-');
            title('Solution Quality by Run');
            xlabel('Run Number');
            ylabel('Average Shortest Path');
            grid on;
            
            subplot(2,2,3);
            scatter(validAvgSPs, validMaxSPs, 'filled');
            title('AvgSP vs MaxSP');
            xlabel('Average Shortest Path');
            ylabel('Max Shortest Path');
            grid on;
            
            subplot(2,2,4);
            bar([min(validAvgSPs), mean(validAvgSPs), max(validAvgSPs)]);
            set(gca, 'XTickLabel', {'Best', 'Mean', 'Worst'});
            title('Solution Quality Summary');
            ylabel('Average Shortest Path');
            grid on;
            
            sgtitle(sprintf('GRASP Results Summary (r=%d, %d valid runs)', bestR, length(validAvgSPs)));
            
            % Save the summary plot
            summaryFilename = sprintf('plots/GRASP_summary_%s.png', timestamp);
            saveas(gcf, summaryFilename);
            fprintf('Results summary plot saved as: %s\n', summaryFilename);
            
        catch ME
            fprintf('Warning: Could not create summary plot: %s\n', ME.message);
        end
    end

    % Run additional analysis functions if requested
    if runAnalysis || runPhaseAnalysis || runNodeAnalysis || runSensitivityAnalysis || runComparison
        fprintf('\n=== ADDITIONAL ANALYSIS ===\n');
        
        if runPhaseAnalysis || runAnalysis
            fprintf('\n--- Phase Contribution Analysis ---\n');
            try
                phaseResults = analyzePhaseContribution(G, n, Cmax, bestR, 20);
                fprintf('Phase analysis completed successfully\n');
            catch ME
                fprintf('Error in phase analysis: %s\n', ME.message);
            end
        end
        
        if runNodeAnalysis || runAnalysis
            fprintf('\n--- Node Frequency Analysis ---\n');
            try
                nodeAnalysis = analyzeNodeFrequency(G, n, Cmax, bestR, 15, 10);
                fprintf('Node frequency analysis completed successfully\n');
            catch ME
                fprintf('Error in node analysis: %s\n', ME.message);
            end
        end
        
        if runComparison || runAnalysis
            fprintf('\n--- Implementation Comparison ---\n');
            try
                comparisonResults = compareOptimizations(G, n, Cmax, bestR, runTime, 10);
                fprintf('Implementation comparison completed successfully\n');
            catch ME
                fprintf('Error in comparison: %s\n', ME.message);
            end
        end
        
        if runSensitivityAnalysis || runAnalysis
            fprintf('\n--- Parameter Sensitivity Analysis ---\n');
            fprintf('Warning: This analysis may take several minutes...\n');
            try
                sensitivityResults = plotParameterSensitivityHeatMap(G, n, Cmax);
                fprintf('Parameter sensitivity analysis completed successfully\n');
            catch ME
                fprintf('Error in sensitivity analysis: %s\n', ME.message);
            end
        end
    end
    
    fprintf('\n=== ANALYSIS COMPLETE ===\n');
    fprintf('All plots and results saved to respective directories\n');
end

% Standalone analysis functions that can be called independently
function runPhaseAnalysis(G, n, Cmax, r, numRuns)
    if nargin < 5, numRuns = 30; end
    fprintf('Running standalone phase contribution analysis...\n');
    phaseResults = analyzePhaseContribution(G, n, Cmax, r, numRuns);
end

function runNodeFrequencyAnalysis(G, n, Cmax, r, numRuns, topPercentile)
    if nargin < 5, numRuns = 20; end
    if nargin < 6, topPercentile = 10; end
    fprintf('Running standalone node frequency analysis...\n');
    nodeAnalysis = analyzeNodeFrequency(G, n, Cmax, r, numRuns, topPercentile);
end

function runParameterSensitivity(G, n, Cmax)
    fprintf('Running standalone parameter sensitivity analysis...\n');
    sensitivityResults = plotParameterSensitivityHeatMap(G, n, Cmax);
end

function runImplementationComparison(G, n, Cmax, r, maxTime, numRuns)
    if nargin < 6, numRuns = 10; end
    fprintf('Running standalone implementation comparison...\n');
    comparisonResults = compareOptimizations(G, n, Cmax, r, maxTime, numRuns);
end

