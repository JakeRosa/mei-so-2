function createConvergencePlot(results, runNumber, timestamp)
% Create convergence plot for a single GA run

    % Create plots directory if it doesn't exist
    if ~exist('plots/convergence', 'dir')
        mkdir('plots/convergence');
    end
    
    % Extract data
    generations = results.generations;
    objectives = results.objectives;
    avgFitness = results.avgFitness;
    bestFitness = results.bestFitness;
    times = results.times;
    
    if isempty(generations)
        return;
    end
    
    % Plot 1: Objective value over generations
    figure('Position', [100, 100, 800, 600]);
    plot(generations, objectives, 'b-', 'LineWidth', 2);
    xlabel('Generation');
    ylabel('Best Objective Value');
    title(sprintf('Best Solution Convergence - Run %d', runNumber));
    grid on;
    
    % Add markers for improvements
    improvements = [true, diff(objectives) < 0];
    improvementGens = generations(improvements);
    improvementObjs = objectives(improvements);
    hold on;
    plot(improvementGens, improvementObjs, 'ro', 'MarkerSize', 6);
    legend('Best Objective', 'Improvements', 'Location', 'best');
    saveas(gcf, sprintf('plots/convergence/objective_convergence_run_%d_%s.png', runNumber, timestamp));
    close(gcf);
    
    % Plot 2: Fitness evolution
    figure('Position', [100, 100, 800, 600]);
    plot(generations, avgFitness, 'g-', 'LineWidth', 1.5);
    hold on;
    plot(generations, bestFitness, 'b-', 'LineWidth', 1.5);
    xlabel('Generation');
    ylabel('Fitness Value');
    title(sprintf('Fitness Evolution - Run %d', runNumber));
    legend('Average Fitness', 'Best Fitness', 'Location', 'best');
    grid on;
    saveas(gcf, sprintf('plots/convergence/fitness_evolution_run_%d_%s.png', runNumber, timestamp));
    close(gcf);
    
    % Plot 3: Objective value over time
    figure('Position', [100, 100, 800, 600]);
    plot(times, objectives, 'r-', 'LineWidth', 2);
    xlabel('Time (seconds)');
    ylabel('Best Objective Value');
    title(sprintf('Convergence Over Time - Run %d', runNumber));
    grid on;
    saveas(gcf, sprintf('plots/convergence/time_convergence_run_%d_%s.png', runNumber, timestamp));
    close(gcf);
    
    % Plot 4: Generation progress
    if length(times) > 1
        figure('Position', [100, 100, 800, 600]);
        % Calculate generations per second
        genPerSec = generations ./ times;
        plot(times, genPerSec, 'm-', 'LineWidth', 1.5);
        xlabel('Time (seconds)');
        ylabel('Generations per Second');
        title(sprintf('GA Speed - Run %d', runNumber));
        grid on;
        
        % Add average line
        avgSpeed = mean(genPerSec);
        hold on;
        plot([times(1), times(end)], [avgSpeed, avgSpeed], 'k--', 'LineWidth', 1);
        text(mean(times), avgSpeed*1.05, sprintf('Avg: %.1f gen/s', avgSpeed), ...
            'HorizontalAlignment', 'center');
        saveas(gcf, sprintf('plots/convergence/ga_speed_run_%d_%s.png', runNumber, timestamp));
        close(gcf);
    end
    
    % Additional plots for optimized GA with cache statistics
    if isfield(results, 'cacheHitRate') && ~isempty(results.cacheHitRate)
        % Cache performance plot
        figure('Position', [100, 100, 800, 600]);
        plot(generations, results.cacheHitRate * 100, 'b-', 'LineWidth', 2);
        xlabel('Generation');
        ylabel('Cache Hit Rate (%)');
        title(sprintf('Cache Performance - Run %d', runNumber));
        grid on;
        ylim([0, 100]);
        saveas(gcf, sprintf('plots/convergence/cache_performance_run_%d_%s.png', runNumber, timestamp));
        close(gcf);
        
        % Diversity metrics plot
        if isfield(results, 'diversityMetrics') && ~isempty(results.diversityMetrics)
            figure('Position', [100, 100, 800, 600]);
            plot(generations, results.diversityMetrics, 'g-', 'LineWidth', 2);
            xlabel('Generation');
            ylabel('Population Diversity');
            title(sprintf('Genetic Diversity - Run %d', runNumber));
            grid on;
            ylim([0, 1]);
            saveas(gcf, sprintf('plots/convergence/diversity_metrics_run_%d_%s.png', runNumber, timestamp));
            close(gcf);
        end
    end
end