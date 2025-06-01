function createParameterAnalysisPlot(parameterResults, timestamp)
    % Create comprehensive parameter analysis visualization with individual plots
    % Inputs:
    %   parameterResults - struct array with parameter testing results
    %   timestamp - timestamp string for file naming
    % Outputs:
    %   Creates and saves comprehensive parameter analysis plots
    
    fprintf('Creating parameter analysis plots...\n');
    
    % Add path for utility functions
    addpath('utilities');
    
    % Check if saveAnalysisPlot function exists
    if ~exist('saveAnalysisPlot', 'file')
        warning('saveAnalysisPlot function not found. Creating plots folder and using basic saveas instead.');
        % Create plots folder if it doesn't exist
        if ~exist('plots', 'dir')
            mkdir('plots');
        end
        if ~exist('plots/parameters', 'dir')
            mkdir('plots/parameters');
        end
    end
    
    % Extract data for plotting
    rValues = [parameterResults.r];
    validParams = [parameterResults.validRuns] > 0;
    
    if sum(validParams) == 0
        fprintf('Warning: No valid parameter results to plot\n');
        return;
    end
    
    % Filter to valid parameters only
    validResults = parameterResults(validParams);
    validRValues = rValues(validParams);
    
    means = [validResults.meanAvgSP];
    stds = [validResults.stdAvgSP];
    bests = [validResults.bestAvgSP];
    worsts = [validResults.worstAvgSP];
    successRates = [validResults.successRate];
    
    % Create individual parameter analysis plots
    
    % 1. Box plots for distribution analysis
    figure('Position', [50, 50, 1200, 800]);
    allData = [];
    groupLabels = [];
    for i = 1:length(validResults)
        data = validResults(i).allResults;
        allData = [allData; data(:)];
        groupLabels = [groupLabels; repmat(validRValues(i), length(data), 1)];
    end
    
    if ~isempty(allData)
        boxplot(allData, groupLabels);
        title('Solution Quality Distribution by r Parameter', 'FontSize', 14, 'FontWeight', 'bold');
        xlabel('r Parameter', 'FontSize', 12);
        ylabel('Average Shortest Path', 'FontSize', 12);
        set(gca, 'FontSize', 11);
        grid on;
    end
    saveAnalysisPlot(gcf, 'parameters', 'distribution_analysis', timestamp);
    
    % 2. Mean with error bars
    figure('Position', [100, 100, 1200, 800]);
    errorbar(validRValues, means, stds, 'o-', 'LineWidth', 1.5, 'MarkerSize', 6, ...
             'MarkerFaceColor', [0.2 0.4 0.8], 'Color', [0.2 0.4 0.8]);
    title('Mean Performance ± Standard Deviation', 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('r Parameter', 'FontSize', 12);
    ylabel('Average Shortest Path', 'FontSize', 12);
    set(gca, 'FontSize', 11);
    grid on;
    
    % Mark the best parameter
    [~, bestIdx] = min(means);
    hold on;
    plot(validRValues(bestIdx), means(bestIdx), 'ro', 'MarkerSize', 8, 'LineWidth', 2, ...
         'MarkerFaceColor', 'red');
    legend('Mean ± Std Dev', 'Best Parameter', 'Location', 'best', 'FontSize', 10);
    saveAnalysisPlot(gcf, 'parameters', 'mean_performance', timestamp);
    
    % 3. Best vs Mean vs Worst comparison
    figure('Position', [150, 150, 1200, 800]);
    plot(validRValues, means, 'o-', 'LineWidth', 1.5, 'MarkerSize', 6, ...
         'Color', [0.2 0.4 0.8], 'MarkerFaceColor', [0.2 0.4 0.8], 'DisplayName', 'Mean');
    hold on;
    plot(validRValues, bests, 's-', 'LineWidth', 1.5, 'MarkerSize', 6, ...
         'Color', [0.8 0.2 0.2], 'MarkerFaceColor', [0.8 0.2 0.2], 'DisplayName', 'Best');
    plot(validRValues, worsts, '^-', 'LineWidth', 1.5, 'MarkerSize', 6, ...
         'Color', [0.2 0.8 0.2], 'MarkerFaceColor', [0.2 0.8 0.2], 'DisplayName', 'Worst');
    title('Performance Comparison: Best vs Mean vs Worst', 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('r Parameter', 'FontSize', 12);
    ylabel('Average Shortest Path', 'FontSize', 12);
    set(gca, 'FontSize', 11);
    legend('show', 'FontSize', 10, 'Location', 'best');
    grid on;
    saveAnalysisPlot(gcf, 'parameters', 'best_mean_worst_comparison', timestamp);
    
    % 4. Success rate analysis  
    figure('Position', [200, 200, 1200, 800]);
    bar(validRValues, successRates, 'FaceColor', [0.3 0.7 0.3], 'EdgeColor', [0.2 0.5 0.2], 'LineWidth', 1);
    title('Success Rate by r Parameter', 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('r Parameter', 'FontSize', 12);
    ylabel('Success Rate (%)', 'FontSize', 12);
    set(gca, 'FontSize', 11);
    ylim([0, 105]);
    grid on;
    
    % Add text annotations for exact values
    for i = 1:length(validRValues)
        text(validRValues(i), successRates(i) + 2, sprintf('%.0f%%', successRates(i)), ...
             'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
    end
    saveAnalysisPlot(gcf, 'parameters', 'success_rate_analysis', timestamp);
    
    % 5. Coefficient of variation (stability)
    cv = 100 * stds ./ means; % Coefficient of variation in percentage
    figure('Position', [250, 250, 1200, 800]);
    bar(validRValues, cv, 'FaceColor', [0.7 0.3 0.7], 'EdgeColor', [0.5 0.2 0.5], 'LineWidth', 1);
    title('Solution Stability Analysis (Coefficient of Variation)', 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('r Parameter', 'FontSize', 12);
    ylabel('Coefficient of Variation (%)', 'FontSize', 12);
    set(gca, 'FontSize', 11);
    grid on;
    
    % Add text annotations
    for i = 1:length(validRValues)
        text(validRValues(i), cv(i) + max(cv)*0.02, sprintf('%.1f%%', cv(i)), ...
             'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
    end
    saveAnalysisPlot(gcf, 'parameters', 'stability_analysis', timestamp);
    
    % 6. Performance vs Stability trade-off scatter plot
    figure('Position', [300, 300, 1200, 800]);
    scatter(means, cv, 120, successRates, 'filled', 'MarkerEdgeColor', [0.3 0.3 0.3], 'LineWidth', 1);
    colorbar;
    caxis([0, 100]);
    title('Performance vs Stability Trade-off (Color = Success Rate)', 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('Mean Performance (lower is better)', 'FontSize', 12);
    ylabel('Coefficient of Variation (lower is better)', 'FontSize', 12);
    set(gca, 'FontSize', 11);
    
    % Add parameter labels
    for i = 1:length(validRValues)
        text(means(i), cv(i), sprintf(' r=%d', validRValues(i)), 'FontSize', 10, 'FontWeight', 'bold');
    end
    
    % Add ideal region indication
    hold on;
    plot(min(means), min(cv), 'r*', 'MarkerSize', 15, 'LineWidth', 2);
    text(min(means), min(cv), ' Ideal Zone', 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'red');
    grid on;
    saveAnalysisPlot(gcf, 'parameters', 'performance_stability_tradeoff', timestamp);
    
    % 7. Performance range visualization
    figure('Position', [350, 350, 1200, 800]);
    fill([validRValues, fliplr(validRValues)], [bests, fliplr(worsts)], ...
         [0.8 0.9 1], 'FaceAlpha', 0.3, 'EdgeColor', 'none', 'DisplayName', 'Performance Range');
    hold on;
    plot(validRValues, means, 'o-', 'LineWidth', 2, 'MarkerSize', 6, ...
         'Color', [0.2 0.4 0.8], 'MarkerFaceColor', [0.2 0.4 0.8], 'DisplayName', 'Mean');
    plot(validRValues, bests, 's-', 'LineWidth', 1.5, 'MarkerSize', 5, ...
         'Color', [0.8 0.2 0.2], 'DisplayName', 'Best');
    plot(validRValues, worsts, '^-', 'LineWidth', 1.5, 'MarkerSize', 5, ...
         'Color', [0.2 0.8 0.2], 'DisplayName', 'Worst');
    title('Performance Range Visualization', 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('r Parameter', 'FontSize', 12);
    ylabel('Average Shortest Path', 'FontSize', 12);
    set(gca, 'FontSize', 11);
    legend('show', 'FontSize', 10, 'Location', 'best');
    grid on;
    saveAnalysisPlot(gcf, 'parameters', 'performance_range', timestamp);
    
    fprintf('\nParameter analysis complete! Individual plots saved in: plots/parameters/\n');
    
    % Create statistical analysis if sufficient data
    if length(validResults) > 1
        % 8. Statistical significance analysis
        figure('Position', [400, 400, 1200, 800]);
        
        if length(validResults) > 2 && ~isempty(allData)
            try
                [p, tbl, stats] = anova1(allData, groupLabels, 'off');
                
                % Create detailed box plot with significance
                boxplot(allData, groupLabels);
                title(sprintf('Statistical Significance Analysis (ANOVA p=%.4f)', p), 'FontSize', 14, 'FontWeight', 'bold');
                xlabel('r Parameter', 'FontSize', 12);
                ylabel('Average Shortest Path', 'FontSize', 12);
                set(gca, 'FontSize', 11);
                
                if p < 0.05
                    text(0.5, 0.95, 'Statistically significant differences detected', ...
                         'Units', 'normalized', 'FontWeight', 'bold', 'Color', 'red', 'FontSize', 12, ...
                         'HorizontalAlignment', 'center');
                else
                    text(0.5, 0.95, 'No statistically significant differences', ...
                         'Units', 'normalized', 'FontWeight', 'bold', 'Color', 'blue', 'FontSize', 12, ...
                         'HorizontalAlignment', 'center');
                end
                grid on;
                
            catch ME
                text(0.5, 0.5, sprintf('Error in ANOVA analysis: %s', ME.message), ...
                     'Units', 'normalized', 'HorizontalAlignment', 'center', 'FontSize', 12);
                title('Statistical Analysis - Error', 'FontSize', 14, 'FontWeight', 'bold');
            end
        else
            text(0.5, 0.5, 'Insufficient data for statistical analysis (need >2 parameters)', ...
                 'Units', 'normalized', 'HorizontalAlignment', 'center', 'FontSize', 12);
            title('Statistical Analysis - Insufficient Data', 'FontSize', 14, 'FontWeight', 'bold');
        end
        saveAnalysisPlot(gcf, 'parameters', 'statistical_significance', timestamp);
        
        % 9. Parameter ranking analysis
        figure('Position', [450, 450, 1200, 800]);
        [sortedMeans, sortIdx] = sort(means);
        sortedRValues = validRValues(sortIdx);
        sortedStds = stds(sortIdx);
        
        barh(1:length(sortedMeans), sortedMeans, 'LineWidth', 1, 'FaceColor', [0.5 0.8 1], 'EdgeColor', [0.3 0.6 0.8]);
        hold on;
        errorbar(sortedMeans, 1:length(sortedMeans), sortedStds, 'horizontal', 'k.', 'LineWidth', 1.5, 'MarkerSize', 8);
        
        set(gca, 'YTick', 1:length(sortedRValues), 'YTickLabel', ...
                arrayfun(@(x) sprintf('r=%d', x), sortedRValues, 'UniformOutput', false), ...
                'FontSize', 11);
        title('Parameter Performance Ranking (Best to Worst)', 'FontSize', 14, 'FontWeight', 'bold');
        xlabel('Mean Average Shortest Path', 'FontSize', 12);
        ylabel('r Parameter', 'FontSize', 12);
        grid on;
        
        % Highlight best parameter
        barh(1, sortedMeans(1), 'FaceColor', [0.2 0.8 0.2], 'LineWidth', 1, 'EdgeColor', [0.1 0.6 0.1]);
        text(sortedMeans(1) * 0.95, 1, ' Best', 'FontSize', 10, 'FontWeight', 'bold', 'Color', 'white');
        
        saveAnalysisPlot(gcf, 'parameters', 'performance_ranking', timestamp);
        
        % 10. Summary line plot with confidence intervals
        figure('Position', [500, 500, 1200, 800]);
        fill([validRValues, fliplr(validRValues)], [means - stds, fliplr(means + stds)], ...
             [0.8 0.9 1], 'FaceAlpha', 0.3, 'EdgeColor', 'none', 'DisplayName', '±1 Std Dev');
        hold on;
        plot(validRValues, means, 'o-', 'LineWidth', 2, 'MarkerSize', 7, ...
             'Color', [0.2 0.4 0.8], 'MarkerFaceColor', [0.2 0.4 0.8], 'DisplayName', 'Mean');
        
        % Highlight best parameter
        [~, bestIdx] = min(means);
        plot(validRValues(bestIdx), means(bestIdx), 'o', 'MarkerSize', 10, 'LineWidth', 2, ...
             'MarkerFaceColor', 'red', 'MarkerEdgeColor', 'magenta', 'DisplayName', 'Best Parameter');
        
        title('Parameter Performance Summary', 'FontSize', 14, 'FontWeight', 'bold');
        xlabel('r Parameter', 'FontSize', 12);
        ylabel('Average Shortest Path', 'FontSize', 12);
        set(gca, 'FontSize', 11);
        legend('show', 'FontSize', 10, 'Location', 'best');
        grid on;
        saveAnalysisPlot(gcf, 'parameters', 'performance_summary', timestamp);
        
        fprintf('Statistical analysis plots saved in: plots/parameters/\n');
    end
end

% Note: Using saveAnalysisPlot function for standardized plot saving