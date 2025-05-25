function plot_grasp_vs_ga()
% Plot comparison of GRASP vs GA average shortest path results
% Loads objective values from GA_results.mat and GRASP_results.mat
% and plots them across 10 runs

% Load GRASP results
try
    grasp_data = load('GRASP\results\GRASP_results.mat');
    
    % Look for arrays with 10 values (the 10 runs)
    if isfield(grasp_data, 'allResults') && length(grasp_data.allResults) == 10
        % Extract avgSP from each run
        grasp_objectives = zeros(1, 10);
        for i = 1:10
            grasp_objectives(i) = grasp_data.allResults(i).avgSP;
        end
    end
    
catch ME
    fprintf('Error: %s\n', ME.message);
    error('Could not load GRASP_results.mat properly.');
end

% Load GA results
try
    ga_data = load('GA\results\GA_results.mat');

    % Look for arrays with 10 values (the 10 runs)
    if isfield(ga_data, 'allResults') && length(ga_data.allResults) == 10
        % Extract objective from each run
        ga_objectives = zeros(1, 10);
        for i = 1:10
            ga_objectives(i) = ga_data.allResults(i).objective;
        end
    end
    
catch ME
    fprintf('Error: %s\n', ME.message);
    error('Could not load GA_results.mat properly.');
end

% Create run numbers (1 to 10)
run_numbers = 1:10;

% Create the figure
figure('Position', [100, 100, 800, 600]);

% Plot GRASP results (red line)
plot(run_numbers, grasp_objectives, 'r-', 'LineWidth', 2, 'Marker', 'o', 'MarkerSize', 6);
hold on;

% Plot GA results (blue line)
plot(run_numbers, ga_objectives, 'b-', 'LineWidth', 2, 'Marker', 's', 'MarkerSize', 6);

% Customize the plot
xlabel('Run number', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Average Shortest Path Length', 'FontSize', 12, 'FontWeight', 'bold');
title('GRASP vs GA', 'FontSize', 14, 'FontWeight', 'bold');

% Add legend
legend({'GRASP', 'GA'}, 'Location', 'best', 'FontSize', 11);

% Set axis properties
grid on;
grid minor;
set(gca, 'FontSize', 10);

% Set x-axis limits and ticks
xlim([0, 11]);
xticks(0:1:10);

% Adjust y-axis to show the data clearly
y_min = min([grasp_objectives, ga_objectives]) - 5;
y_max = max([grasp_objectives, ga_objectives]) + 5;
ylim([y_min, y_max]);

% Add subtitle with performance statistics
subtitle_text = sprintf('GRASP vs GA');

% Add subtitle below the plot
text(5.5, y_min + 0.1*(y_max-y_min), subtitle_text, ...
    'HorizontalAlignment', 'center', 'FontSize', 10, ...
    'BackgroundColor', 'white', 'EdgeColor', 'black');

% Save the figure
saveas(gcf, 'plots/GRASP_vs_GA_comparison.png');
saveas(gcf, 'plots/GRASP_vs_GA_comparison.fig');

fprintf('\nPlot saved as: GRASP_vs_GA_comparison.png and .fig\n');

end