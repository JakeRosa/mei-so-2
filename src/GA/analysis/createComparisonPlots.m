function createComparisonPlots(standardResults, optimizedResults, timestamp)
% Create comparison plots between standard and optimized GA

    fprintf('Creating GA comparison plots...\n');
    
    % Create plots directory if it doesn't exist
    if ~exist('plots/comparison', 'dir')
        mkdir('plots/comparison');
    end
    
    % Extract data
    standardObjs = [standardResults.objective];
    standardTimes = [standardResults.runTime];
    standardValid = [standardResults.valid];
    
    optimizedObjs = [optimizedResults.objective];
    optimizedTimes = [optimizedResults.runTime];
    optimizedValid = [optimizedResults.valid];
    
    %% Plot 1: Objective comparison
    figure('Position', [100, 100, 800, 600]);
    data = {standardObjs(standardValid), optimizedObjs(optimizedValid)};
    labels = {'Standard', 'Optimized'};
    
    boxplot([data{:}], [ones(size(data{1})), 2*ones(size(data{2}))]);
    set(gca, 'XTickLabel', labels);
    ylabel('Objective Value');
    title('Solution Quality Comparison');
    grid on;
    
    % Add mean markers
    hold on;
    means = cellfun(@mean, data);
    plot(1:2, means, 'r*', 'MarkerSize', 10);
    
    saveas(gcf, sprintf('plots/comparison/objective_comparison_%s.png', timestamp));
    close(gcf);
    
    %% Plot 2: Runtime comparison
    figure('Position', [100, 100, 800, 600]);
    data = {standardTimes, optimizedTimes};
    
    boxplot([data{:}], [ones(size(data{1})), 2*ones(size(data{2}))]);
    set(gca, 'XTickLabel', labels);
    ylabel('Runtime (seconds)');
    title('Execution Time Comparison');
    grid on;
    
    saveas(gcf, sprintf('plots/comparison/runtime_comparison_%s.png', timestamp));
    close(gcf);
    
    %% Plot 4: Convergence comparison
    figure('Position', [100, 100, 800, 600]);
    
    % Plot average convergence for each type
    standardConvergence = [];
    optimizedConvergence = [];
    
    for i = 1:length(standardResults)
        if standardValid(i) && isfield(standardResults(i).runResults, 'objectives')
            objs = standardResults(i).runResults.objectives;
            if i == 1
                standardConvergence = objs;
            else
                % Align lengths
                maxLen = max(length(standardConvergence), length(objs));
                if size(standardConvergence, 2) < maxLen
                    standardConvergence(:, end+1:maxLen) = NaN;
                end
                if length(objs) < maxLen
                    objs(end+1:maxLen) = NaN;
                end
                standardConvergence(end+1, :) = objs;
            end
        end
    end
    
    for i = 1:length(optimizedResults)
        if optimizedValid(i) && isfield(optimizedResults(i).runResults, 'objectives')
            objs = optimizedResults(i).runResults.objectives;
            if i == 1
                optimizedConvergence = objs;
            else
                % Align lengths
                maxLen = max(length(optimizedConvergence), length(objs));
                if size(optimizedConvergence, 2) < maxLen
                    optimizedConvergence(:, end+1:maxLen) = NaN;
                end
                if length(objs) < maxLen
                    objs(end+1:maxLen) = NaN;
                end
                optimizedConvergence(end+1, :) = objs;
            end
        end
    end
    
    if ~isempty(standardConvergence)
        avgStandard = nanmean(standardConvergence, 1);
        plot(1:length(avgStandard), avgStandard, 'b-', 'LineWidth', 2);
        hold on;
    end
    
    if ~isempty(optimizedConvergence)
        avgOptimized = nanmean(optimizedConvergence, 1);
        plot(1:length(avgOptimized), avgOptimized, 'r-', 'LineWidth', 2);
    end
    
    xlabel('Generation');
    ylabel('Average Objective');
    title('Average Convergence Comparison');
    legend('Standard GA', 'Optimized GA', 'Location', 'best');
    grid on;
    
    saveas(gcf, sprintf('plots/comparison/convergence_comparison_%s.png', timestamp));
    close(gcf);
    
    %% Plot 5: Cache performance
    if any(arrayfun(@(r) isfield(r, 'cacheHitRate'), optimizedResults))
        figure('Position', [100, 100, 800, 600]);
        cacheRates = [optimizedResults.cacheHitRate] * 100;
        bar(cacheRates);
        xlabel('Run Number');
        ylabel('Cache Hit Rate (%)');
        title('Cache Performance (Optimized GA)');
        grid on;
        
        % Add average line
        avgCache = mean(cacheRates);
        hold on;
        plot([0.5, length(cacheRates)+0.5], [avgCache, avgCache], 'r--', 'LineWidth', 2);
        text(length(cacheRates)/2, avgCache*1.05, sprintf('Avg: %.1f%%', avgCache), ...
            'HorizontalAlignment', 'center', 'Color', 'r');
        
        saveas(gcf, sprintf('plots/comparison/cache_performance_%s.png', timestamp));
        close(gcf);
    end
    
    %% Plot 6: Performance summary
    figure('Position', [100, 100, 800, 600]);
    axis off;
    
    textY = 0.9;
    textStep = 0.08;
    
    text(0.5, textY, 'PERFORMANCE SUMMARY', 'FontSize', 14, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center');
    textY = textY - 2*textStep;
    
    % Quality improvement
    if any(standardValid) && any(optimizedValid)
        stdAvgObj = mean(standardObjs(standardValid));
        optAvgObj = mean(optimizedObjs(optimizedValid));
        improvement = (stdAvgObj - optAvgObj) / stdAvgObj * 100;
        
        text(0.1, textY, sprintf('Quality improvement: %.2f%%', improvement), 'FontSize', 11);
        textY = textY - textStep;
    end
    
    % Speed improvement
    speedup = mean(standardTimes) / mean(optimizedTimes);
    text(0.1, textY, sprintf('Speed improvement: %.2fx', speedup), 'FontSize', 11);
    textY = textY - textStep;
    
    % Generation comparison
    standardGens = arrayfun(@(r) length(r.runResults.generations), standardResults(standardValid));
    optimizedGens = arrayfun(@(r) length(r.runResults.generations), optimizedResults(optimizedValid));
    
    if ~isempty(standardGens) && ~isempty(optimizedGens)
        text(0.1, textY, sprintf('Avg generations - Standard: %.0f, Optimized: %.0f', ...
            mean(standardGens), mean(optimizedGens)), 'FontSize', 11);
        textY = textY - textStep;
    end
    
    % Cache statistics
    if any(arrayfun(@(r) isfield(r, 'totalEvaluations'), optimizedResults))
        avgEvals = mean([optimizedResults(optimizedValid).totalEvaluations]);
        avgCacheHits = mean([optimizedResults(optimizedValid).cacheHitRate]) * 100;
        
        text(0.1, textY, sprintf('Avg evaluations saved: %.0f (%.1f%% cache hits)', ...
            avgEvals * avgCacheHits / 100, avgCacheHits), 'FontSize', 11);
        textY = textY - textStep;
    end
    
    saveas(gcf, sprintf('plots/comparison/performance_summary_%s.png', timestamp));
    close(gcf);
    
    %% Plot 7: Objective over time
    figure('Position', [100, 100, 800, 600]);
    
    for i = 1:min(3, sum(standardValid))
        validIdx = find(standardValid);
        if i <= length(validIdx) && isfield(standardResults(validIdx(i)).runResults, 'times')
            times = standardResults(validIdx(i)).runResults.times;
            objs = standardResults(validIdx(i)).runResults.objectives;
            plot(times, objs, 'b-', 'LineWidth', 1);
            hold on;
        end
    end
    
    for i = 1:min(3, sum(optimizedValid))
        validIdx = find(optimizedValid);
        if i <= length(validIdx) && isfield(optimizedResults(validIdx(i)).runResults, 'times')
            times = optimizedResults(validIdx(i)).runResults.times;
            objs = optimizedResults(validIdx(i)).runResults.objectives;
            plot(times, objs, 'r--', 'LineWidth', 1);
            hold on;
        end
    end
    
    xlabel('Time (seconds)');
    ylabel('Objective Value');
    title('Convergence Over Time (First 3 Runs)');
    legend('Standard', 'Optimized', 'Location', 'best');
    grid on;
    
    saveas(gcf, sprintf('plots/comparison/objective_over_time_%s.png', timestamp));
    close(gcf);
    
    %% Plot 8: Generations per second
    figure('Position', [100, 100, 800, 600]);
    
    standardGenPerSec = standardGens ./ standardTimes(standardValid);
    optimizedGenPerSec = optimizedGens ./ optimizedTimes(optimizedValid);
    
    data = {standardGenPerSec, optimizedGenPerSec};
    boxplot([data{:}], [ones(size(data{1})), 2*ones(size(data{2}))]);
    set(gca, 'XTickLabel', {'Standard', 'Optimized'});
    ylabel('Generations per Second');
    title('Processing Speed Comparison');
    grid on;
    
    saveas(gcf, sprintf('plots/comparison/generations_per_second_%s.png', timestamp));
    close(gcf);
    
    %% Plot 9: Quality vs Time scatter
    figure('Position', [100, 100, 800, 600]);
    
    scatter(standardTimes(standardValid), standardObjs(standardValid), 50, 'b', 'filled');
    hold on;
    scatter(optimizedTimes(optimizedValid), optimizedObjs(optimizedValid), 50, 'r', 'filled');
    
    xlabel('Runtime (seconds)');
    ylabel('Objective Value');
    title('Quality vs Time Trade-off');
    legend('Standard', 'Optimized', 'Location', 'best');
    grid on;
    
    saveas(gcf, sprintf('plots/comparison/quality_vs_time_%s.png', timestamp));
    close(gcf);
    
    %% Plot 10: Efficiency metrics
    figure('Position', [100, 100, 800, 600]);
    
    % Calculate efficiency (quality per second)
    standardEff = 1 ./ (standardObjs(standardValid) .* standardTimes(standardValid));
    optimizedEff = 1 ./ (optimizedObjs(optimizedValid) .* optimizedTimes(optimizedValid));
    
    data = {standardEff, optimizedEff};
    boxplot([data{:}], [ones(size(data{1})), 2*ones(size(data{2}))]);
    set(gca, 'XTickLabel', {'Standard', 'Optimized'});
    ylabel('Efficiency (1 / (Objective × Time))');
    title('Overall Efficiency Comparison');
    grid on;
    
    saveas(gcf, sprintf('plots/comparison/efficiency_comparison_%s.png', timestamp));
    close(gcf);
    
    fprintf('GA comparison plots created successfully.\n');
end