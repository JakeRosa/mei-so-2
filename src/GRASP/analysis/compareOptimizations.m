function comparisonResults = compareOptimizations(G, n, Cmax, r, maxTime, numRuns)
% Compare original vs optimized GRASP implementations
% Inputs:
%   G - graph representing the network
%   n - number of nodes to select
%   Cmax - maximum allowed shortest path length between controllers
%   r - parameter for greedy randomized selection
%   maxTime - maximum running time in seconds
%   numRuns - number of runs for comparison (default: 10)
% Output:
%   comparisonResults - struct with detailed comparison

    if nargin < 6
        numRuns = 10;
    end

    fprintf('Comparing Original vs Optimized GRASP implementations...\n');
    fprintf('Parameters: n=%d, Cmax=%d, r=%d, maxTime=%ds, numRuns=%d\n', ...
            n, Cmax, r, maxTime, numRuns);
    
    % Initialize result storage
    originalResults = struct();
    optimizedResults = struct();
    
    originalTimes = zeros(numRuns, 1);
    originalQualities = zeros(numRuns, 1);
    originalIterations = zeros(numRuns, 1);
    originalValid = false(numRuns, 1);
    
    optimizedTimes = zeros(numRuns, 1);
    optimizedQualities = zeros(numRuns, 1);
    optimizedIterations = zeros(numRuns, 1);
    optimizedValid = false(numRuns, 1);
    optimizedCacheHitRates = zeros(numRuns, 1);
    optimizedTerminationReasons = cell(numRuns, 1);
    
    fprintf('\n=== Running Original GRASP ===\n');
    
    % Test original GRASP
    for run = 1:numRuns
        fprintf('Original run %d/%d... ', run, numRuns);
        
        try
            tic;
            [solution, avgSP, maxSP, results] = GRASP(G, n, Cmax, r, maxTime);
            runTime = toc;
            
            if ~isempty(solution) && maxSP <= Cmax
                originalValid(run) = true;
                originalTimes(run) = runTime;
                originalQualities(run) = avgSP;
                originalIterations(run) = length(results.avgSPs);
                fprintf('completed (%.2fs, %.4f, %d iters)\n', runTime, avgSP, originalIterations(run));
            else
                fprintf('failed (no valid solution)\n');
            end
        catch ME
            fprintf('error: %s\n', ME.message);
        end
    end
    
    fprintf('\n=== Running Optimized GRASP ===\n');
    
    % Test optimized GRASP
    options = struct('useCaching', true, 'stagnationLimit', 50, ...
                    'trackNodeFreq', false, 'verbose', false);
    
    for run = 1:numRuns
        fprintf('Optimized run %d/%d... ', run, numRuns);
        
        try
            tic;
            [solution, avgSP, maxSP, results] = GRASPOptimized(G, n, Cmax, r, maxTime, options);
            runTime = toc;
            
            if ~isempty(solution) && maxSP <= Cmax
                optimizedValid(run) = true;
                optimizedTimes(run) = runTime;
                optimizedQualities(run) = avgSP;
                optimizedIterations(run) = results.totalIterations;
                if isfield(results, 'cacheHitRate')
                    optimizedCacheHitRates(run) = results.cacheHitRate;
                end
                if isfield(results, 'terminationReason') && ~isempty(results.terminationReason)
                    optimizedTerminationReasons{run} = results.terminationReason;
                else
                    optimizedTerminationReasons{run} = 'unknown';
                end
                fprintf('completed (%.2fs, %.4f, %d iters, %.1f%% cache)\n', ...
                        runTime, avgSP, optimizedIterations(run), optimizedCacheHitRates(run));
            else
                optimizedTerminationReasons{run} = 'failed';
                fprintf('failed (no valid solution)\n');
            end
        catch ME
            optimizedTerminationReasons{run} = 'error';
            fprintf('error: %s\n', ME.message);
        end
    end
    
    % Calculate statistics
    originalValidRuns = sum(originalValid);
    optimizedValidRuns = sum(optimizedValid);
    
    if originalValidRuns == 0 || optimizedValidRuns == 0
        error('Insufficient valid runs for comparison');
    end
    
    % Extract valid results
    origTimes = originalTimes(originalValid);
    origQualities = originalQualities(originalValid);
    origIterations = originalIterations(originalValid);
    
    optTimes = optimizedTimes(optimizedValid);
    optQualities = optimizedQualities(optimizedValid);
    optIterations = optimizedIterations(optimizedValid);
    optCacheRates = optimizedCacheHitRates(optimizedValid);
    
    % Calculate performance metrics
    comparisonResults = struct();
    
    % Original GRASP statistics
    comparisonResults.original.validRuns = originalValidRuns;
    comparisonResults.original.meanTime = mean(origTimes);
    comparisonResults.original.stdTime = std(origTimes);
    comparisonResults.original.meanQuality = mean(origQualities);
    comparisonResults.original.stdQuality = std(origQualities);
    comparisonResults.original.bestQuality = min(origQualities);
    comparisonResults.original.meanIterations = mean(origIterations);
    comparisonResults.original.successRate = 100 * originalValidRuns / numRuns;
    
    % Optimized GRASP statistics
    comparisonResults.optimized.validRuns = optimizedValidRuns;
    comparisonResults.optimized.meanTime = mean(optTimes);
    comparisonResults.optimized.stdTime = std(optTimes);
    comparisonResults.optimized.meanQuality = mean(optQualities);
    comparisonResults.optimized.stdQuality = std(optQualities);
    comparisonResults.optimized.bestQuality = min(optQualities);
    comparisonResults.optimized.meanIterations = mean(optIterations);
    comparisonResults.optimized.meanCacheHitRate = mean(optCacheRates);
    comparisonResults.optimized.successRate = 100 * optimizedValidRuns / numRuns;
    
    % Calculate improvements
    comparisonResults.improvements.timeSpeedup = comparisonResults.original.meanTime / comparisonResults.optimized.meanTime;
    comparisonResults.improvements.qualityImprovement = comparisonResults.original.meanQuality - comparisonResults.optimized.meanQuality;
    comparisonResults.improvements.qualityImprovementPercent = 100 * comparisonResults.improvements.qualityImprovement / comparisonResults.original.meanQuality;
    comparisonResults.improvements.iterationsRatio = comparisonResults.optimized.meanIterations / comparisonResults.original.meanIterations;
    comparisonResults.improvements.bestQualityImprovement = comparisonResults.original.bestQuality - comparisonResults.optimized.bestQuality;
    
    % Statistical significance testing (if possible)
    if length(origQualities) > 1 && length(optQualities) > 1
        [~, comparisonResults.statistics.qualityPValue] = ttest2(origQualities, optQualities);
        [~, comparisonResults.statistics.timePValue] = ttest2(origTimes, optTimes);
    end
    
    % Store raw data
    comparisonResults.rawData.originalTimes = origTimes;
    comparisonResults.rawData.originalQualities = origQualities;
    comparisonResults.rawData.originalIterations = origIterations;
    comparisonResults.rawData.optimizedTimes = optTimes;
    comparisonResults.rawData.optimizedQualities = optQualities;
    comparisonResults.rawData.optimizedIterations = optIterations;
    comparisonResults.rawData.optimizedCacheRates = optCacheRates;
    
    % Print detailed comparison
    fprintf('\n=== GRASP Implementation Comparison Results ===\n');
    
    fprintf('\nOriginal GRASP:\n');
    fprintf('  Valid runs: %d/%d (%.1f%% success rate)\n', ...
            originalValidRuns, numRuns, comparisonResults.original.successRate);
    fprintf('  Mean time: %.3f ± %.3f seconds\n', ...
            comparisonResults.original.meanTime, comparisonResults.original.stdTime);
    fprintf('  Mean quality: %.6f ± %.6f\n', ...
            comparisonResults.original.meanQuality, comparisonResults.original.stdQuality);
    fprintf('  Best quality: %.6f\n', comparisonResults.original.bestQuality);
    fprintf('  Mean iterations: %.1f\n', comparisonResults.original.meanIterations);
    
    fprintf('\nOptimized GRASP:\n');
    fprintf('  Valid runs: %d/%d (%.1f%% success rate)\n', ...
            optimizedValidRuns, numRuns, comparisonResults.optimized.successRate);
    fprintf('  Mean time: %.3f ± %.3f seconds\n', ...
            comparisonResults.optimized.meanTime, comparisonResults.optimized.stdTime);
    fprintf('  Mean quality: %.6f ± %.6f\n', ...
            comparisonResults.optimized.meanQuality, comparisonResults.optimized.stdQuality);
    fprintf('  Best quality: %.6f\n', comparisonResults.optimized.bestQuality);
    fprintf('  Mean iterations: %.1f\n', comparisonResults.optimized.meanIterations);
    fprintf('  Mean cache hit rate: %.1f%%\n', comparisonResults.optimized.meanCacheHitRate);
    
    fprintf('\nPerformance Improvements:\n');
    fprintf('  Time speedup: %.2fx (%.1f%% faster)\n', ...
            comparisonResults.improvements.timeSpeedup, ...
            100 * (1 - 1/comparisonResults.improvements.timeSpeedup));
    fprintf('  Quality improvement: %.6f (%.2f%% better)\n', ...
            comparisonResults.improvements.qualityImprovement, ...
            comparisonResults.improvements.qualityImprovementPercent);
    fprintf('  Best quality improvement: %.6f\n', ...
            comparisonResults.improvements.bestQualityImprovement);
    fprintf('  Iterations ratio: %.2f\n', comparisonResults.improvements.iterationsRatio);
    
    if isfield(comparisonResults, 'statistics')
        fprintf('\nStatistical Significance:\n');
        fprintf('  Quality difference p-value: %.4f\n', comparisonResults.statistics.qualityPValue);
        fprintf('  Time difference p-value: %.4f\n', comparisonResults.statistics.timePValue);
    end
    
    % Termination reason analysis
    terminationCounts = containers.Map();
    if exist('optimizedTerminationReasons', 'var') && ~isempty(optimizedTerminationReasons)
        validReasons = optimizedTerminationReasons(optimizedValid);
        for i = 1:length(validReasons)
            if ~isempty(validReasons{i}) && ischar(validReasons{i})
                reason = validReasons{i};
                if isKey(terminationCounts, reason)
                    terminationCounts(reason) = terminationCounts(reason) + 1;
                else
                    terminationCounts(reason) = 1;
                end
            end
        end
    end
    
    if terminationCounts.Count > 0
        fprintf('\nOptimized GRASP Termination Reasons:\n');
        reasons = keys(terminationCounts);
        for i = 1:length(reasons)
            fprintf('  %s: %d runs (%.1f%%)\n', reasons{i}, ...
                    terminationCounts(reasons{i}), ...
                    100 * terminationCounts(reasons{i}) / optimizedValidRuns);
        end
    end
    
    % Add path for utility functions
    addpath('utilities');
    
    % Generate timestamp for consistent naming
    timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
    
    % Create individual comparison plots (larger and more readable)
    
    % 1. Execution Time Comparison
    figure('Position', [50, 50, 2200, 1600]);
    data = [origTimes; optTimes];
    groups = [ones(length(origTimes), 1); 2*ones(length(optTimes), 1)];
    boxplot(data, groups, 'Labels', {'Original GRASP', 'Optimized GRASP'});
    title(sprintf('Execution Time Comparison (n=%d, Cmax=%d, r=%d)', n, Cmax, r), 'FontSize', 16, 'FontWeight', 'bold');
    ylabel('Time (seconds)', 'FontSize', 14);
    set(gca, 'FontSize', 12);
    grid on; grid minor;
    
    % Add improvement annotation
    if comparisonResults.improvements.timeSpeedup > 1
        text(0.5, 0.95, sprintf('%.1fx faster', comparisonResults.improvements.timeSpeedup), ...
             'Units', 'normalized', 'HorizontalAlignment', 'center', ...
             'FontSize', 14, 'FontWeight', 'bold', 'Color', 'green', ...
             'BackgroundColor', 'white', 'EdgeColor', 'black');
    end
    saveAnalysisPlot(gcf, 'comparisons', 'execution_time_comparison', timestamp);
    
    % 2. Solution Quality Comparison
    figure('Position', [100, 100, 2200, 1600]);
    data = [origQualities; optQualities];
    groups = [ones(length(origQualities), 1); 2*ones(length(optQualities), 1)];
    boxplot(data, groups, 'Labels', {'Original GRASP', 'Optimized GRASP'});
    title(sprintf('Solution Quality Comparison (n=%d, Cmax=%d, r=%d)', n, Cmax, r), 'FontSize', 16, 'FontWeight', 'bold');
    ylabel('Average Shortest Path', 'FontSize', 14);
    set(gca, 'FontSize', 12);
    grid on; grid minor;
    
    % Add improvement annotation
    if comparisonResults.improvements.qualityImprovementPercent > 0
        text(0.5, 0.95, sprintf('%.2f%% better quality', comparisonResults.improvements.qualityImprovementPercent), ...
             'Units', 'normalized', 'HorizontalAlignment', 'center', ...
             'FontSize', 14, 'FontWeight', 'bold', 'Color', 'green', ...
             'BackgroundColor', 'white', 'EdgeColor', 'black');
    elseif comparisonResults.improvements.qualityImprovementPercent < -1
        text(0.5, 0.95, sprintf('%.2f%% worse quality', abs(comparisonResults.improvements.qualityImprovementPercent)), ...
             'Units', 'normalized', 'HorizontalAlignment', 'center', ...
             'FontSize', 14, 'FontWeight', 'bold', 'Color', 'red', ...
             'BackgroundColor', 'white', 'EdgeColor', 'black');
    end
    saveAnalysisPlot(gcf, 'comparisons', 'solution_quality_comparison', timestamp);
    
    % 3. Iterations Comparison
    figure('Position', [150, 150, 2200, 1600]);
    data = [origIterations; optIterations];
    groups = [ones(length(origIterations), 1); 2*ones(length(optIterations), 1)];
    boxplot(data, groups, 'Labels', {'Original GRASP', 'Optimized GRASP'});
    title(sprintf('Iterations Comparison (n=%d, Cmax=%d, r=%d)', n, Cmax, r), 'FontSize', 16, 'FontWeight', 'bold');
    ylabel('Number of Iterations', 'FontSize', 14);
    set(gca, 'FontSize', 12);
    grid on; grid minor;
    
    % Add ratio annotation
    text(0.5, 0.95, sprintf('Ratio: %.2f', comparisonResults.improvements.iterationsRatio), ...
         'Units', 'normalized', 'HorizontalAlignment', 'center', ...
         'FontSize', 14, 'FontWeight', 'bold', 'Color', 'blue', ...
         'BackgroundColor', 'white', 'EdgeColor', 'black');
    saveAnalysisPlot(gcf, 'comparisons', 'iterations_comparison', timestamp);
    
    % 4. Time vs Quality Trade-off Scatter
    figure('Position', [200, 200, 2200, 1600]);
    scatter(origTimes, origQualities, 150, 'bo', 'filled', 'DisplayName', 'Original GRASP', 'MarkerEdgeColor', 'black');
    hold on;
    scatter(optTimes, optQualities, 150, 'ro', 'filled', 'DisplayName', 'Optimized GRASP', 'MarkerEdgeColor', 'black');
    xlabel('Time (seconds)', 'FontSize', 14);
    ylabel('Solution Quality (Average Shortest Path)', 'FontSize', 14);
    title(sprintf('Time vs Quality Trade-off Analysis (n=%d, Cmax=%d, r=%d)', n, Cmax, r), 'FontSize', 16, 'FontWeight', 'bold');
    legend('show', 'FontSize', 12, 'Location', 'best');
    set(gca, 'FontSize', 12);
    grid on; grid minor;
    saveAnalysisPlot(gcf, 'comparisons', 'time_quality_tradeoff', timestamp);
    
    % 5. Performance Improvements Summary
    figure('Position', [250, 250, 2200, 1600]);
    improvements = [comparisonResults.improvements.timeSpeedup, ...
                   -comparisonResults.improvements.qualityImprovementPercent, ...
                   comparisonResults.improvements.iterationsRatio];
    colors = {'green', 'blue', 'orange'};
    b = bar(improvements, 'FaceColor', 'flat');
    for i = 1:length(improvements)
        b.CData(i,:) = [0.2 0.7 0.3]; % Green for all for now
    end
    set(gca, 'XTickLabel', {'Time Speedup (x)', 'Quality Improve (%)', 'Iterations Ratio'});
    title(sprintf('Performance Improvements Summary (n=%d, Cmax=%d, r=%d)', n, Cmax, r), 'FontSize', 16, 'FontWeight', 'bold');
    ylabel('Factor / Percentage', 'FontSize', 14);
    set(gca, 'FontSize', 12);
    grid on; grid minor;
    
    % Add value labels on bars
    for i = 1:length(improvements)
        text(i, improvements(i) + sign(improvements(i))*0.05*max(abs(improvements)), ...
             sprintf('%.2f', improvements(i)), 'HorizontalAlignment', 'center', ...
             'FontSize', 12, 'FontWeight', 'bold');
    end
    saveAnalysisPlot(gcf, 'comparisons', 'performance_improvements', timestamp);
    
    % 6. Cache Hit Rate Distribution (if available)
    if ~isempty(optCacheRates) && any(optCacheRates > 0)
        figure('Position', [300, 300, 2200, 1600]);
        histogram(optCacheRates, 'Normalization', 'probability', 'FaceColor', [0.3 0.7 0.9], 'EdgeColor', 'black');
        title(sprintf('Cache Hit Rate Distribution (n=%d, Cmax=%d, r=%d)', n, Cmax, r), 'FontSize', 16, 'FontWeight', 'bold');
        xlabel('Cache Hit Rate (%)', 'FontSize', 14);
        ylabel('Probability', 'FontSize', 14);
        set(gca, 'FontSize', 12);
        grid on; grid minor;
        
        % Add statistics
        text(0.7, 0.8, sprintf('Mean: %.1f%%\nStd: %.1f%%', mean(optCacheRates), std(optCacheRates)), ...
             'Units', 'normalized', 'FontSize', 12, 'FontWeight', 'bold', ...
             'BackgroundColor', 'white', 'EdgeColor', 'black');
        saveAnalysisPlot(gcf, 'comparisons', 'cache_hitrate_distribution', timestamp);
    end
    
    fprintf('\nComparison analysis complete! Individual plots saved in: plots/comparisons/\n');
    
    % Save results
    resultsFilename = sprintf('results/grasp_comparison_results_%s.mat', timestamp);
    save(resultsFilename, 'comparisonResults');
    fprintf('Comparison results saved as: %s\n', resultsFilename);
    
    % Summary recommendations
    fprintf('\n=== Recommendations ===\n');
    
    if comparisonResults.improvements.timeSpeedup > 1.1
        fprintf('✓ Optimized version is %.1fx faster\n', comparisonResults.improvements.timeSpeedup);
    else
        fprintf('- No significant time improvement\n');
    end
    
    if comparisonResults.improvements.qualityImprovementPercent > 1
        fprintf('✓ Optimized version finds %.2f%% better solutions\n', ...
                comparisonResults.improvements.qualityImprovementPercent);
    elseif comparisonResults.improvements.qualityImprovementPercent > -1
        fprintf('≈ Similar solution quality\n');
    else
        fprintf('- Optimized version finds slightly worse solutions\n');
    end
    
    if comparisonResults.optimized.meanCacheHitRate > 20
        fprintf('✓ Caching is effective (%.1f%% hit rate)\n', ...
                comparisonResults.optimized.meanCacheHitRate);
    else
        fprintf('- Low cache effectiveness\n');
    end
    
    fprintf('\nOverall: ');
    if comparisonResults.improvements.timeSpeedup > 1.1 || ...
       comparisonResults.improvements.qualityImprovementPercent > 1
        fprintf('Optimized version is recommended\n');
    else
        fprintf('Use original version for simplicity\n');
    end
end