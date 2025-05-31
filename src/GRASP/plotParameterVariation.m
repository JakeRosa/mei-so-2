function plotParameterVariation(G, n, Cmax, rValues, testResults)
% Plot showing the effect of parameter r on GRASP solution quality
% This function creates a clean line plot showing parameter variation
% 
% Inputs:
%   G - graph representing the network
%   n - number of nodes to select  
%   Cmax - maximum allowed shortest path length between controllers
%   rValues - array of r values tested (e.g., [1, 2, 3, 5, 8, 10])
%   testResults - struct array with results from parameter tuning
%
% Usage: Call this after parameter tuning in runGRASP.m

    fprintf('Creating parameter variation plot...\n');
    
    % Generate additional solution samples for each r value to create the plot
    numSamples = 100; % Number of solution samples per r value
    colors = {'k', 'b', 'r', 'g', 'm', 'c'}; % Colors for different r values
    
    % Create figure - full width for line plot only
    figure('Position', [100, 100, 800, 600]);
    hold on;
    
    % Generate random baseline first
    fprintf('Generating random baseline...\n');
    randomObjectives = [];
    nNodes = numnodes(G);
    for i = 1:numSamples
        randomNodes = randperm(nNodes, n);
        [avgSP, maxSP] = PerfSNS(G, randomNodes);
        if maxSP <= Cmax
            randomObjectives = [randomObjectives, avgSP];
        end
    end
    
    % Plot random solutions
    if ~isempty(randomObjectives)
        plot(1:length(randomObjectives), randomObjectives, 'Color', [0.7 0.7 0.7], ...
             'LineWidth', 1, 'DisplayName', 'Random');
    end
    
    % Store statistics for CSV export
    stats = struct();
    
    % Generate and plot solutions for each r value
    for rIdx = 1:length(rValues)
        r = rValues(rIdx);
        fprintf('Generating solutions for r = %d...\n', r);
        
        objectives = [];
        for i = 1:numSamples
            % Use only greedy randomized construction (no local search for speed)
            solution = greedyRandomized(G, n, r, Cmax);
            if ~isempty(solution) && length(solution) == n
                [avgSP, maxSP] = PerfSNS(G, solution);
                if maxSP <= Cmax
                    objectives = [objectives, avgSP];
                end
            end
        end
        
        % Plot solutions for this r value
        if ~isempty(objectives)
            plot(1:length(objectives), objectives, 'Color', colors{rIdx}, ...
                 'LineWidth', 1.5, 'DisplayName', sprintf('Greedy Randomized, r=%d', r));
            
            % Store statistics
            stats(rIdx).r = r;
            stats(rIdx).min = min(objectives);
            stats(rIdx).avg = mean(objectives);
            stats(rIdx).max = max(objectives);
            stats(rIdx).count = length(objectives);
        end
    end
    
    % Format plot
    xlabel('Solution number');
    ylabel('Objective value');
    title('Parameter r Variation in GRASP');
    legend('Location', 'best');
    grid on;
    
    % Save plot
    if ~exist('plots', 'dir')
        mkdir('plots');
    end
    
    timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
    filename = sprintf('plots/GRASP_parameter_r_variation_%s.png', timestamp);
    saveas(gcf, filename);
    fprintf('Parameter variation plot saved to: %s\n', filename);
    
    % Export statistics to CSV
    addpath("exports/")
    exportParameterStats(stats, randomObjectives, testResults, timestamp);
    
    % Print statistics to console
    fprintf('\n=== PARAMETER VARIATION STATISTICS ===\n');
    for rIdx = 1:length(stats)
        if isfield(stats, 'r') && ~isempty(stats(rIdx).r)
            fprintf('r = %d: Min=%.2f, Avg=%.2f, Max=%.2f (%d solutions)\n', ...
                stats(rIdx).r, stats(rIdx).min, stats(rIdx).avg, ...
                stats(rIdx).max, stats(rIdx).count);
        end
    end
    
    if ~isempty(randomObjectives)
        fprintf('Random: Avg=%.2f (%d solutions)\n', mean(randomObjectives), length(randomObjectives));
    end
end