function plot_grasp_vs_ga()
% Plot comparison of all GRASP and GA variants from CSV summary files
% Reads from:
% - GRASP_summary.csv (default)
% - GRASP_Optimized_summary.csv
% - GA_summary.csv (default)
% - GA_Optimized_summary.csv

% Load GRASP Default results from CSV
try
    % Read as text first to parse properly
    fid = fopen('GRASP/results/GRASP default/GRASP_summary.csv', 'r');
    header = fgetl(fid);
    grasp_default_objectives = zeros(10, 1);
    
    for i = 1:10
        line = fgetl(fid);
        parts = strsplit(line, ',');
        % Column 2 is Final_avgSP
        grasp_default_objectives(i) = str2double(parts{2});
    end
    fclose(fid);
    
    fprintf('GRASP Default values: ');
    disp(grasp_default_objectives');
catch ME
    fprintf('Error loading GRASP default CSV: %s\n', ME.message);
    error('Could not load GRASP_summary.csv');
end

% Load GRASP Optimized results from CSV
try
    fid = fopen('GRASP/results/GRASP Optimized/GRASP_Optimized_summary.csv', 'r');
    header = fgetl(fid);
    grasp_optimized_objectives = zeros(10, 1);
    
    for i = 1:10
        line = fgetl(fid);
        parts = strsplit(line, ',');
        % Column 2 is Final_avgSP
        grasp_optimized_objectives(i) = str2double(parts{2});
    end
    fclose(fid);
    
    fprintf('GRASP Optimized values: ');
    disp(grasp_optimized_objectives');
catch ME
    fprintf('Error loading GRASP optimized CSV: %s\n', ME.message);
    error('Could not load GRASP_Optimized_summary.csv');
end

% Load GA Default results from CSV
try
    fid = fopen('GA/results/GA Default/GA_summary.csv', 'r');
    header = fgetl(fid);
    ga_default_objectives = zeros(10, 1);
    
    for i = 1:10
        line = fgetl(fid);
        parts = strsplit(line, ',');
        % Column 2 is Objective
        ga_default_objectives(i) = str2double(parts{2});
    end
    fclose(fid);
    
    fprintf('GA Default values: ');
    disp(ga_default_objectives');
catch ME
    fprintf('Error loading GA default CSV: %s\n', ME.message);
    error('Could not load GA_summary.csv');
end

% Load GA Optimized results from CSV
try
    fid = fopen('GA/results/GA Optimized/GA_Optimized_summary.csv', 'r');
    header = fgetl(fid);
    ga_optimized_objectives = zeros(10, 1);
    
    for i = 1:10
        line = fgetl(fid);
        parts = strsplit(line, ',');
        % Column 2 is Objective
        ga_optimized_objectives(i) = str2double(parts{2});
    end
    fclose(fid);
    
    fprintf('GA Optimized values: ');
    disp(ga_optimized_objectives');
catch ME
    fprintf('Error loading GA optimized CSV: %s\n', ME.message);
    error('Could not load GA_Optimized_summary.csv');
end

% Create run numbers (1 to 10)
run_numbers = 1:10;

% Create the figure
figure('Position', [100, 100, 900, 700]);

% Plot all four algorithms with distinct colors and styles
plot(run_numbers, grasp_default_objectives, '-', 'LineWidth', 2, 'Marker', 'o', 'MarkerSize', 8, ...
     'Color', [0.8 0.2 0.2], 'MarkerFaceColor', [0.8 0.2 0.2]); % Red
hold on;
plot(run_numbers, grasp_optimized_objectives, '--', 'LineWidth', 2, 'Marker', '^', 'MarkerSize', 8, ...
     'Color', [0.2 0.6 0.2], 'MarkerFaceColor', [0.2 0.6 0.2]); % Green
plot(run_numbers, ga_default_objectives, '-', 'LineWidth', 2, 'Marker', 's', 'MarkerSize', 8, ...
     'Color', [0.2 0.2 0.8], 'MarkerFaceColor', [0.2 0.2 0.8]); % Blue
plot(run_numbers, ga_optimized_objectives, '--', 'LineWidth', 2, 'Marker', 'd', 'MarkerSize', 8, ...
     'Color', [0.8 0.5 0.0], 'MarkerFaceColor', [0.8 0.5 0.0]); % Orange

% Customize the plot
xlabel('Run number', 'FontSize', 12, 'FontWeight', 'bold');
ylabel('Average Shortest Path Length', 'FontSize', 12, 'FontWeight', 'bold');
title('Comparison of GRASP and GA Algorithms', 'FontSize', 14, 'FontWeight', 'bold');

% Add legend with all four algorithms
legend({'GRASP Default', 'GRASP Optimized', 'GA Default', 'GA Optimized'}, ...
       'Location', 'best', 'FontSize', 11, 'Box', 'on');

% Set axis properties
grid on;
grid minor;
set(gca, 'FontSize', 10);

% Set x-axis limits and ticks
xlim([0, 11]);
xticks(0:1:10);

% Adjust y-axis to show the data clearly
all_objectives = [grasp_default_objectives; grasp_optimized_objectives; ...
                  ga_default_objectives; ga_optimized_objectives];
y_min = min(all_objectives) - 5;
y_max = max(all_objectives) + 5;
ylim([y_min, y_max]);

% Calculate statistics for each algorithm
grasp_default_mean = mean(grasp_default_objectives);
grasp_optimized_mean = mean(grasp_optimized_objectives);
ga_default_mean = mean(ga_default_objectives);
ga_optimized_mean = mean(ga_optimized_objectives);

% Add statistics text box
stats_text = sprintf('Mean Average SP:\nGRASP Default: %.2f\nGRASP Optimized: %.2f\nGA Default: %.2f\nGA Optimized: %.2f', ...
    grasp_default_mean, grasp_optimized_mean, ga_default_mean, ga_optimized_mean);

% Add text box with statistics
annotation('textbox', [0.15, 0.15, 0.25, 0.15], 'String', stats_text, ...
    'FontSize', 10, 'BackgroundColor', 'white', 'EdgeColor', 'black', ...
    'FitBoxToText', 'on');

% Save the figure
saveas(gcf, 'plots/GRASP_vs_GA_comparison.png');
saveas(gcf, 'plots/GRASP_vs_GA_comparison.fig');

fprintf('\nPlot saved as: GRASP_vs_GA_comparison.png and .fig\n');

end