function sensitivityResults = plotParameterSensitivityHeatMap(G, n, Cmax, timeLimit)
% Create parameter sensitivity heat map for GRASP algorithm
% Inputs:
%   G - graph representing the network
%   n - number of nodes to select
%   Cmax - maximum allowed shortest path length between controllers
%   timeLimit - time limit for each parameter combination (default: 30)
% Output:
%   sensitivityResults - struct with detailed sensitivity analysis

    if nargin < 4
        timeLimit = 30;
    end

    fprintf('Creating parameter sensitivity heat map for GRASP...\n');
    fprintf('Time limit per configuration: %d seconds\n', timeLimit);
    
    % Parameter ranges to test
    rValues = [2, 3, 4, 5, 6, 8, 10, 15, 20];
    timeLimits = [10, 20, 30, 45, 60, 90, 120];
    
    nR = length(rValues);
    nTime = length(timeLimits);
    
    % Initialize result matrices
    avgQuality = nan(nR, nTime);
    bestQuality = nan(nR, nTime);
    stdQuality = nan(nR, nTime);
    successRate = nan(nR, nTime);
    avgIterations = nan(nR, nTime);
    avgCacheHitRate = nan(nR, nTime);
    
    totalConfigs = nR * nTime;
    configCount = 0;
    
    fprintf('Testing %d parameter combinations...\n', totalConfigs);
    
    % Test each parameter combination
    for i = 1:nR
        for j = 1:nTime
            r = rValues(i);
            maxTime = timeLimits(j);
            configCount = configCount + 1;
            
            fprintf('Config %d/%d: r=%d, time=%ds... ', ...
                    configCount, totalConfigs, r, maxTime);
            
            % Run multiple GRASP instances for this configuration
            numRuns = max(3, min(10, floor(60 / maxTime))); % Adaptive number of runs Example
            qualities = [];
            iterations = [];
            cacheHitRates = [];
            validRuns = 0;
            
            tic;
            for run = 1:numRuns
                try
                    % Use optimized GRASP with caching
                    options = struct('useCaching', true, 'stagnationLimit', inf, ...
                                   'trackNodeFreq', false, 'verbose', false);
                    [~, avgSP, maxSP, results] = GRASPOptimized(G, n, Cmax, r, maxTime, options);
                    
                    % Only consider feasible solutions
                    if ~isempty(avgSP) && ~isinf(avgSP) && maxSP <= Cmax
                        validRuns = validRuns + 1;
                        qualities(validRuns) = avgSP;
                        iterations(validRuns) = results.totalIterations;
                        if isfield(results, 'cacheHitRate')
                            cacheHitRates(validRuns) = results.cacheHitRate;
                        end
                    end
                catch ME
                    fprintf('Error in run %d: %s\n', run, ME.message);
                end
            end
            configTime = toc;
            
            % Calculate statistics for this configuration
            if validRuns > 0
                avgQuality(i, j) = mean(qualities);
                bestQuality(i, j) = min(qualities);
                stdQuality(i, j) = std(qualities);
                successRate(i, j) = 100 * validRuns / numRuns;
                avgIterations(i, j) = mean(iterations);
                if ~isempty(cacheHitRates)
                    avgCacheHitRate(i, j) = mean(cacheHitRates);
                end
                
                fprintf('completed (%.1fs, %d/%d valid, best=%.4f)\n', ...
                        configTime, validRuns, numRuns, bestQuality(i, j));
            else
                fprintf('failed (no valid solutions)\n');
            end
        end
    end
    
    % Store results
    sensitivityResults = struct();
    sensitivityResults.rValues = rValues;
    sensitivityResults.timeLimits = timeLimits;
    sensitivityResults.avgQuality = avgQuality;
    sensitivityResults.bestQuality = bestQuality;
    sensitivityResults.stdQuality = stdQuality;
    sensitivityResults.successRate = successRate;
    sensitivityResults.avgIterations = avgIterations;
    sensitivityResults.avgCacheHitRate = avgCacheHitRate;
    
    % Find optimal parameters
    [minAvg, minIdx] = nanmin(avgQuality(:));
    [optR_avg, optTime_avg] = ind2sub(size(avgQuality), minIdx);
    
    [minBest, minBestIdx] = nanmin(bestQuality(:));
    [optR_best, optTime_best] = ind2sub(size(bestQuality), minBestIdx);
    
    % Add path for utility functions
    addpath('utilities');
    
    % Generate timestamp for consistent naming
    timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
    
    % Create individual heat map plots (larger and more readable)
    
    % 1. Average Quality Heat Map
    figure('Position', [50, 50, 2200, 1600]);
    imagesc(avgQuality);
    colorbar;
    title(sprintf('Average Solution Quality Heat Map (n=%d, Cmax=%d)', n, Cmax), 'FontSize', 16, 'FontWeight', 'bold');
    xlabel('Time Limit (seconds)', 'FontSize', 14);
    ylabel('r Parameter', 'FontSize', 14);
    set(gca, 'XTick', 1:nTime, 'XTickLabel', timeLimits, 'FontSize', 12);
    set(gca, 'YTick', 1:nR, 'YTickLabel', rValues, 'FontSize', 12);
    
    % Mark optimal point
    hold on;
    scatter(optTime_avg, optR_avg, 150, 'r', 'filled', 'MarkerEdgeColor', 'w', 'LineWidth', 3);
    text(optTime_avg, optR_avg-0.3, sprintf('%.4f', minAvg), ...
         'HorizontalAlignment', 'center', 'Color', 'white', 'FontWeight', 'bold', 'FontSize', 12);
    grid on; grid minor;
    saveAnalysisPlot(gcf, 'parameters', 'average_quality_heatmap', timestamp);
    
    % 2. Best Quality Heat Map
    figure('Position', [100, 100, 2200, 1600]);
    imagesc(bestQuality);
    colorbar;
    title(sprintf('Best Solution Quality Heat Map (n=%d, Cmax=%d)', n, Cmax), 'FontSize', 16, 'FontWeight', 'bold');
    xlabel('Time Limit (seconds)', 'FontSize', 14);
    ylabel('r Parameter', 'FontSize', 14);
    set(gca, 'XTick', 1:nTime, 'XTickLabel', timeLimits, 'FontSize', 12);
    set(gca, 'YTick', 1:nR, 'YTickLabel', rValues, 'FontSize', 12);
    
    % Mark optimal point
    hold on;
    scatter(optTime_best, optR_best, 150, 'r', 'filled', 'MarkerEdgeColor', 'w', 'LineWidth', 3);
    text(optTime_best, optR_best-0.3, sprintf('%.4f', minBest), ...
         'HorizontalAlignment', 'center', 'Color', 'white', 'FontWeight', 'bold', 'FontSize', 12);
    grid on; grid minor;
    saveAnalysisPlot(gcf, 'parameters', 'best_quality_heatmap', timestamp);
    
    % 3. Consistency Heat Map
    figure('Position', [150, 150, 2200, 1600]);
    imagesc(stdQuality);
    colorbar;
    title(sprintf('Solution Consistency Heat Map (Lower Std Dev = Better) (n=%d, Cmax=%d)', n, Cmax), 'FontSize', 16, 'FontWeight', 'bold');
    xlabel('Time Limit (seconds)', 'FontSize', 14);
    ylabel('r Parameter', 'FontSize', 14);
    set(gca, 'XTick', 1:nTime, 'XTickLabel', timeLimits, 'FontSize', 12);
    set(gca, 'YTick', 1:nR, 'YTickLabel', rValues, 'FontSize', 12);
    grid on; grid minor;
    saveAnalysisPlot(gcf, 'parameters', 'consistency_heatmap', timestamp);
    
    % 4. Success Rate Heat Map
    figure('Position', [200, 200, 2200, 1600]);
    imagesc(successRate);
    colorbar;
    title(sprintf('Success Rate Heat Map (n=%d, Cmax=%d)', n, Cmax), 'FontSize', 16, 'FontWeight', 'bold');
    xlabel('Time Limit (seconds)', 'FontSize', 14);
    ylabel('r Parameter', 'FontSize', 14);
    set(gca, 'XTick', 1:nTime, 'XTickLabel', timeLimits, 'FontSize', 12);
    set(gca, 'YTick', 1:nR, 'YTickLabel', rValues, 'FontSize', 12);
    caxis([0, 100]);
    grid on; grid minor;
    saveAnalysisPlot(gcf, 'parameters', 'success_rate_heatmap', timestamp);
    
    % 5. Iterations Heat Map
    figure('Position', [250, 250, 2200, 1600]);
    imagesc(avgIterations);
    colorbar;
    title(sprintf('Average Iterations Heat Map (n=%d, Cmax=%d)', n, Cmax), 'FontSize', 16, 'FontWeight', 'bold');
    xlabel('Time Limit (seconds)', 'FontSize', 14);
    ylabel('r Parameter', 'FontSize', 14);
    set(gca, 'XTick', 1:nTime, 'XTickLabel', timeLimits, 'FontSize', 12);
    set(gca, 'YTick', 1:nR, 'YTickLabel', rValues, 'FontSize', 12);
    grid on; grid minor;
    saveAnalysisPlot(gcf, 'parameters', 'iterations_heatmap', timestamp);
    
    % 6. Cache Hit Rate Heat Map (if data available)
    if any(~isnan(avgCacheHitRate(:)))
        figure('Position', [300, 300, 2200, 1600]);
        imagesc(avgCacheHitRate);
        colorbar;
        title(sprintf('Cache Hit Rate Heat Map (n=%d, Cmax=%d)', n, Cmax), 'FontSize', 16, 'FontWeight', 'bold');
        xlabel('Time Limit (seconds)', 'FontSize', 14);
        ylabel('r Parameter', 'FontSize', 14);
        set(gca, 'XTick', 1:nTime, 'XTickLabel', timeLimits, 'FontSize', 12);
        set(gca, 'YTick', 1:nR, 'YTickLabel', rValues, 'FontSize', 12);
        caxis([0, 100]);
        grid on; grid minor;
        saveAnalysisPlot(gcf, 'parameters', 'cache_hitrate_heatmap', timestamp);
    end
    
    % Print summary
    fprintf('\n=== Parameter Sensitivity Analysis Results ===\n');
    fprintf('Best average quality: %.6f at r=%d, time=%ds\n', ...
            minAvg, rValues(optR_avg), timeLimits(optTime_avg));
    fprintf('Best overall quality: %.6f at r=%d, time=%ds\n', ...
            minBest, rValues(optR_best), timeLimits(optTime_best));
    
    % Find most consistent parameters (lowest std dev with good quality)
    validMask = ~isnan(avgQuality) & ~isnan(stdQuality);
    qualityThreshold = prctile(avgQuality(validMask), 25); % Top 25% of average quality
    consistentMask = validMask & avgQuality <= qualityThreshold;
    
    if any(consistentMask(:))
        [~, consistentIdx] = nanmin(stdQuality(consistentMask));
        consistentIndices = find(consistentMask);
        [consistentR, consistentTime] = ind2sub(size(avgQuality), consistentIndices(consistentIdx));
        
        fprintf('Most consistent (low std dev): r=%d, time=%ds (avg=%.6f, std=%.6f)\n', ...
                rValues(consistentR), timeLimits(consistentTime), ...
                avgQuality(consistentR, consistentTime), stdQuality(consistentR, consistentTime));
    end
    
    % Parameter recommendations
    fprintf('\n=== Parameter Recommendations ===\n');
    
    % For quality
    fprintf('For best quality: r=%d, time=%ds\n', ...
            rValues(optR_best), timeLimits(optTime_best));
    
    % For consistency
    if any(consistentMask(:))
        fprintf('For consistency: r=%d, time=%ds\n', ...
                rValues(consistentR), timeLimits(consistentTime));
    end
    
    % For efficiency (good quality with low time)
    efficiencyScore = nan(size(avgQuality));
    for i = 1:nR
        for j = 1:nTime
            if ~isnan(avgQuality(i, j))
                % Score: lower is better (quality penalty + time penalty)
                qualityNorm = (avgQuality(i, j) - nanmin(avgQuality(:))) / ...
                             (nanmax(avgQuality(:)) - nanmin(avgQuality(:)));
                timeNorm = (timeLimits(j) - min(timeLimits)) / (max(timeLimits) - min(timeLimits));
                efficiencyScore(i, j) = qualityNorm + 0.3 * timeNorm; % Weight time less
            end
        end
    end
    
    [~, effIdx] = nanmin(efficiencyScore(:));
    [effR, effTime] = ind2sub(size(efficiencyScore), effIdx);
    fprintf('For efficiency: r=%d, time=%ds\n', ...
            rValues(effR), timeLimits(effTime));
    
    % Analyze r parameter sensitivity
    fprintf('\n=== Parameter Sensitivity Insights ===\n');
    
    % R parameter analysis
    avgByR = nanmean(avgQuality, 2);
    [~, bestRIdx] = nanmin(avgByR);
    fprintf('Best r parameter overall: %d (avg quality: %.6f)\n', ...
            rValues(bestRIdx), avgByR(bestRIdx));
    
    % Time analysis
    avgByTime = nanmean(avgQuality, 1);
    [~, bestTimeIdx] = nanmin(avgByTime);
    fprintf('Best time limit overall: %ds (avg quality: %.6f)\n', ...
            timeLimits(bestTimeIdx), avgByTime(bestTimeIdx));
    
    % Check for diminishing returns
    timeImprovements = diff(avgByTime);
    significantImprovements = find(abs(timeImprovements) > 0.001);
    if ~isempty(significantImprovements)
        lastImprovement = significantImprovements(end);
        fprintf('Diminishing returns after: %ds\n', timeLimits(lastImprovement));
    end
    
    
    % Save results
    resultsFilename = sprintf('results/parameter_sensitivity_results_%s.mat', timestamp);
    save(resultsFilename, 'sensitivityResults');
    fprintf('\nParameter sensitivity analysis complete!\n');
    fprintf('Results saved as: %s\n', resultsFilename);
    fprintf('Individual plots saved in: plots/parameters/\n');
    
    % Time parameter profile  
    figure('Position', [400, 400, 2200, 1600]);
    errorbar(timeLimits, avgByTime, nanstd(avgQuality, 0, 1), 'ro-', 'LineWidth', 3, 'MarkerSize', 10);
    title('Solution Quality vs Time Limit', 'FontSize', 16, 'FontWeight', 'bold');
    xlabel('Time Limit (seconds)', 'FontSize', 14);
    ylabel('Average Quality', 'FontSize', 14);
    set(gca, 'FontSize', 12);
    grid on; grid minor;
    saveAnalysisPlot(gcf, 'parameters', 'quality_vs_time_limit', timestamp);
    
    % Quality vs consistency trade-off
    figure('Position', [450, 450, 2200, 1600]);
    validIdx = ~isnan(avgQuality(:)) & ~isnan(stdQuality(:));
    scatter(avgQuality(validIdx), stdQuality(validIdx), 100, 'filled', 'alpha', 0.7);
    title('Quality vs Consistency Trade-off', 'FontSize', 16, 'FontWeight', 'bold');
    xlabel('Average Quality (lower is better)', 'FontSize', 14);
    ylabel('Standard Deviation (lower is better)', 'FontSize', 14);
    set(gca, 'FontSize', 12);
    grid on; grid minor;
    saveAnalysisPlot(gcf, 'parameters', 'quality_consistency_tradeoff', timestamp);
    
    % Success rate analysis
    figure('Position', [500, 500, 2200, 1600]);
    validSuccessIdx = ~isnan(successRate(:));
    histogram(successRate(validSuccessIdx), 'Normalization', 'probability', 'FaceColor', [0.3 0.7 0.9]);
    title('Success Rate Distribution', 'FontSize', 16, 'FontWeight', 'bold');
    xlabel('Success Rate (%)', 'FontSize', 14);
    ylabel('Probability', 'FontSize', 14);
    set(gca, 'FontSize', 12);
    grid on; grid minor;
    saveAnalysisPlot(gcf, 'parameters', 'success_rate_distribution', timestamp);
end