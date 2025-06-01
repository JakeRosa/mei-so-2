function nodeAnalysis = analyzeNodeFrequency(G, n, Cmax, r, numRuns, topPercentile)
% Analyze node frequency in GRASP solutions to identify important nodes
% Inputs:
%   G - graph representing the network
%   n - number of nodes to select
%   Cmax - maximum allowed shortest path length between controllers
%   r - parameter for greedy randomized selection
%   numRuns - number of GRASP runs to analyze
%   topPercentile - consider solutions in top percentile (default: 10)
% Output:
%   nodeAnalysis - struct with detailed node frequency analysis

    if nargin < 6
        topPercentile = 10;
    end

    fprintf('Analyzing node frequency over %d GRASP runs...\n', numRuns);
    fprintf('Considering top %d%% of solutions\n', topPercentile);
    
    nNodes = numnodes(G);
    allSolutions = {};
    allAvgSPs = [];
    validRuns = 0;
    
    % Run GRASP multiple times to collect solutions
    for run = 1:numRuns
        % Single GRASP iteration
        constructedSolution = greedyRandomized(G, n, r, Cmax);
        
        if isempty(constructedSolution)
            continue;
        end
        
        % Apply local search
        finalSolution = steepestAscentHillClimbing(G, constructedSolution, Cmax);
        
        % Evaluate solution
        [avgSP, maxSP] = PerfSNS(G, finalSolution);
        
        % Only consider feasible solutions
        if maxSP <= Cmax
            validRuns = validRuns + 1;
            allSolutions{validRuns} = finalSolution;
            allAvgSPs(validRuns) = avgSP;
        end
        
        if mod(run, 10) == 0
            fprintf('Completed %d/%d runs (%d valid)\n', run, numRuns, validRuns);
        end
    end
    
    if validRuns == 0
        error('No valid solutions found in %d runs', numRuns);
    end
    
    % Select top solutions based on percentile
    threshold = prctile(allAvgSPs, topPercentile);
    topIndices = find(allAvgSPs <= threshold);
    topSolutions = allSolutions(topIndices);
    topAvgSPs = allAvgSPs(topIndices);
    
    fprintf('Selected %d solutions in top %d%% (threshold: %.4f)\n', ...
            length(topSolutions), topPercentile, threshold);
    
    % Calculate node frequencies
    nodeFrequency = zeros(nNodes, 1);
    nodeFrequencyInTop = zeros(nNodes, 1);
    
    % Count frequency in all valid solutions
    for i = 1:validRuns
        solution = allSolutions{i};
        for node = solution
            nodeFrequency(node) = nodeFrequency(node) + 1;
        end
    end
    
    % Count frequency in top solutions
    for i = 1:length(topSolutions)
        solution = topSolutions{i};
        for node = solution
            nodeFrequencyInTop(node) = nodeFrequencyInTop(node) + 1;
        end
    end
    
    % Convert to percentages
    nodeFrequencyPercent = 100 * nodeFrequency / validRuns;
    nodeFrequencyTopPercent = 100 * nodeFrequencyInTop / length(topSolutions);
    
    % Identify important nodes
    coreThreshold = 50; % nodes appearing in >50% of top solutions
    coreNodes = find(nodeFrequencyTopPercent > coreThreshold);
    
    frequentThreshold = 25; % nodes appearing in >25% of top solutions
    frequentNodes = find(nodeFrequencyTopPercent > frequentThreshold);
    
    rareThreshold = 5; % nodes appearing in <5% of top solutions
    rareNodes = find(nodeFrequencyTopPercent < rareThreshold & nodeFrequencyTopPercent > 0);
    
    % Calculate node importance metrics
    nodeImportance = zeros(nNodes, 1);
    for i = 1:nNodes
        % Weighted importance based on frequency in top vs all solutions
        if nodeFrequency(i) > 0
            nodeImportance(i) = nodeFrequencyTopPercent(i) / nodeFrequencyPercent(i);
        end
    end
    
    % Store results
    nodeAnalysis = struct();
    nodeAnalysis.validRuns = validRuns;
    nodeAnalysis.topSolutions = topSolutions;
    nodeAnalysis.topAvgSPs = topAvgSPs;
    nodeAnalysis.topPercentile = topPercentile;
    nodeAnalysis.threshold = threshold;
    
    nodeAnalysis.nodeFrequency = nodeFrequency;
    nodeAnalysis.nodeFrequencyPercent = nodeFrequencyPercent;
    nodeAnalysis.nodeFrequencyInTop = nodeFrequencyInTop;
    nodeAnalysis.nodeFrequencyTopPercent = nodeFrequencyTopPercent;
    nodeAnalysis.nodeImportance = nodeImportance;
    
    nodeAnalysis.coreNodes = coreNodes;
    nodeAnalysis.frequentNodes = frequentNodes;
    nodeAnalysis.rareNodes = rareNodes;
    
    % Print summary
    fprintf('\n=== Node Frequency Analysis ===\n');
    fprintf('Total valid runs: %d\n', validRuns);
    fprintf('Top solutions analyzed: %d\n', length(topSolutions));
    fprintf('Best solution avgSP: %.4f\n', min(topAvgSPs));
    fprintf('Worst top solution avgSP: %.4f\n', max(topAvgSPs));
    
    fprintf('\nNode Categories:\n');
    fprintf('  Core nodes (>%d%% in top): %d nodes\n', coreThreshold, length(coreNodes));
    if ~isempty(coreNodes)
        fprintf('    Nodes: [%s]\n', num2str(coreNodes'));
        fprintf('    Frequencies: [%s]\n', num2str(round(nodeFrequencyTopPercent(coreNodes)', 1)));
    end
    
    fprintf('  Frequent nodes (>%d%% in top): %d nodes\n', frequentThreshold, length(frequentNodes));
    if ~isempty(frequentNodes)
        fprintf('    Nodes: [%s]\n', num2str(frequentNodes'));
    end
    
    fprintf('  Rare nodes (<%d%% in top): %d nodes\n', rareThreshold, length(rareNodes));
    
    % Most and least popular nodes
    [~, mostPopularIdx] = max(nodeFrequencyTopPercent);
    [~, leastPopularIdx] = min(nodeFrequencyTopPercent(nodeFrequencyTopPercent > 0));
    nonZeroNodes = find(nodeFrequencyTopPercent > 0);
    leastPopularNode = nonZeroNodes(leastPopularIdx);
    
    fprintf('\nExtreme Cases:\n');
    fprintf('  Most popular node: %d (%.1f%% in top solutions)\n', ...
            mostPopularIdx, nodeFrequencyTopPercent(mostPopularIdx));
    fprintf('  Least popular node: %d (%.1f%% in top solutions)\n', ...
            leastPopularNode, nodeFrequencyTopPercent(leastPopularNode));
    
    % Add path for utility functions
    addpath('utilities');
    
    % Generate timestamp for consistent naming
    timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
    
    % Create individual node frequency analysis plots
    fprintf('\n=== Creating Individual Node Analysis Plots ===\n');
    
    % 1. Node frequency in top solutions
    figure('Position', [50, 50, 1200, 800]);
    bar(nodeFrequencyTopPercent, 'FaceColor', [0.3 0.7 0.9], 'EdgeColor', "black");
    title(sprintf('Node Frequency in Top %d%% Solutions', topPercentile), 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('Node ID', 'FontSize', 12);
    ylabel('Frequency (%)', 'FontSize', 12);
    set(gca, 'FontSize', 11);
    grid on;
    if ~isempty(coreNodes)
        hold on;
        bar(coreNodes, nodeFrequencyTopPercent(coreNodes), 'FaceColor', 'red', 'EdgeColor', 'darkred');
        legend('All nodes', 'Core nodes (>50%)', 'Location', 'best', 'FontSize', 10);
    end
    saveAnalysisPlot(gcf, 'nodes', 'node_frequency_top_solutions', timestamp);
    
    % 2. Node importance scatter plot
    figure('Position', [100, 100, 1200, 800]);
    validImportance = nodeImportance(nodeImportance > 0);
    validNodes = find(nodeImportance > 0);
    scatter(validNodes, validImportance, 80, [0.7 0.3 0.9], 'filled', 'MarkerEdgeColor', [0.5 0.2 0.7]);
    title('Node Importance Score Analysis', 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('Node ID', 'FontSize', 12);
    ylabel('Importance Score (Top Freq / All Freq)', 'FontSize', 12);
    set(gca, 'FontSize', 11);
    grid on;
    
    % Highlight core nodes
    if ~isempty(coreNodes)
        hold on;
        scatter(coreNodes, nodeImportance(coreNodes), 120, 'r', 'filled', 'MarkerEdgeColor', 'darkred');
        legend('All nodes', 'Core nodes', 'Location', 'best', 'FontSize', 10);
    end
    saveAnalysisPlot(gcf, 'nodes', 'node_importance_score', timestamp);
    
    % 3. Frequency comparison (all vs top solutions)
    figure('Position', [150, 150, 1200, 800]);
    activeNodes = find(nodeFrequency > 0);
    scatter(nodeFrequencyPercent(activeNodes), nodeFrequencyTopPercent(activeNodes), 80, ...
            [0.3 0.9 0.3], 'filled', 'MarkerEdgeColor', [0.2 0.7 0.2]);
    hold on;
    plot([0, 100], [0, 100], 'r--', 'LineWidth', 2);
    title('Node Frequency: All Solutions vs Top Solutions', 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('Frequency in All Solutions (%)', 'FontSize', 12);
    ylabel('Frequency in Top Solutions (%)', 'FontSize', 12);
    set(gca, 'FontSize', 11);
    grid on;
    legend('Active nodes', 'Equal frequency line', 'Location', 'best', 'FontSize', 10);
    
    % Add quadrant labels
    text(0.75, 0.25, 'Higher in all\nthan in top', 'Units', 'normalized', ...
         'FontSize', 10, 'HorizontalAlignment', 'center', 'Color', 'blue');
    text(0.25, 0.75, 'Higher in top\nthan in all', 'Units', 'normalized', ...
         'FontSize', 10, 'HorizontalAlignment', 'center', 'Color', 'red');
    
    saveAnalysisPlot(gcf, 'nodes', 'frequency_comparison_all_vs_top', timestamp);
    
    % 4. Network visualization with node importance (for small networks)
    figure('Position', [200, 200, 1200, 800]);
    if nNodes <= 200 % Only plot if network is not too large
        % Create position layout
        pos = spring_layout(G);
        
        % Node colors based on frequency
        nodeColors = nodeFrequencyTopPercent;
        nodeColors(nodeColors == 0) = min(nodeColors(nodeColors > 0)) / 2; % Make unused nodes visible
        
        % Node sizes based on frequency
        maxFreq = max(nodeFrequencyTopPercent);
        if maxFreq > 0
            nodeSizes = 8 + 12 * (nodeFrequencyTopPercent / maxFreq);
            nodeSizes(nodeFrequencyTopPercent == 0) = 4; % Smaller size for unused nodes
        else
            nodeSizes = 8 * ones(nNodes, 1);
        end
        
        % Plot network
        h = plot(G, 'XData', pos(:,1), 'YData', pos(:,2), ...
                'NodeCData', nodeColors, 'MarkerSize', nodeSizes, ...
                'EdgeColor', [0.7 0.7 0.7], 'EdgeAlpha', 0.3);
        
        title('Network Visualization with Node Selection Frequency', 'FontSize', 14, 'FontWeight', 'bold');
        colorbar;
        colormap('hot');
        
        % Highlight core nodes with different shape
        if ~isempty(coreNodes)
            highlight(h, coreNodes, 'NodeColor', 'blue', 'MarkerSize', 15);
            legend('Regular nodes', 'Core nodes', 'FontSize', 10);
        end
    else
        text(0.5, 0.5, sprintf('Network too large to display\n(%d nodes)', nNodes), ...
             'HorizontalAlignment', 'center', 'FontSize', 12, 'FontWeight', 'bold');
        title('Network Visualization - Too Large to Display', 'FontSize', 14, 'FontWeight', 'bold');
    end
    saveAnalysisPlot(gcf, 'nodes', 'network_visualization', timestamp);
    
    % 5. Node degree vs selection frequency correlation
    figure('Position', [250, 250, 1200, 800]);
    try
        nodeDegrees = degree(G);
        activeNodes = find(nodeFrequencyTopPercent > 0);
        
        if length(activeNodes) > 3
            scatter(nodeDegrees(activeNodes), nodeFrequencyTopPercent(activeNodes), 80, ...
                    [0.9 0.6 0.2], 'filled', 'MarkerEdgeColor', [0.7 0.4 0.1]);
            title('Node Degree vs Selection Frequency', 'FontSize', 14, 'FontWeight', 'bold');
            xlabel('Node Degree', 'FontSize', 12);
            ylabel('Selection Frequency in Top Solutions (%)', 'FontSize', 12);
            set(gca, 'FontSize', 11);
            grid on;
            
            % Add correlation coefficient
            if length(activeNodes) > 1
                corrCoef = corrcoef(nodeDegrees(activeNodes), nodeFrequencyTopPercent(activeNodes));
                text(0.05, 0.95, sprintf('Correlation: %.3f', corrCoef(1,2)), ...
                     'Units', 'normalized', 'FontSize', 11, 'FontWeight', 'bold', ...
                     'BackgroundColor', 'white', 'EdgeColor', 'black');
            end
            
            % Add trend line if enough points
            if length(activeNodes) > 5
                p = polyfit(nodeDegrees(activeNodes), nodeFrequencyTopPercent(activeNodes), 1);
                hold on;
                x_trend = min(nodeDegrees(activeNodes)):max(nodeDegrees(activeNodes));
                y_trend = polyval(p, x_trend);
                plot(x_trend, y_trend, 'r--', 'LineWidth', 2);
                legend('Nodes', 'Trend line', 'FontSize', 10);
            end
        else
            bar(1:length(activeNodes), nodeFrequencyTopPercent(activeNodes), ...
                'FaceColor', [0.9 0.6 0.2], 'EdgeColor', [0.7 0.4 0.1]);
            title('Active Node Frequencies', 'FontSize', 14, 'FontWeight', 'bold');
            xlabel('Active Node Index', 'FontSize', 12);
            ylabel('Frequency (%)', 'FontSize', 12);
            set(gca, 'FontSize', 11);
            grid on;
        end
    catch
        text(0.5, 0.5, 'Unable to compute node degrees', ...
             'HorizontalAlignment', 'center', 'FontSize', 12);
        title('Node Degree Analysis - Error', 'FontSize', 14, 'FontWeight', 'bold');
    end
    saveAnalysisPlot(gcf, 'nodes', 'degree_vs_frequency', timestamp);
    
    % 6. Core nodes detailed analysis (if any exist)
    if ~isempty(coreNodes)
        figure('Position', [300, 300, 1200, 800]);
        coreFreqs = nodeFrequencyTopPercent(coreNodes);
        [sortedFreqs, sortIdx] = sort(coreFreqs, 'descend');
        sortedNodes = coreNodes(sortIdx);
        
        bar(sortedFreqs, 'FaceColor', [0.8 0.2 0.2], 'EdgeColor', 'darkred');
        title('Core Nodes Frequency Analysis (Ranked)', 'FontSize', 14, 'FontWeight', 'bold');
        xlabel('Core Node Rank', 'FontSize', 12);
        ylabel('Frequency in Top Solutions (%)', 'FontSize', 12);
        set(gca, 'XTickLabel', sortedNodes, 'FontSize', 11);
        grid on;
        
        % Add value labels on bars
        for i = 1:length(sortedFreqs)
            text(i, sortedFreqs(i) + max(sortedFreqs)*0.02, ...
                 sprintf('Node %d\n%.1f%%', sortedNodes(i), sortedFreqs(i)), ...
                 'HorizontalAlignment', 'center', 'FontSize', 10, 'FontWeight', 'bold');
        end
        saveAnalysisPlot(gcf, 'nodes', 'core_nodes_detailed_analysis', timestamp);
    end
    
    % 7. Node category distribution
    figure('Position', [350, 350, 1200, 800]);
    categories = {'Core (>50%)', 'Frequent (25-50%)', 'Occasional (5-25%)', 'Rare (<5%)', 'Never used'};
    
    nCore = length(coreNodes);
    nFrequent = length(find(nodeFrequencyTopPercent >= 25 & nodeFrequencyTopPercent <= 50));
    nOccasional = length(find(nodeFrequencyTopPercent >= 5 & nodeFrequencyTopPercent < 25));
    nRare = length(find(nodeFrequencyTopPercent > 0 & nodeFrequencyTopPercent < 5));
    nNever = length(find(nodeFrequencyTopPercent == 0));
    
    counts = [nCore, nFrequent, nOccasional, nRare, nNever];
    colors = [0.8 0.2 0.2; 0.9 0.6 0.2; 0.9 0.9 0.2; 0.6 0.9 0.2; 0.7 0.7 0.7];
    
    pie(counts, categories);
    colormap(colors);
    title('Node Usage Categories Distribution', 'FontSize', 14, 'FontWeight', 'bold');
    
    % Add summary text
    text(0, -1.5, sprintf('Total nodes analyzed: %d\nTop solutions analyzed: %d', ...
         nNodes, length(topSolutions)), ...
         'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold');
    
    saveAnalysisPlot(gcf, 'nodes', 'node_category_distribution', timestamp);
    
    % 8. Frequency histogram
    figure('Position', [400, 400, 1200, 800]);
    activeFreqs = nodeFrequencyTopPercent(nodeFrequencyTopPercent > 0);
    if ~isempty(activeFreqs)
        histogram(activeFreqs, 'Normalization', 'count', 'BinWidth', 5, ...
                  'FaceColor', [0.4 0.6 0.8], 'EdgeColor', [0.3 0.4 0.6]);
        title('Distribution of Node Selection Frequencies', 'FontSize', 14, 'FontWeight', 'bold');
        xlabel('Selection Frequency in Top Solutions (%)', 'FontSize', 12);
        ylabel('Number of Nodes', 'FontSize', 12);
        set(gca, 'FontSize', 11);
        grid on;
        
        % Add statistics
        text(0.7, 0.8, sprintf('Active nodes: %d\nMean freq: %.1f%%\nStd freq: %.1f%%', ...
             length(activeFreqs), mean(activeFreqs), std(activeFreqs)), ...
             'Units', 'normalized', 'FontSize', 11, 'FontWeight', 'bold', ...
             'BackgroundColor', 'white', 'EdgeColor', 'black');
    else
        text(0.5, 0.5, 'No nodes were selected in any solution', ...
             'HorizontalAlignment', 'center', 'FontSize', 12);
        title('Node Frequency Distribution - No Data', 'FontSize', 14, 'FontWeight', 'bold');
    end
    saveAnalysisPlot(gcf, 'nodes', 'frequency_histogram', timestamp);
    
    fprintf('Node frequency analysis plots saved in: plots/nodes/\n');
    
    % Save results
    resultsFilename = sprintf('results/node_frequency_results_%s.mat', timestamp);
    save(resultsFilename, 'nodeAnalysis');
    fprintf('Node frequency results saved as: %s\n', resultsFilename);
end

function pos = spring_layout(G)
% Simple spring layout for small networks
    nNodes = numnodes(G);
    if nNodes <= 50
        pos = rand(nNodes, 2);
        for iter = 1:100
            forces = zeros(nNodes, 2);
            
            % Repulsive forces
            for i = 1:nNodes
                for j = 1:nNodes
                    if i ~= j
                        diff = pos(i,:) - pos(j,:);
                        dist = norm(diff);
                        if dist > 0
                            forces(i,:) = forces(i,:) + diff / (dist^3);
                        end
                    end
                end
            end
            
            % Attractive forces for connected nodes
            edges = table2array(G.Edges(:,1:2));
            for e = 1:size(edges,1)
                i = edges(e,1);
                j = edges(e,2);
                diff = pos(i,:) - pos(j,:);
                dist = norm(diff);
                forces(i,:) = forces(i,:) - 0.1 * diff;
                forces(j,:) = forces(j,:) + 0.1 * diff;
            end
            
            pos = pos + 0.01 * forces;
        end
    else
        % For larger networks, use circular layout
        angles = linspace(0, 2*pi, nNodes+1);
        angles = angles(1:end-1);
        pos = [cos(angles)', sin(angles)'];
    end
end