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
    
end