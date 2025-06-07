function createParameterAnalysisPlots(results, timestamp)
% Create comprehensive parameter analysis plots for GA tuning

    fprintf('Creating parameter analysis plots...\n');
    
    % Create plots directory if it doesn't exist
    if ~exist('plots/parameters', 'dir')
        mkdir('plots/parameters');
    end
    
    % Extract data
    popSizes = [results.popSize];
    mutRates = [results.mutRate];
    eliteCounts = [results.eliteCount];
    avgObjectives = [results.avgObjective];
    minObjectives = [results.minObjective];
    stdObjectives = [results.stdObjective];
    successRates = [results.successRate];
    
    % Get unique parameter values
    uniquePopSizes = unique(popSizes);
    uniqueMutRates = unique(mutRates);
    uniqueEliteCounts = unique(eliteCounts);
    
    %% 1. 3D scatter plot of parameter performance
    figure('Position', [100, 100, 1200, 800]);
    
    % Color by average objective (lower is better)
    scatter3(popSizes, mutRates, eliteCounts, 100, avgObjectives, 'filled');
    colorbar;
    colormap('jet');
    xlabel('Population Size');
    ylabel('Mutation Rate');
    zlabel('Elite Count');
    title('GA Parameter Space - Average Objective');
    grid on;
    view(45, 30);
    
    saveas(gcf, sprintf('plots/parameters/parameter_space_3d_%s.png', timestamp));
    close(gcf);
    
    %% 2. Heatmaps for each parameter pair
    % Population Size vs Mutation Rate
    figure('Position', [100, 100, 800, 600]);
    createHeatmap(popSizes, mutRates, avgObjectives, uniquePopSizes, uniqueMutRates, ...
        'Population Size', 'Mutation Rate', 'Avg Objective by PopSize and MutRate');
    saveas(gcf, sprintf('plots/parameters/heatmap_popsize_mutrate_%s.png', timestamp));
    close(gcf);
    
    % Population Size vs Elite Count
    figure('Position', [100, 100, 800, 600]);
    createHeatmap(popSizes, eliteCounts, avgObjectives, uniquePopSizes, uniqueEliteCounts, ...
        'Population Size', 'Elite Count', 'Avg Objective by PopSize and EliteCount');
    saveas(gcf, sprintf('plots/parameters/heatmap_popsize_elitecount_%s.png', timestamp));
    close(gcf);
    
    % Mutation Rate vs Elite Count
    figure('Position', [100, 100, 800, 600]);
    createHeatmap(mutRates, eliteCounts, avgObjectives, uniqueMutRates, uniqueEliteCounts, ...
        'Mutation Rate', 'Elite Count', 'Avg Objective by MutRate and EliteCount');
    saveas(gcf, sprintf('plots/parameters/heatmap_mutrate_elitecount_%s.png', timestamp));
    close(gcf);
    
    %% 3. Box plots for each parameter
    % Population Size effect
    figure('Position', [100, 100, 800, 600]);
    boxplot(avgObjectives, popSizes);
    xlabel('Population Size');
    ylabel('Average Objective');
    title('Effect of Population Size');
    grid on;
    saveas(gcf, sprintf('plots/parameters/boxplot_popsize_%s.png', timestamp));
    close(gcf);
    
    % Mutation Rate effect
    figure('Position', [100, 100, 800, 600]);
    boxplot(avgObjectives, mutRates);
    xlabel('Mutation Rate');
    ylabel('Average Objective');
    title('Effect of Mutation Rate');
    grid on;
    saveas(gcf, sprintf('plots/parameters/boxplot_mutrate_%s.png', timestamp));
    close(gcf);
    
    % Elite Count effect
    figure('Position', [100, 100, 800, 600]);
    boxplot(avgObjectives, eliteCounts);
    xlabel('Elite Count');
    ylabel('Average Objective');
    title('Effect of Elite Count');
    grid on;
    saveas(gcf, sprintf('plots/parameters/boxplot_elitecount_%s.png', timestamp));
    close(gcf);
    
    %% 4. Performance vs Stability trade-off
    figure('Position', [100, 100, 1000, 800]);
    
    % Remove NaN values
    validIdx = ~isnan(stdObjectives) & ~isnan(avgObjectives);
    
    scatter(avgObjectives(validIdx), stdObjectives(validIdx), 100, 'filled');
    xlabel('Average Objective');
    ylabel('Standard Deviation');
    title('Performance vs Stability Trade-off');
    grid on;
    
    % Add labels for best configurations
    [~, bestAvgIdx] = min(avgObjectives);
    [~, bestStableIdx] = min(stdObjectives(validIdx));
    
    hold on;
    scatter(avgObjectives(bestAvgIdx), stdObjectives(bestAvgIdx), 200, 'r', 'filled');
    text(avgObjectives(bestAvgIdx), stdObjectives(bestAvgIdx), '  Best Avg', ...
        'FontSize', 10, 'Color', 'r');
    
    validStdObj = stdObjectives(validIdx);
    validAvgObj = avgObjectives(validIdx);
    scatter(validAvgObj(bestStableIdx), validStdObj(bestStableIdx), 200, 'g', 'filled');
    text(validAvgObj(bestStableIdx), validStdObj(bestStableIdx), '  Most Stable', ...
        'FontSize', 10, 'Color', 'g');
    
    saveas(gcf, sprintf('plots/parameters/performance_stability_%s.png', timestamp));
    close(gcf);
    
    %% 5. Parameter importance analysis
    % Calculate correlation with performance
    corrPop = corr(popSizes', avgObjectives');
    corrMut = corr(mutRates', avgObjectives');
    corrElite = corr(eliteCounts', avgObjectives');
    
    % Parameter importance bar chart
    figure('Position', [100, 100, 800, 600]);
    bar([abs(corrPop), abs(corrMut), abs(corrElite)]);
    set(gca, 'XTickLabel', {'Population Size', 'Mutation Rate', 'Elite Count'});
    ylabel('Absolute Correlation with Objective');
    title('Parameter Importance');
    grid on;
    saveas(gcf, sprintf('plots/parameters/parameter_importance_%s.png', timestamp));
    close(gcf);
    
    % Top configurations table
    figure('Position', [100, 100, 800, 600]);
    axis off;
    
    % Find top 5 configurations
    [~, sortIdx] = sort(avgObjectives);
    topConfigs = sortIdx(1:min(5, length(sortIdx)));
    
    tableData = cell(6, 5);
    tableData(1, :) = {'Rank', 'Pop Size', 'Mut Rate', 'Elite Count', 'Avg Objective'};
    for i = 1:length(topConfigs)
        idx = topConfigs(i);
        tableData{i+1, 1} = num2str(i);
        tableData{i+1, 2} = num2str(popSizes(idx));
        tableData{i+1, 3} = sprintf('%.2f', mutRates(idx));
        tableData{i+1, 4} = num2str(eliteCounts(idx));
        tableData{i+1, 5} = sprintf('%.4f', avgObjectives(idx));
    end
    
    text(0.1, 0.9, 'Top 5 Parameter Configurations', 'FontSize', 14, 'FontWeight', 'bold');
    for i = 1:size(tableData, 1)
        for j = 1:size(tableData, 2)
            text(0.1 + (j-1)*0.18, 0.8 - i*0.1, tableData{i, j}, 'FontSize', 10);
        end
    end
    
    saveas(gcf, sprintf('plots/parameters/top_configurations_%s.png', timestamp));
    close(gcf);
    
    fprintf('Parameter analysis plots created successfully.\n');
end

function createHeatmap(x, y, z, uniqueX, uniqueY, xLabel, yLabel, titleStr)
    % Create a heatmap for parameter pairs
    
    % Create grid
    heatmapData = zeros(length(uniqueY), length(uniqueX));
    countData = zeros(length(uniqueY), length(uniqueX));
    
    % Fill grid with average values
    for i = 1:length(x)
        xIdx = find(uniqueX == x(i));
        yIdx = find(uniqueY == y(i));
        heatmapData(yIdx, xIdx) = heatmapData(yIdx, xIdx) + z(i);
        countData(yIdx, xIdx) = countData(yIdx, xIdx) + 1;
    end
    
    % Average the values
    heatmapData = heatmapData ./ max(countData, 1);
    
    % Create heatmap
    imagesc(uniqueX, uniqueY, heatmapData);
    colorbar;
    xlabel(xLabel);
    ylabel(yLabel);
    title(titleStr);
    
    % Add value labels
    for i = 1:length(uniqueY)
        for j = 1:length(uniqueX)
            if countData(i, j) > 0
                text(uniqueX(j), uniqueY(i), sprintf('%.3f', heatmapData(i, j)), ...
                    'HorizontalAlignment', 'center', 'FontSize', 8);
            end
        end
    end
end