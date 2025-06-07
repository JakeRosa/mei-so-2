function phaseResults = analyzePhaseContribution(G, n, Cmax, r, numRuns)
% Analyze the contribution of construction vs local search phases in GRASP
% Inputs:
%   G - graph representing the network
%   n - number of nodes to select
%   Cmax - maximum allowed shortest path length between controllers
%   r - parameter for greedy randomized selection
%   numRuns - number of GRASP runs to analyze
% Output:
%   phaseResults - struct with detailed phase analysis

    fprintf('Analyzing GRASP phase contributions over %d runs...\n', numRuns);
    
    % Initialize tracking arrays
    constructionAvgSPs = zeros(numRuns, 1);
    localSearchAvgSPs = zeros(numRuns, 1);
    improvements = zeros(numRuns, 1);
    improvementPercentages = zeros(numRuns, 1);
    constructionTimes = zeros(numRuns, 1);
    localSearchTimes = zeros(numRuns, 1);
    
    validRuns = 0;
    
    for run = 1:numRuns
        % Time construction phase
        tic;
        constructedSolution = greedyRandomized(G, n, r, Cmax);
        constructionTime = toc;
        
        if isempty(constructedSolution)
            fprintf('Warning: No valid solution found in run %d\n', run);
            continue;
        end
        
        validRuns = validRuns + 1;
        
        % Evaluate construction phase
        [constructionAvgSP, ~] = PerfSNS(G, constructedSolution);
        
        % Time local search phase
        tic;
        finalSolution = steepestAscentHillClimbing(G, constructedSolution, Cmax);
        localSearchTime = toc;
        
        % Evaluate final solution
        [finalAvgSP, ~] = PerfSNS(G, finalSolution);
        
        % Calculate improvement
        improvement = constructionAvgSP - finalAvgSP;
        improvementPercentage = 100 * improvement / constructionAvgSP;
        
        % Store results
        constructionAvgSPs(validRuns) = constructionAvgSP;
        localSearchAvgSPs(validRuns) = finalAvgSP;
        improvements(validRuns) = improvement;
        improvementPercentages(validRuns) = improvementPercentage;
        constructionTimes(validRuns) = constructionTime;
        localSearchTimes(validRuns) = localSearchTime;
        
        if mod(run, 10) == 0
            fprintf('Completed %d/%d runs\n', run, numRuns);
        end
    end
    
    % Trim arrays to valid runs
    constructionAvgSPs = constructionAvgSPs(1:validRuns);
    localSearchAvgSPs = localSearchAvgSPs(1:validRuns);
    improvements = improvements(1:validRuns);
    improvementPercentages = improvementPercentages(1:validRuns);
    constructionTimes = constructionTimes(1:validRuns);
    localSearchTimes = localSearchTimes(1:validRuns);
    
    % Calculate statistics
    phaseResults = struct();
    phaseResults.validRuns = validRuns;
    
    % Construction phase statistics
    phaseResults.construction.meanAvgSP = mean(constructionAvgSPs);
    phaseResults.construction.stdAvgSP = std(constructionAvgSPs);
    phaseResults.construction.minAvgSP = min(constructionAvgSPs);
    phaseResults.construction.maxAvgSP = max(constructionAvgSPs);
    phaseResults.construction.meanTime = mean(constructionTimes);
    
    % Local search phase statistics
    phaseResults.localSearch.meanAvgSP = mean(localSearchAvgSPs);
    phaseResults.localSearch.stdAvgSP = std(localSearchAvgSPs);
    phaseResults.localSearch.minAvgSP = min(localSearchAvgSPs);
    phaseResults.localSearch.maxAvgSP = max(localSearchAvgSPs);
    phaseResults.localSearch.meanTime = mean(localSearchTimes);
    
    % Improvement statistics
    phaseResults.improvement.meanAbsolute = mean(improvements);
    phaseResults.improvement.stdAbsolute = std(improvements);
    phaseResults.improvement.meanPercentage = mean(improvementPercentages);
    phaseResults.improvement.stdPercentage = std(improvementPercentages);
    phaseResults.improvement.maxPercentage = max(improvementPercentages);
    phaseResults.improvement.runsWithImprovement = sum(improvements > 0);
    phaseResults.improvement.improvementRate = 100 * sum(improvements > 0) / validRuns;
    
    % Time statistics
    phaseResults.timing.totalConstructionTime = sum(constructionTimes);
    phaseResults.timing.totalLocalSearchTime = sum(localSearchTimes);
    phaseResults.timing.constructionPercentage = 100 * sum(constructionTimes) / (sum(constructionTimes) + sum(localSearchTimes));
    
    % Store raw data
    phaseResults.rawData.constructionAvgSPs = constructionAvgSPs;
    phaseResults.rawData.localSearchAvgSPs = localSearchAvgSPs;
    phaseResults.rawData.improvements = improvements;
    phaseResults.rawData.improvementPercentages = improvementPercentages;
    phaseResults.rawData.constructionTimes = constructionTimes;
    phaseResults.rawData.localSearchTimes = localSearchTimes;
    
    % Print summary
    fprintf('\n=== GRASP Phase Contribution Analysis ===\n');
    fprintf('Valid runs: %d/%d\n', validRuns, numRuns);
    fprintf('\nConstruction Phase:\n');
    fprintf('  Mean avgSP: %.4f (±%.4f)\n', phaseResults.construction.meanAvgSP, phaseResults.construction.stdAvgSP);
    fprintf('  Range: [%.4f, %.4f]\n', phaseResults.construction.minAvgSP, phaseResults.construction.maxAvgSP);
    fprintf('  Mean time: %.4f seconds\n', phaseResults.construction.meanTime);
    
    fprintf('\nLocal Search Phase:\n');
    fprintf('  Mean avgSP: %.4f (±%.4f)\n', phaseResults.localSearch.meanAvgSP, phaseResults.localSearch.stdAvgSP);
    fprintf('  Range: [%.4f, %.4f]\n', phaseResults.localSearch.minAvgSP, phaseResults.localSearch.maxAvgSP);
    fprintf('  Mean time: %.4f seconds\n', phaseResults.localSearch.meanTime);
    
    fprintf('\nImprovement Analysis:\n');
    fprintf('  Mean absolute improvement: %.4f (±%.4f)\n', phaseResults.improvement.meanAbsolute, phaseResults.improvement.stdAbsolute);
    fprintf('  Mean percentage improvement: %.2f%% (±%.2f%%)\n', phaseResults.improvement.meanPercentage, phaseResults.improvement.stdPercentage);
    fprintf('  Maximum improvement: %.2f%%\n', phaseResults.improvement.maxPercentage);
    fprintf('  Runs with improvement: %d/%d (%.1f%%)\n', phaseResults.improvement.runsWithImprovement, validRuns, phaseResults.improvement.improvementRate);
    
    fprintf('\nTiming Analysis:\n');
    fprintf('  Construction phase: %.1f%% of total time\n', phaseResults.timing.constructionPercentage);
    fprintf('  Local search phase: %.1f%% of total time\n', 100 - phaseResults.timing.constructionPercentage);
    
    % Add path for utility functions
    addpath('utilities');
    
    % Generate timestamp for consistent naming
    timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
    
    % Create individual phase analysis plots
    fprintf('\n=== Creating Individual Phase Analysis Plots ===\n');
    
    % 1. Solution quality comparison (boxplot)
    figure('Position', [50, 50, 1200, 800]);
    boxplot([constructionAvgSPs, localSearchAvgSPs], 'Labels', {'Construction', 'Local Search'}, ...
            'Colors', [0.3 0.7 0.9; 0.9 0.3 0.3]);
    title('Solution Quality Comparison by Phase', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('Average Shortest Path', 'FontSize', 12);
    set(gca, 'FontSize', 11);
    grid on;
    
    % Add mean markers
    hold on;
    means = [phaseResults.construction.meanAvgSP, phaseResults.localSearch.meanAvgSP];
    plot(1:2, means, 'ro', 'MarkerSize', 8, 'MarkerFaceColor', 'red', 'DisplayName', 'Mean');
    legend('Mean values', 'FontSize', 10);
    
    saveAnalysisPlot(gcf, 'phases', 'solution_quality_comparison', timestamp);
    
    % 2. Local search improvement distribution
    figure('Position', [100, 100, 1200, 800]);
    histogram(improvementPercentages, 'Normalization', 'probability', 'BinWidth', 1, ...
              'FaceColor', [0.2 0.8 0.4], 'EdgeColor', [0.1 0.6 0.3]);
    title('Local Search Improvement Distribution', 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('Improvement Percentage (%)', 'FontSize', 12);
    ylabel('Probability', 'FontSize', 12);
    set(gca, 'FontSize', 11);
    grid on;
    
    % Add statistics annotations
    text(0.7, 0.8, sprintf('Mean: %.2f%%\nStd: %.2f%%\nMax: %.2f%%', ...
         phaseResults.improvement.meanPercentage, phaseResults.improvement.stdPercentage, ...
         phaseResults.improvement.maxPercentage), ...
         'Units', 'normalized', 'FontSize', 11, 'FontWeight', 'bold', ...
         'BackgroundColor', 'white', 'EdgeColor', 'black');
    
    saveAnalysisPlot(gcf, 'phases', 'improvement_distribution', timestamp);
    
    % 3. Construction vs final quality scatter plot
    figure('Position', [150, 150, 1200, 800]);
    scatter(constructionAvgSPs, localSearchAvgSPs, 80, [0.3 0.6 0.9], 'filled', 'MarkerEdgeColor', [0.2 0.4 0.7]);
    hold on;
    plot([min(constructionAvgSPs), max(constructionAvgSPs)], [min(constructionAvgSPs), max(constructionAvgSPs)], ...
         'r--', 'LineWidth', 2, 'DisplayName', 'No improvement line');
    xlabel('Construction Phase avgSP', 'FontSize', 12);
    ylabel('Final avgSP (after Local Search)', 'FontSize', 12);
    title('Construction vs Final Solution Quality', 'FontSize', 14, 'FontWeight', 'bold');
    legend('Solution pairs', 'No improvement line', 'Location', 'best', 'FontSize', 10);
    set(gca, 'FontSize', 11);
    grid on;
    
    % Add correlation coefficient
    if length(constructionAvgSPs) > 1
        corrCoef = corrcoef(constructionAvgSPs, localSearchAvgSPs);
        text(0.05, 0.95, sprintf('Correlation: %.3f', corrCoef(1,2)), ...
             'Units', 'normalized', 'FontSize', 11, 'FontWeight', 'bold', ...
             'BackgroundColor', 'white', 'EdgeColor', 'black');
    end
    
    saveAnalysisPlot(gcf, 'phases', 'construction_vs_final_quality', timestamp);
    
    % 4. Average time per phase
    figure('Position', [200, 200, 1200, 800]);
    phases = {'Construction', 'Local Search'};
    times = [mean(constructionTimes), mean(localSearchTimes)];
    colors = [0.3 0.7 0.9; 0.9 0.3 0.3];
    
    b = bar(times, 'FaceColor', 'flat');
    b.CData = colors;
    set(gca, 'XTickLabel', phases, 'FontSize', 11);
    title('Average Execution Time per Phase', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('Time (seconds)', 'FontSize', 12);
    grid on;
    
    % Add value labels on bars
    for i = 1:length(times)
        text(i, times(i) + max(times)*0.02, sprintf('%.4fs', times(i)), ...
             'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold');
    end
    
    % Add percentage labels
    totalTime = sum(times);
    for i = 1:length(times)
        text(i, times(i)/2, sprintf('%.1f%%', 100*times(i)/totalTime), ...
             'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold', 'Color', 'white');
    end
    
    saveAnalysisPlot(gcf, 'phases', 'execution_time_comparison', timestamp);
    
    % 5. Improvement vs construction quality correlation
    figure('Position', [250, 250, 1200, 800]);
    scatter(constructionAvgSPs, improvementPercentages, 80, [0.7 0.3 0.7], 'filled', 'MarkerEdgeColor', [0.5 0.2 0.5]);
    xlabel('Construction Phase avgSP', 'FontSize', 12);
    ylabel('Local Search Improvement (%)', 'FontSize', 12);
    title('Improvement Potential vs Construction Quality', 'FontSize', 14, 'FontWeight', 'bold');
    set(gca, 'FontSize', 11);
    grid on;
    
    % Add trend line
    if length(constructionAvgSPs) > 1
        p = polyfit(constructionAvgSPs, improvementPercentages, 1);
        hold on;
        x_trend = linspace(min(constructionAvgSPs), max(constructionAvgSPs), 100);
        y_trend = polyval(p, x_trend);
        plot(x_trend, y_trend, 'r-', 'LineWidth', 2, 'DisplayName', 'Trend line');
        legend('Data points', 'Trend line', 'FontSize', 10);
        
        % Add correlation
        corrCoef = corrcoef(constructionAvgSPs, improvementPercentages);
        text(0.05, 0.95, sprintf('Correlation: %.3f', corrCoef(1,2)), ...
             'Units', 'normalized', 'FontSize', 11, 'FontWeight', 'bold', ...
             'BackgroundColor', 'white', 'EdgeColor', 'black');
    end
    
    saveAnalysisPlot(gcf, 'phases', 'improvement_vs_construction_quality', timestamp);
    
    % 6. Solution quality evolution over runs
    figure('Position', [300, 300, 1200, 800]);
    plot(1:validRuns, constructionAvgSPs, 'o-', 'LineWidth', 1.5, 'MarkerSize', 6, ...
         'Color', [0.3 0.7 0.9], 'MarkerFaceColor', [0.3 0.7 0.9], 'DisplayName', 'Construction');
    hold on;
    plot(1:validRuns, localSearchAvgSPs, 's-', 'LineWidth', 1.5, 'MarkerSize', 6, ...
         'Color', [0.9 0.3 0.3], 'MarkerFaceColor', [0.9 0.3 0.3], 'DisplayName', 'After Local Search');
    xlabel('Run Number', 'FontSize', 12);
    ylabel('Average Shortest Path', 'FontSize', 12);
    title('Solution Quality Evolution Across Runs', 'FontSize', 14, 'FontWeight', 'bold');
    legend('show', 'FontSize', 10, 'Location', 'best');
    set(gca, 'FontSize', 11);
    grid on;
    
    % Add moving averages for better trend visualization
    if validRuns > 5
        windowSize = max(3, floor(validRuns/10));
        constructionMA = movmean(constructionAvgSPs, windowSize);
        localSearchMA = movmean(localSearchAvgSPs, windowSize);
        plot(1:validRuns, constructionMA, '--', 'LineWidth', 2, 'Color', [0.2 0.5 0.7], 'DisplayName', 'Construction MA');
        plot(1:validRuns, localSearchMA, '--', 'LineWidth', 2, 'Color', [0.7 0.2 0.2], 'DisplayName', 'Local Search MA');
        legend('show', 'FontSize', 10);
    end
    
    saveAnalysisPlot(gcf, 'phases', 'solution_quality_evolution', timestamp);
    
    % 7. Phase contribution summary
    figure('Position', [350, 350, 1200, 800]);
    
    % Create a comprehensive bar chart showing multiple metrics
    metrics = {'Mean Quality', 'Best Quality', 'Worst Quality'};
    constructionData = [phaseResults.construction.meanAvgSP, phaseResults.construction.minAvgSP, phaseResults.construction.maxAvgSP];
    localSearchData = [phaseResults.localSearch.meanAvgSP, phaseResults.localSearch.minAvgSP, phaseResults.localSearch.maxAvgSP];
    
    x = 1:length(metrics);
    width = 0.35;
    
    b1 = bar(x - width/2, constructionData, width, 'FaceColor', [0.3 0.7 0.9], 'DisplayName', 'Construction');
    hold on;
    b2 = bar(x + width/2, localSearchData, width, 'FaceColor', [0.9 0.3 0.3], 'DisplayName', 'Local Search');
    
    set(gca, 'XTickLabel', metrics, 'FontSize', 11);
    title('Phase Performance Summary', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('Average Shortest Path', 'FontSize', 12);
    legend('show', 'FontSize', 10);
    grid on;
    
    % Add improvement annotations
    for i = 1:length(metrics)
        improvement = constructionData(i) - localSearchData(i);
        improvementPct = 100 * improvement / constructionData(i);
        text(i, max(constructionData(i), localSearchData(i)) + max([constructionData, localSearchData])*0.02, ...
             sprintf('↓%.1f%%', improvementPct), 'HorizontalAlignment', 'center', ...
             'FontSize', 10, 'FontWeight', 'bold', 'Color', 'green');
    end
    
    saveAnalysisPlot(gcf, 'phases', 'phase_performance_summary', timestamp);
    
    % 9. Detailed improvement analysis
    figure('Position', [450, 450, 1200, 800]);
    
    % Create improvement categories
    noImprovement = sum(improvementPercentages <= 0);
    smallImprovement = sum(improvementPercentages > 0 & improvementPercentages <= 5);
    moderateImprovement = sum(improvementPercentages > 5 & improvementPercentages <= 15);
    largeImprovement = sum(improvementPercentages > 15);
    
    categories = {'No Improvement', 'Small (0-5%)', 'Moderate (5-15%)', 'Large (>15%)'};
    counts = [noImprovement, smallImprovement, moderateImprovement, largeImprovement];
    colors = [0.8 0.8 0.8; 0.9 0.9 0.4; 0.4 0.8 0.4; 0.2 0.7 0.2];
    
    b = bar(counts, 'FaceColor', 'flat');
    for i = 1:length(colors)
        b.CData(i,:) = colors(i,:);
    end
    
    set(gca, 'XTickLabel', categories, 'FontSize', 11);
    title('Local Search Improvement Categories', 'FontSize', 14, 'FontWeight', 'bold');
    ylabel('Number of Runs', 'FontSize', 12);
    grid on;
    
    % Add percentage labels
    for i = 1:length(counts)
        if counts(i) > 0
            text(i, counts(i) + max(counts)*0.02, sprintf('%d\n(%.1f%%)', counts(i), 100*counts(i)/validRuns), ...
                 'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
        end
    end
    
    saveAnalysisPlot(gcf, 'phases', 'improvement_categories', timestamp);
    
    fprintf('Phase analysis plots saved in: plots/phases/\n');
    
    % Save results to file
    resultsFilename = sprintf('results/phase_analysis_results_%s.mat', timestamp);
    save(resultsFilename, 'phaseResults');
    fprintf('Phase analysis results saved as: %s\n', resultsFilename);
end