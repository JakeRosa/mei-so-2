function plot_algorithms_comparison_bar()
% Plot bar chart comparison of max, average, and min values for all algorithms
% Reads from metadata CSV files and ILP results

% Algorithm names
algorithms = {'GRASP Default', 'GRASP Optimized', 'GA Default', 'GA Optimized', 'ILP'};

% Read GRASP Default metadata
grasp_default_meta = readtable('GRASP/results/GRASP default/GRASP_metadata.csv');
% Extract values from Parameter/Value structure
best_idx = strcmp(grasp_default_meta.Parameter, 'Best_Overall');
avg_idx = strcmp(grasp_default_meta.Parameter, 'Average_Overall');
worst_idx = strcmp(grasp_default_meta.Parameter, 'Worst_Overall');
grasp_default_min = grasp_default_meta.Value(best_idx);
grasp_default_avg = grasp_default_meta.Value(avg_idx);
grasp_default_max = grasp_default_meta.Value(worst_idx);

% Read GRASP Optimized metadata
grasp_opt_meta = readtable('GRASP/results/GRASP Optimized/GRASP_Optimized_metadata.csv');
% Extract values from Parameter/Value structure
best_idx = strcmp(grasp_opt_meta.Parameter, 'Best_Overall');
avg_idx = strcmp(grasp_opt_meta.Parameter, 'Average_Overall');
worst_idx = strcmp(grasp_opt_meta.Parameter, 'Worst_Overall');
grasp_opt_min = grasp_opt_meta.Value(best_idx);
grasp_opt_avg = grasp_opt_meta.Value(avg_idx);
grasp_opt_max = grasp_opt_meta.Value(worst_idx);

% Read GA Default data from summary
ga_default_summary = readtable('GA/results/GA Default/GA_summary.csv');
ga_default_objectives = ga_default_summary.Objective;
ga_default_min = min(ga_default_objectives);
ga_default_avg = mean(ga_default_objectives);
ga_default_max = max(ga_default_objectives);

% Read GA Optimized data from summary
ga_opt_summary = readtable('GA/results/GA Optimized/GA_Optimized_summary.csv');
ga_opt_objectives = ga_opt_summary.Objective;
ga_opt_min = min(ga_opt_objectives);
ga_opt_avg = mean(ga_opt_objectives);
ga_opt_max = max(ga_opt_objectives);

% ILP results (hardcoded from results.txt as it's a single run)
ilp_avg = 145.085;  % From the ILP results.txt file

% Prepare data for plotting
min_values = [grasp_default_min, grasp_opt_min, ga_default_min, ga_opt_min, NaN];
avg_values = [grasp_default_avg, grasp_opt_avg, ga_default_avg, ga_opt_avg, ilp_avg];
max_values = [grasp_default_max, grasp_opt_max, ga_default_max, ga_opt_max, NaN];

% Create figure
figure('Position', [100, 100, 1000, 700]);

% Create grouped bar chart
x = 1:length(algorithms);
width = 0.25;

% Plot bars
bar(x - width, min_values, width, 'FaceColor', [0.2 0.6 0.2], 'EdgeColor', 'black', 'LineWidth', 1.5);
hold on;
bar(x, avg_values, width, 'FaceColor', [0.2 0.4 0.8], 'EdgeColor', 'black', 'LineWidth', 1.5);
bar(x + width, max_values, width, 'FaceColor', [0.8 0.2 0.2], 'EdgeColor', 'black', 'LineWidth', 1.5);

% Customize the plot
xlabel('Algorithm', 'FontSize', 14, 'FontWeight', 'bold');
ylabel('Average Shortest Path Length', 'FontSize', 14, 'FontWeight', 'bold');
title('Algorithm Performance Comparison', 'FontSize', 16, 'FontWeight', 'bold');

% Set x-axis labels
set(gca, 'XTick', x);
set(gca, 'XTickLabel', algorithms);
xtickangle(45);

% Add legend
legend({'Minimum', 'Average', 'Maximum'}, 'Location', 'northwest', 'FontSize', 12);

% Add grid
grid on;
grid minor;
set(gca, 'FontSize', 11);

% Add value labels on top of bars
for i = 1:length(algorithms)
    % Check if all values are the same (like GRASP Optimized)
    if ~isnan(min_values(i)) && ~isnan(max_values(i)) && ...
       abs(min_values(i) - avg_values(i)) < 0.001 && abs(max_values(i) - avg_values(i)) < 0.001
        % All values are the same, show only one label centered
        text(i, avg_values(i) + 0.5, sprintf('%.2f', avg_values(i)), ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
            'FontSize', 9, 'FontWeight', 'bold');
    else
        % Min value label (skip if NaN)
        if ~isnan(min_values(i))
            text(i - width, min_values(i) + 0.5, sprintf('%.2f', min_values(i)), ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
                'FontSize', 9, 'FontWeight', 'bold');
        end
        
        % Avg value label
        text(i, avg_values(i) + 0.5, sprintf('%.2f', avg_values(i)), ...
            'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
            'FontSize', 9, 'FontWeight', 'bold');
        
        % Max value label (skip if NaN)
        if ~isnan(max_values(i))
            text(i + width, max_values(i) + 0.5, sprintf('%.2f', max_values(i)), ...
                'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', ...
                'FontSize', 9, 'FontWeight', 'bold');
        end
    end
end

% Adjust y-axis limits
y_min = min([min_values, avg_values, max_values]) - 2;
y_max = max([min_values, avg_values, max_values]) + 5;
ylim([y_min, y_max]);

% Add a horizontal line at the best value found
best_value = min([min_values, avg_values, max_values]);
line([0.5, length(algorithms) + 0.5], [best_value, best_value], ...
    'Color', 'green', 'LineStyle', '--', 'LineWidth', 2);
text(length(algorithms) + 0.3, best_value, sprintf('Best: %.2f', best_value), ...
    'VerticalAlignment', 'middle', 'FontSize', 10, 'Color', 'green', 'FontWeight', 'bold');

% Save the figure
saveas(gcf, 'plots/algorithms_comparison_bar.png');
saveas(gcf, 'plots/algorithms_comparison_bar.fig');

fprintf('\nBar plot saved as: algorithms_comparison_bar.png and .fig\n');
fprintf('\nSummary Statistics:\n');
fprintf('%-20s %10s %10s %10s\n', 'Algorithm', 'Min', 'Average', 'Max');
fprintf('%-20s %10.3f %10.3f %10.3f\n', 'GRASP Default', grasp_default_min, grasp_default_avg, grasp_default_max);
fprintf('%-20s %10.3f %10.3f %10.3f\n', 'GRASP Optimized', grasp_opt_min, grasp_opt_avg, grasp_opt_max);
fprintf('%-20s %10.3f %10.3f %10.3f\n', 'GA Default', ga_default_min, ga_default_avg, ga_default_max);
fprintf('%-20s %10.3f %10.3f %10.3f\n', 'GA Optimized', ga_opt_min, ga_opt_avg, ga_opt_max);
fprintf('%-20s %10s %10.3f %10s\n', 'ILP', '-', ilp_avg, '-');

end