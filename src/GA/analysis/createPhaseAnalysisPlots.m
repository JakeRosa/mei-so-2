function createPhaseAnalysisPlots(allResults, timestamp)
% Create detailed phase analysis plots for GA operations

    fprintf('Creating GA phase analysis plots...\n');
    
    % Create plots directory if it doesn't exist
    if ~exist('plots/phases', 'dir')
        mkdir('plots/phases');
    end
    
    % Extract valid results
    validResults = allResults([allResults.valid]);
    
    if isempty(validResults)
        fprintf('No valid results for phase analysis.\n');
        return;
    end
    
    %% Plot 1: Convergence patterns
    figure('Position', [100, 100, 800, 600]);
    for i = 1:min(5, length(validResults))
        if isfield(validResults(i).runResults, 'objectives')
            objectives = validResults(i).runResults.objectives;
            generations = validResults(i).runResults.generations;
            
            % Normalize to show relative improvement
            if ~isempty(objectives) && objectives(1) > 0
                normalizedObj = objectives / objectives(1);
                plot(generations, normalizedObj, '-', 'LineWidth', 1.5);
                hold on;
            end
        end
    end
    xlabel('Generation');
    ylabel('Normalized Objective');
    title('GA Convergence Patterns (First 5 Runs)');
    legend(arrayfun(@(x) sprintf('Run %d', x), 1:min(5, length(validResults)), ...
        'UniformOutput', false), 'Location', 'best');
    grid on;
    saveas(gcf, sprintf('plots/phases/convergence_patterns_%s.png', timestamp));
    close(gcf);
    
    %% Plot 2: Fitness evolution analysis
    figure('Position', [100, 100, 800, 600]);
    avgFitnessEvolution = [];
    for i = 1:length(validResults)
        if isfield(validResults(i).runResults, 'avgFitness')
            avgFit = validResults(i).runResults.avgFitness;
            if i == 1
                avgFitnessEvolution = avgFit;
            else
                % Align by padding or truncating
                maxLen = max(length(avgFitnessEvolution), length(avgFit));
                if size(avgFitnessEvolution, 2) < maxLen
                    avgFitnessEvolution(:, end+1:maxLen) = NaN;
                end
                if length(avgFit) < maxLen
                    avgFit(end+1:maxLen) = NaN;
                end
                avgFitnessEvolution(i, :) = avgFit;
            end
        end
    end
    
    if ~isempty(avgFitnessEvolution)
        meanFitness = nanmean(avgFitnessEvolution, 1);
        stdFitness = nanstd(avgFitnessEvolution, 1);
        generations = 1:length(meanFitness);
        
        plot(generations, meanFitness, 'b-', 'LineWidth', 2);
        hold on;
        fill([generations, fliplr(generations)], ...
            [meanFitness + stdFitness, fliplr(meanFitness - stdFitness)], ...
            'b', 'FaceAlpha', 0.3, 'EdgeColor', 'none');
        
        xlabel('Generation');
        ylabel('Average Fitness');
        title('Population Fitness Evolution');
        grid on;
        saveas(gcf, sprintf('plots/phases/fitness_evolution_%s.png', timestamp));
        close(gcf);
    end
    
    %% Plot 3: Improvement frequency
    figure('Position', [100, 100, 800, 600]);
    improvementData = [];
    maxGens = 0;
    for i = 1:length(validResults)
        if isfield(validResults(i).runResults, 'objectives')
            objectives = validResults(i).runResults.objectives;
            if length(objectives) > 1
                improvements = [false, diff(objectives) < 0];
                maxGens = max(maxGens, length(improvements));
            end
        end
    end
    
    % Create improvement matrix
    improvementMatrix = zeros(length(validResults), maxGens);
    for i = 1:length(validResults)
        if isfield(validResults(i).runResults, 'objectives')
            objectives = validResults(i).runResults.objectives;
            if length(objectives) > 1
                improvements = [false, diff(objectives) < 0];
                improvementMatrix(i, 1:length(improvements)) = improvements;
            end
        end
    end
    
    if maxGens > 0
        improvementRate = sum(improvementMatrix, 1) / length(validResults);
        bar(improvementRate);
        xlabel('Generation');
        ylabel('Improvement Frequency');
        title('Probability of Improvement by Generation');
        grid on;
        saveas(gcf, sprintf('plots/phases/improvement_frequency_%s.png', timestamp));
        close(gcf);
    end
    
    %% Plot 4: Diversity analysis (if available)
    if any(arrayfun(@(r) isfield(r.runResults, 'diversityMetrics'), validResults))
        figure('Position', [100, 100, 800, 600]);
        for i = 1:min(5, length(validResults))
            if isfield(validResults(i).runResults, 'diversityMetrics')
                diversity = validResults(i).runResults.diversityMetrics;
                generations = validResults(i).runResults.generations;
                
                plot(generations, diversity, '-', 'LineWidth', 1.5);
                hold on;
            end
        end
        xlabel('Generation');
        ylabel('Population Diversity');
        title('Genetic Diversity Over Time');
        legend(arrayfun(@(x) sprintf('Run %d', x), 1:min(5, length(validResults)), ...
            'UniformOutput', false), 'Location', 'best');
        grid on;
        saveas(gcf, sprintf('plots/phases/diversity_evolution_%s.png', timestamp));
        close(gcf);
    end
    
    %% Plot 5: Cache performance (for optimized GA)
    if any(arrayfun(@(r) isfield(r.runResults, 'cacheHitRate'), validResults))
        figure('Position', [100, 100, 800, 600]);
        cacheData = [];
        for i = 1:length(validResults)
            if isfield(validResults(i).runResults, 'cacheHitRate')
                cacheData(i) = validResults(i).runResults.finalCacheHitRate * 100;
            end
        end
        
        if ~isempty(cacheData)
            bar(cacheData);
            xlabel('Run Number');
            ylabel('Cache Hit Rate (%)');
            title('Cache Performance by Run');
            grid on;
            
            % Add average line
            avgCache = mean(cacheData);
            hold on;
            plot([0.5, length(cacheData)+0.5], [avgCache, avgCache], 'r--', 'LineWidth', 2);
            text(length(cacheData)/2, avgCache*1.05, sprintf('Avg: %.1f%%', avgCache), ...
                'HorizontalAlignment', 'center', 'Color', 'r');
            saveas(gcf, sprintf('plots/phases/cache_performance_%s.png', timestamp));
            close(gcf);
        end
    end
    
    %% Plot 6: Early vs Late generation performance
    figure('Position', [100, 100, 800, 600]);
    earlyGens = [];
    lateGens = [];
    
    for i = 1:length(validResults)
        if isfield(validResults(i).runResults, 'objectives')
            objectives = validResults(i).runResults.objectives;
            if length(objectives) >= 20
                earlyGens = [earlyGens, mean(objectives(1:10))];
                lateGens = [lateGens, mean(objectives(end-9:end))];
            end
        end
    end
    
    if ~isempty(earlyGens) && ~isempty(lateGens)
        data = [earlyGens', lateGens'];
        boxplot(data, {'Early (1-10)', 'Late (last 10)'});
        ylabel('Average Objective');
        title('Early vs Late Generation Performance');
        grid on;
        saveas(gcf, sprintf('plots/phases/early_vs_late_performance_%s.png', timestamp));
        close(gcf);
    end
    
    %% Plot 7: Convergence speed analysis
    figure('Position', [100, 100, 800, 600]);
    convergenceSpeeds = [];
    
    for i = 1:length(validResults)
        if isfield(validResults(i).runResults, 'objectives') && ...
           isfield(validResults(i).runResults, 'times')
            objectives = validResults(i).runResults.objectives;
            times = validResults(i).runResults.times;
            
            if length(objectives) > 1 && length(times) > 1
                % Find 90% convergence point
                initialObj = objectives(1);
                finalObj = objectives(end);
                target = initialObj - 0.9 * (initialObj - finalObj);
                
                idx = find(objectives <= target, 1);
                if ~isempty(idx) && idx <= length(times)
                    convergenceSpeeds(end+1) = times(idx);
                end
            end
        end
    end
    
    if ~isempty(convergenceSpeeds)
        histogram(convergenceSpeeds, 'BinMethod', 'auto');
        xlabel('Time to 90% Convergence (seconds)');
        ylabel('Frequency');
        title('Convergence Speed Distribution');
        grid on;
        saveas(gcf, sprintf('plots/phases/convergence_speed_%s.png', timestamp));
        close(gcf);
    end
    
    %% Plot 8: Stagnation analysis
    figure('Position', [100, 100, 800, 600]);
    stagnationLengths = [];
    
    for i = 1:length(validResults)
        if isfield(validResults(i).runResults, 'objectives')
            objectives = validResults(i).runResults.objectives;
            
            if length(objectives) > 1
                % Find periods of no improvement
                improvements = [false, diff(objectives) < 0];
                stagnation = 0;
                maxStagnation = 0;
                
                for j = 1:length(improvements)
                    if ~improvements(j)
                        stagnation = stagnation + 1;
                        maxStagnation = max(maxStagnation, stagnation);
                    else
                        stagnation = 0;
                    end
                end
                
                stagnationLengths(end+1) = maxStagnation;
            end
        end
    end
    
    if ~isempty(stagnationLengths)
        bar(stagnationLengths);
        xlabel('Run Number');
        ylabel('Max Generations Without Improvement');
        title('Maximum Stagnation Period by Run');
        grid on;
        saveas(gcf, sprintf('plots/phases/stagnation_analysis_%s.png', timestamp));
        close(gcf);
    end
    
    %% Plot 9: Final improvement potential
    figure('Position', [100, 100, 800, 600]);
    improvementRatios = [];
    
    for i = 1:length(validResults)
        if isfield(validResults(i).runResults, 'objectives')
            objectives = validResults(i).runResults.objectives;
            
            if length(objectives) > 10
                % Compare last 10% to previous 10%
                n = length(objectives);
                early = mean(objectives(round(0.8*n):round(0.9*n)));
                late = mean(objectives(round(0.9*n):n));
                
                if early > 0
                    improvementRatios(end+1) = (early - late) / early * 100;
                end
            end
        end
    end
    
    if ~isempty(improvementRatios)
        bar(improvementRatios);
        xlabel('Run Number');
        ylabel('Improvement in Last 10% (%)');
        title('Late-Stage Improvement Potential');
        grid on;
        
        % Add zero line
        hold on;
        plot([0.5, length(improvementRatios)+0.5], [0, 0], 'k--', 'LineWidth', 1);
        saveas(gcf, sprintf('plots/phases/late_stage_improvement_%s.png', timestamp));
        close(gcf);
    end
    
    %% Summary statistics plot
    figure('Position', [100, 100, 800, 600]);
    axis off;
    
    % Display phase statistics
    textY = 0.9;
    textStep = 0.08;
    
    text(0.5, textY, 'GA PHASE ANALYSIS', 'FontSize', 14, 'FontWeight', 'bold', ...
        'HorizontalAlignment', 'center');
    textY = textY - 2*textStep;
    
    % Calculate average generations
    avgGenerations = mean(arrayfun(@(r) length(r.runResults.generations), validResults));
    text(0.1, textY, sprintf('Average generations: %.0f', avgGenerations), 'FontSize', 11);
    textY = textY - textStep;
    
    % Calculate improvement statistics
    totalImprovements = 0;
    totalGenerations = 0;
    for i = 1:length(validResults)
        if isfield(validResults(i).runResults, 'objectives')
            objectives = validResults(i).runResults.objectives;
            if length(objectives) > 1
                totalImprovements = totalImprovements + sum(diff(objectives) < 0);
                totalGenerations = totalGenerations + length(objectives) - 1;
            end
        end
    end
    
    if totalGenerations > 0
        improvementRate = totalImprovements / totalGenerations * 100;
        text(0.1, textY, sprintf('Overall improvement rate: %.1f%%', improvementRate), 'FontSize', 11);
        textY = textY - textStep;
    end
    
    % Display optimization statistics if available
    if any(arrayfun(@(r) isfield(r.runResults, 'totalEvaluations'), validResults))
        avgEvals = mean(arrayfun(@(r) r.runResults.totalEvaluations, ...
            validResults(arrayfun(@(r) isfield(r.runResults, 'totalEvaluations'), validResults))));
        text(0.1, textY, sprintf('Average evaluations: %.0f', avgEvals), 'FontSize', 11);
        textY = textY - textStep;
    end
    
    saveas(gcf, sprintf('plots/phases/phase_summary_%s.png', timestamp));
    close(gcf);
    
    fprintf('GA phase analysis plots created successfully.\n');
end