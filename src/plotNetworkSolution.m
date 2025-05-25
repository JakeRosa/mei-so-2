function plotNetworkSolution(G, solution, avgSP, maxSP, algorithm, runNumber, outputDir)
% Plot network with selected nodes highlighted
% Inputs:
%   G - graph representing the network
%   solution - vector of selected node indices
%   avgSP - average shortest path value
%   maxSP - maximum shortest path value
%   algorithm - string ('GRASP' or 'GA')
%   runNumber - run number
%   outputDir - output directory for saving plots

    if nargin < 7
        outputDir = 'plots/';
    end
    
    % Create figure
    figure('Position', [100, 100, 1200, 800]);
    
    % Get node positions
    nodeX = G.Nodes.x;
    nodeY = G.Nodes.y;
    
    % Plot all edges first (in light gray)
    hold on;
    [s, t] = findedge(G);
    for i = 1:length(s)
        x_coords = [nodeX(s(i)), nodeX(t(i))];
        y_coords = [nodeY(s(i)), nodeY(t(i))];
        plot(x_coords, y_coords, '-', 'Color', [0.8, 0.8, 0.8], 'LineWidth', 0.5);
    end
    
    % Plot all nodes (small, light blue)
    scatter(nodeX, nodeY, 30, [0.7, 0.7, 1], 'filled', 'MarkerEdgeColor', 'k', 'LineWidth', 0.5);
    
    % Highlight selected nodes (larger, red)
    selectedX = nodeX(solution);
    selectedY = nodeY(solution);
    scatter(selectedX, selectedY, 150, 'red', 'filled', 'MarkerEdgeColor', 'red', 'LineWidth', 2);
    
    % Add node labels for selected nodes
    for i = 1:length(solution)
        text(selectedX(i), selectedY(i), num2str(solution(i)), ...
             'HorizontalAlignment', 'center', 'VerticalAlignment', 'middle', ...
             'FontSize', 8, 'FontWeight', 'bold', 'Color', 'white');
    end
    
    % Add title and labels
    title(sprintf('%s Solution - Run %d\nSelected SDN Controllers: [%s]\nAvg SP: %.4f, Max SP: %.4f', ...
          algorithm, runNumber, num2str(solution), avgSP, maxSP), ...
          'FontSize', 14, 'FontWeight', 'bold');
    
    xlabel('X Coordinate', 'FontSize', 12);
    ylabel('Y Coordinate', 'FontSize', 12);
    
    % Add legend
    legend({'Network Links', 'Network Nodes', 'Selected Controllers'}, ...
           'Location', 'northeast', 'FontSize', 10);
    
    % Add grid and improve appearance
    grid on;
    axis equal;
    axis tight;
    
    % Add constraint information
    constraintText = sprintf('Constraint: Max SP ≤ %d\nStatus: %s', ...
                           1000, ternary(maxSP <= 1000, 'SATISFIED', 'VIOLATED'));
    
    % Position text box in upper left
    xlims = xlim;
    ylims = ylim;
    text(xlims(1) + 0.02*(xlims(2)-xlims(1)), ylims(2) - 0.05*(ylims(2)-ylims(1)), ...
         constraintText, 'FontSize', 10, 'BackgroundColor', 'white', ...
         'EdgeColor', 'black', 'VerticalAlignment', 'top');
    
    hold off;
    
    % Save the plot
    if ~exist(outputDir, 'dir')
        mkdir(outputDir);
    end
    
    filename = sprintf('%s/%s_solution_run_%d.png', outputDir, lower(algorithm), runNumber);
    saveas(gcf, filename);
    
    filename_fig = sprintf('%s/%s_solution_run_%d.fig', outputDir, lower(algorithm), runNumber);
    saveas(gcf, filename_fig);
    
    fprintf('Plot saved to: %s\n', filename);
    
    % Close figure to save memory
    close(gcf);
end

function result = ternary(condition, trueValue, falseValue)
% Simple ternary operator function
    if condition
        result = trueValue;
    else
        result = falseValue;
    end
end
