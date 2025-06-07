function createGASummaryPlots(allResults, timestamp)
% Create summary plots for GA execution results

    fprintf('Creating GA summary plots...\n');
    
    % Create plots directory if it doesn't exist
    if ~exist('plots/summary', 'dir')
        mkdir('plots/summary');
    end
    
    % Extract data
    objectives = [allResults.objective];
    maxSPs = [allResults.maxSP];
    validRuns = [allResults.valid];
    runTimes = [allResults.runTime];
    
    % Filter valid results
    validObjectives = objectives(validRuns);
    validMaxSPs = maxSPs(validRuns);
    validRunTimes = runTimes(validRuns);
    validIndices = find(validRuns);
    
    %% Main summary plots
    % Plot 1: Objective values across runs
    figure('Position', [100, 100, 800, 600]);
    bar(1:length(objectives), objectives);
    hold on;
    
    % Mark invalid runs
    invalidIndices = find(~validRuns);
    if ~isempty(invalidIndices)
        bar(invalidIndices, objectives(invalidIndices), 'r');
    end
    
    % Add average line
    if ~isempty(validObjectives)
        avgObj = mean(validObjectives);
        plot([0.5, length(objectives)+0.5], [avgObj, avgObj], 'g--', 'LineWidth', 2);
        text(length(objectives)/2, avgObj*1.05, sprintf('Avg: %.4f', avgObj), ...
            'HorizontalAlignment', 'center', 'Color', 'g');
    end
    
    xlabel('Run Number');
    ylabel('Objective Value');
    title('GA Objective Values by Run');
    legend('Valid', 'Invalid', 'Average', 'Location', 'best');
    grid on;
    saveas(gcf, sprintf('plots/summary/objective_values_%s.png', timestamp));
    close(gcf);
    
    % Plot 2: Max shortest path values
    figure('Position', [100, 100, 800, 600]);
    bar(1:length(maxSPs), maxSPs);
    hold on;
    
    % Add constraint line
    Cmax = 1000;  % Get from config if available
    plot([0.5, length(maxSPs)+0.5], [Cmax, Cmax], 'r--', 'LineWidth', 2);
    text(length(maxSPs)/2, Cmax*1.05, 'Constraint (Cmax)', ...
        'HorizontalAlignment', 'center', 'Color', 'r');
    
    xlabel('Run Number');
    ylabel('Max Shortest Path');
    title('Maximum Shortest Path by Run');
    grid on;
    saveas(gcf, sprintf('plots/summary/max_shortest_path_%s.png', timestamp));
    close(gcf);
    
    % Add average line
    avgTime = mean(runTimes);
    hold on;
    plot([0.5, length(runTimes)+0.5], [avgTime, avgTime], 'g--', 'LineWidth', 2);
    text(length(runTimes)/2, avgTime*1.05, sprintf('Avg: %.1fs', avgTime), ...
        'HorizontalAlignment', 'center', 'Color', 'g');
    saveas(gcf, sprintf('plots/summary/runtime_analysis_%s.png', timestamp));
    close(gcf);
    
    % Plot 4: Objective distribution
    if ~isempty(validObjectives)
        figure('Position', [100, 100, 800, 600]);
        histogram(validObjectives, 'BinMethod', 'auto');
        xlabel('Objective Value');
        ylabel('Frequency');
        title('Distribution of Valid GA Objectives');
        grid on;
        
        % Add statistics
        text(0.05, 0.95, sprintf('Mean: %.4f', mean(validObjectives)), ...
            'Units', 'normalized', 'VerticalAlignment', 'top');
        text(0.05, 0.88, sprintf('Std: %.4f', std(validObjectives)), ...
            'Units', 'normalized', 'VerticalAlignment', 'top');
        text(0.05, 0.81, sprintf('Min: %.4f', min(validObjectives)), ...
            'Units', 'normalized', 'VerticalAlignment', 'top');
        text(0.05, 0.74, sprintf('Max: %.4f', max(validObjectives)), ...
            'Units', 'normalized', 'VerticalAlignment', 'top');
        saveas(gcf, sprintf('plots/summary/objective_distribution_%s.png', timestamp));
        close(gcf);
    end
    
    % Plot 5: Convergence summary
    if ~isempty(validIndices)
        figure('Position', [100, 100, 800, 600]);
        
        % Extract final generation counts
        finalGenerations = zeros(length(validIndices), 1);
        for i = 1:length(validIndices)
            idx = validIndices(i);
            if isfield(allResults(idx).runResults, 'generations')
                gens = allResults(idx).runResults.generations;
                if ~isempty(gens)
                    finalGenerations(i) = gens(end);
                end
            end
        end
        
        if any(finalGenerations > 0)
            scatter(finalGenerations, validObjectives, 50, 'filled');
            xlabel('Final Generation');
            ylabel('Final Objective');
            title('Generations vs Solution Quality');
            grid on;
            
            % Add trend line
            if length(finalGenerations) > 2
                p = polyfit(finalGenerations(finalGenerations > 0), ...
                    validObjectives(finalGenerations > 0), 1);
                hold on;
                x = linspace(min(finalGenerations), max(finalGenerations), 100);
                plot(x, polyval(p, x), 'r--', 'LineWidth', 1.5);
            end
            saveas(gcf, sprintf('plots/summary/generations_vs_quality_%s.png', timestamp));
            close(gcf);
        end
    end
    
    % Plot 6: Success rate and statistics summary
    figure('Position', [100, 100, 800, 600]);
    axis off;
    
    % Calculate statistics
    numRuns = length(allResults);
    numValid = sum(validRuns);
    successRate = numValid / numRuns * 100;
    
    % Display summary statistics
    textY = 0.9;
    textStep = 0.08;
    
    text(0.5, textY, 'GA EXECUTION SUMMARY', 'FontSize', 14, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center');
    textY = textY - 2*textStep;
    
    text(0.1, textY, sprintf('Total runs: %d', numRuns), 'FontSize', 11);
    textY = textY - textStep;
    
    text(0.1, textY, sprintf('Valid runs: %d (%.1f%%)', numValid, successRate), 'FontSize', 11);
    textY = textY - textStep;
    
    if ~isempty(validObjectives)
        text(0.1, textY, sprintf('Best objective: %.4f', min(validObjectives)), 'FontSize', 11);
        textY = textY - textStep;
        
        text(0.1, textY, sprintf('Average objective: %.4f ± %.4f', ...
            mean(validObjectives), std(validObjectives)), 'FontSize', 11);
        textY = textY - textStep;
        
        text(0.1, textY, sprintf('Worst objective: %.4f', max(validObjectives)), 'FontSize', 11);
        textY = textY - textStep;
    end
    
    text(0.1, textY, sprintf('Average runtime: %.1f seconds', mean(runTimes)), 'FontSize', 11);
    textY = textY - textStep;
    
    % Add timestamp
    text(0.1, 0.1, sprintf('Generated: %s', timestamp), 'FontSize', 9, 'Color', [0.5, 0.5, 0.5]);
    
    saveas(gcf, sprintf('plots/summary/statistics_summary_%s.png', timestamp));
    close(gcf);
    
    %% Additional quality analysis plots
    if ~isempty(validObjectives) && length(validObjectives) > 1
        % Box plot of objectives
        figure('Position', [100, 100, 800, 600]);
        boxplot(validObjectives);
        ylabel('Objective Value');
        title('GA Objective Value Distribution');
        grid on;
        saveas(gcf, sprintf('plots/summary/objective_boxplot_%s.png', timestamp));
        close(gcf);
        
        % Objective vs MaxSP scatter
        figure('Position', [100, 100, 800, 600]);
        scatter(validMaxSPs, validObjectives, 50, 'filled');
        xlabel('Max Shortest Path');
        ylabel('Objective Value');
        title('Objective vs Max Shortest Path');
        grid on;
        
        % Add trend line if enough points
        if length(validObjectives) > 2
            p = polyfit(validMaxSPs, validObjectives, 1);
            hold on;
            x = linspace(min(validMaxSPs), max(validMaxSPs), 100);
            plot(x, polyval(p, x), 'r--', 'LineWidth', 1.5);
            
            % Calculate correlation
            r = corr(validMaxSPs', validObjectives');
            text(0.05, 0.95, sprintf('Correlation: %.3f', r), ...
                'Units', 'normalized', 'VerticalAlignment', 'top');
        end
        saveas(gcf, sprintf('plots/summary/objective_vs_maxsp_%s.png', timestamp));
        close(gcf);
        
        % Cumulative best objective
        figure('Position', [100, 100, 800, 600]);
        cumBest = zeros(length(validObjectives), 1);
        cumBest(1) = validObjectives(1);
        for i = 2:length(validObjectives)
            cumBest(i) = min(cumBest(i-1), validObjectives(i));
        end
        
        plot(validIndices, cumBest, 'b-', 'LineWidth', 2);
        xlabel('Run Number');
        ylabel('Best Objective So Far');
        title('Cumulative Best Solution');
        grid on;
        saveas(gcf, sprintf('plots/summary/cumulative_best_%s.png', timestamp));
        close(gcf);
    end
    
    fprintf('GA summary plots created successfully.\n');
end