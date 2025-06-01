function analyzeExistingResults()
% Quick analysis of existing GRASP results without running fresh algorithms
% This function loads saved GRASP results and generates individual analysis plots

    fprintf('=== Analyzing Existing GRASP Results ===\n\n');
    
    % Check for results file
    resultsFile = 'results/GRASP_results.mat';
    if exist(resultsFile, 'file') ~= 2
        fprintf('Error: No GRASP results found at %s\n', resultsFile);
        fprintf('Run GRASP first using runGRASP() to generate results\n');
        return;
    end
    
    % Load data and results
    addpath('../');
    [G, n, Cmax] = loadData();
    load(resultsFile);
    
    if ~exist('allResults', 'var')
        fprintf('Error: Results file does not contain expected data structure\n');
        return;
    end
    
    fprintf('Loaded data: %d nodes, target n=%d, Cmax=%d\n', numnodes(G), n, Cmax);
    fprintf('Found %d GRASP runs to analyze\n\n', length(allResults));
    
    % Add path for utility functions
    addpath('utilities');
    
    % Extract and validate solutions
    validResults = [];
    validSolutions = {};
    validAvgSPs = [];
    validMaxSPs = [];
    
    for i = 1:length(allResults)
        if ~isempty(allResults(i).solution) && ...
           ~isempty(allResults(i).avgSP) && ...
           ~isinf(allResults(i).avgSP) && ...
           allResults(i).maxSP <= Cmax
            
            validResults(end+1) = i;
            validSolutions{end+1} = allResults(i).solution;
            validAvgSPs(end+1) = allResults(i).avgSP;
            validMaxSPs(end+1) = allResults(i).maxSP;
        end
    end
    
    numValid = length(validResults);
    if numValid == 0
        fprintf('Error: No valid solutions found in results\n');
        return;
    end
    
    fprintf('Valid solutions: %d/%d (%.1f%% success rate)\n', ...
            numValid, length(allResults), 100*numValid/length(allResults));
    
    % === BASIC STATISTICS ===
    fprintf('\n=== Solution Quality Statistics ===\n');
    fprintf('Best avgSP: %.6f\n', min(validAvgSPs));
    fprintf('Worst avgSP: %.6f\n', max(validAvgSPs));
    fprintf('Mean avgSP: %.6f ± %.6f\n', mean(validAvgSPs), std(validAvgSPs));
    fprintf('Mean maxSP: %.6f ± %.6f\n', mean(validMaxSPs), std(validMaxSPs));
    
    % === NODE FREQUENCY ANALYSIS ===
    fprintf('\n=== Node Frequency Analysis ===\n');
    
    nNodes = numnodes(G);
    nodeFrequency = zeros(nNodes, 1);
    
    % Count node appearances
    for i = 1:numValid
        solution = validSolutions{i};
        for node = solution
            nodeFrequency(node) = nodeFrequency(node) + 1;
        end
    end
    
    nodeFrequencyPercent = 100 * nodeFrequency / numValid;
    
    % Find important nodes
    coreNodes = find(nodeFrequencyPercent > 50);
    frequentNodes = find(nodeFrequencyPercent > 25);
    rareNodes = find(nodeFrequencyPercent > 0 & nodeFrequencyPercent < 10);
    
    fprintf('Core nodes (>50%% frequency): %d nodes\n', length(coreNodes));
    if ~isempty(coreNodes)
        fprintf('  Nodes: [%s]\n', num2str(coreNodes'));
        fprintf('  Frequencies: [%s]%%\n', num2str(round(nodeFrequencyPercent(coreNodes)', 1)));
    end
    
    fprintf('Frequent nodes (>25%% frequency): %d nodes\n', length(frequentNodes));
    fprintf('Rarely used nodes (<10%% frequency): %d nodes\n', length(rareNodes));
    
    % === TOP SOLUTIONS ANALYSIS ===
    fprintf('\n=== Top Solutions Analysis ===\n');
    
    % Analyze top 20% solutions
    topPercent = 20;
    threshold = prctile(validAvgSPs, topPercent);
    topIndices = find(validAvgSPs <= threshold);
    topSolutions = validSolutions(topIndices);
    
    fprintf('Top %d%% solutions (threshold: %.6f): %d solutions\n', ...
            topPercent, threshold, length(topSolutions));
    
    % Node frequency in top solutions
    topNodeFreq = zeros(nNodes, 1);
    for i = 1:length(topSolutions)
        solution = topSolutions{i};
        for node = solution
            topNodeFreq(node) = topNodeFreq(node) + 1;
        end
    end
    
    topNodeFreqPercent = 100 * topNodeFreq / length(topSolutions);
    topCoreNodes = find(topNodeFreqPercent > 50);
    
    fprintf('Core nodes in top solutions: %d nodes\n', length(topCoreNodes));
    if ~isempty(topCoreNodes)
        fprintf('  Nodes: [%s]\n', num2str(topCoreNodes'));
    end
    
    % === CONVERGENCE ANALYSIS ===
    fprintf('\n=== Convergence Analysis ===\n');
    
    % Analyze convergence patterns if iteration data is available
    convergenceData = [];
    if isfield(allResults(1), 'results') && isfield(allResults(1).results, 'avgSPs')
        fprintf('Analyzing convergence patterns...\n');
        
        for i = validResults
            if ~isempty(allResults(i).results) && isfield(allResults(i).results, 'avgSPs')
                runData = allResults(i).results.avgSPs;
                % Normalize to percentage improvement
                if length(runData) > 1
                    improvement = 100 * (runData(1) - runData(end)) / runData(1);
                    convergenceData(end+1) = improvement;
                end
            end
        end
        
        if ~isempty(convergenceData)
            fprintf('Average improvement per run: %.2f%% ± %.2f%%\n', ...
                    mean(convergenceData), std(convergenceData));
            fprintf('Best improvement: %.2f%%\n', max(convergenceData));
        end
    end
    
    % === CREATE INDIVIDUAL VISUALIZATIONS ===
    fprintf('\n=== Creating Individual Analysis Plots ===\n');
    
    timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
    
    % 1. Solution quality distribution
    figure('Position', [50, 50, 1200, 800]);
    histogram(validAvgSPs, 'Normalization', 'probability', 'BinWidth', (max(validAvgSPs)-min(validAvgSPs))/15, ...
              'FaceColor', [0.3 0.6 0.9], 'EdgeColor', [0.2 0.4 0.7]);
    title('Solution Quality Distribution', 'FontSize', 14, 'FontWeight', 'bold');
    xlabel('Average Shortest Path', 'FontSize', 12);
    ylabel('Probability', 'FontSize', 12);
    hold on;
    xline(mean(validAvgSPs), 'r--', 'LineWidth', 2, 'Label', 'Mean');
    xline(threshold, 'g--', 'LineWidth', 2, 'Label', sprintf('Top %d%%', topPercent));
    legend('show', 'FontSize', 11, 'Location', 'best');
    grid on;
    set(gca, 'FontSize', 11);
    saveAnalysisPlot(gcf, 'analysis', 'solution_quality_distribution', timestamp);
    
    % 2. Solution consistency analysis
    figure('Position', [100, 100, 1200, 800]);
    if numValid > 1
        % Calculate coefficient of variation for solution quality
        cv = 100 * std(validAvgSPs) / mean(validAvgSPs);
        
        % Show run-to-run variation
        plot(1:numValid, validAvgSPs, 'o-', 'LineWidth', 1.5, 'MarkerSize', 6, ...
             'Color', [0.2 0.4 0.8], 'MarkerFaceColor', [0.2 0.4 0.8]);
        hold on;
        plot([1, numValid], [mean(validAvgSPs), mean(validAvgSPs)], 'r--', 'LineWidth', 2);
        fill([1:numValid, numValid:-1:1], ...
             [validAvgSPs, mean(validAvgSPs)*ones(1, numValid)], ...
             [0.2 0.4 0.8], 'FaceAlpha', 0.1, 'EdgeColor', 'none');
        
        title(sprintf('Solution Consistency (CV=%.1f%%)', cv), 'FontSize', 14, 'FontWeight', 'bold');
        xlabel('Run Number', 'FontSize', 12);
        ylabel('Average Shortest Path', 'FontSize', 12);
        grid on;
        legend('Individual runs', 'Mean quality', 'Variation range', 'Location', 'best', 'FontSize', 11);
        set(gca, 'FontSize', 11);
        
        % Add consistency assessment
        if cv < 5
            text(0.7, 0.9, 'Very Consistent', 'Units', 'normalized', ...
                 'BackgroundColor', 'green', 'Color', 'white', 'FontWeight', 'bold', 'FontSize', 11);
        elseif cv < 15
            text(0.7, 0.9, 'Moderately Consistent', 'Units', 'normalized', ...
                 'BackgroundColor', 'orange', 'Color', 'white', 'FontWeight', 'bold', 'FontSize', 11);
        else
            text(0.7, 0.9, 'Highly Variable', 'Units', 'normalized', ...
                 'BackgroundColor', 'red', 'Color', 'white', 'FontWeight', 'bold', 'FontSize', 11);
        end
    else
        text(0.5, 0.5, 'Need multiple runs for consistency analysis', ...
             'HorizontalAlignment', 'center', 'FontSize', 12);
        title('Solution Consistency Analysis', 'FontSize', 14, 'FontWeight', 'bold');
    end
    saveAnalysisPlot(gcf, 'analysis', 'solution_consistency', timestamp);
    
    % 3. AvgSP vs MaxSP correlation
    figure('Position', [150, 150, 1200, 800]);
    scatter(validAvgSPs, validMaxSPs, 80, [0.3 0.6 0.9], 'filled', 'MarkerEdgeColor', [0.2 0.4 0.7]);
    xlabel('Average Shortest Path', 'FontSize', 12);
    ylabel('Maximum Shortest Path', 'FontSize', 12);
    title('Average vs Maximum Shortest Path Correlation', 'FontSize', 14, 'FontWeight', 'bold');
    grid on;
    set(gca, 'FontSize', 11);
    
    % Add correlation coefficient
    if length(validAvgSPs) > 1
        corrCoef = corrcoef(validAvgSPs, validMaxSPs);
        text(0.05, 0.95, sprintf('Correlation: %.3f', corrCoef(1,2)), ...
             'Units', 'normalized', 'FontSize', 12, 'FontWeight', 'bold', ...
             'BackgroundColor', 'white', 'EdgeColor', 'black');
    end
    saveAnalysisPlot(gcf, 'analysis', 'avgsp_vs_maxsp_correlation', timestamp);
    
    % 4. Node frequency analysis
    figure('Position', [200, 200, 1200, 800]);
    if nNodes <= 50
        % Bar plot for small networks
        bar(1:nNodes, nodeFrequencyPercent, 'FaceColor', [0.3 0.7 0.3], 'EdgeColor', [0.2 0.5 0.2]);
        xlabel('Node ID', 'FontSize', 12);
        ylabel('Selection Frequency (%)', 'FontSize', 12);
        title('Node Selection Frequency', 'FontSize', 14, 'FontWeight', 'bold');
        
        % Highlight core nodes
        if ~isempty(coreNodes)
            hold on;
            bar(coreNodes, nodeFrequencyPercent(coreNodes), 'FaceColor', 'red', 'EdgeColor', 'darkred');
            legend('All nodes', 'Core nodes (>50%)', 'FontSize', 11);
        end
    else
        % Histogram for large networks
        histogram(nodeFrequencyPercent(nodeFrequencyPercent > 0), 'Normalization', 'count', ...
                  'FaceColor', [0.3 0.7 0.3], 'EdgeColor', [0.2 0.5 0.2]);
        xlabel('Selection Frequency (%)', 'FontSize', 12);
        ylabel('Number of Nodes', 'FontSize', 12);
        title('Distribution of Node Selection Frequencies', 'FontSize', 14, 'FontWeight', 'bold');
    end
    grid on;
    set(gca, 'FontSize', 11);
    saveAnalysisPlot(gcf, 'analysis', 'node_frequency_analysis', timestamp);
    
    % 5. Core nodes comparison (all vs top solutions)
    figure('Position', [250, 250, 1200, 800]);
    if ~isempty(coreNodes) && ~isempty(topCoreNodes)
        % Venn diagram data
        onlyAll = setdiff(coreNodes, topCoreNodes);
        both = intersect(coreNodes, topCoreNodes);
        onlyTop = setdiff(topCoreNodes, coreNodes);
        
        categories = {'All solutions only', 'Both categories', 'Top solutions only'};
        values = [length(onlyAll), length(both), length(onlyTop)];
        
        pie(values, categories);
        title('Core Nodes: All Solutions vs Top 20% Solutions', 'FontSize', 14, 'FontWeight', 'bold');
        
        % Add summary text
        text(0, -1.5, sprintf('All solutions core nodes: %d\nTop solutions core nodes: %d\nOverlap: %d nodes', ...
             length(coreNodes), length(topCoreNodes), length(both)), ...
             'HorizontalAlignment', 'center', 'FontSize', 11, 'FontWeight', 'bold');
    else
        text(0.5, 0.5, 'Insufficient core nodes for comparison', ...
             'HorizontalAlignment', 'center', 'FontSize', 12);
        title('Core Nodes Comparison', 'FontSize', 14, 'FontWeight', 'bold');
    end
    saveAnalysisPlot(gcf, 'analysis', 'core_nodes_comparison', timestamp);
    
    % 6. Solution diversity (Jaccard similarity)
    figure('Position', [300, 300, 1200, 800]);
    if numValid >= 2
        similarities = [];
        for i = 1:min(20, numValid-1)  % Sample max 20 comparisons
            for j = i+1:min(i+5, numValid)  % Compare with next 5
                sol1 = validSolutions{i};
                sol2 = validSolutions{j};
                intersection = length(intersect(sol1, sol2));
                union = length(union(sol1, sol2));
                jaccard = intersection / union;
                similarities(end+1) = jaccard;
            end
        end
        
        histogram(similarities, 'Normalization', 'probability', ...
                  'FaceColor', [0.7 0.3 0.7], 'EdgeColor', [0.5 0.2 0.5]);
        title('Solution Diversity (Jaccard Similarity)', 'FontSize', 14, 'FontWeight', 'bold');
        xlabel('Jaccard Similarity Index', 'FontSize', 12);
        ylabel('Probability', 'FontSize', 12);
        grid on;
        set(gca, 'FontSize', 11);
        
        % Add diversity assessment
        avgSimilarity = mean(similarities);
        if avgSimilarity < 0.3
            diversityText = 'High Diversity';
            textColor = 'green';
        elseif avgSimilarity < 0.6
            diversityText = 'Moderate Diversity';
            textColor = 'orange';
        else
            diversityText = 'Low Diversity';
            textColor = 'red';
        end
        
        text(0.7, 0.9, sprintf('%s\n(Avg: %.3f)', diversityText, avgSimilarity), ...
             'Units', 'normalized', 'FontSize', 11, 'FontWeight', 'bold', ...
             'BackgroundColor', textColor, 'Color', 'white');
    else
        text(0.5, 0.5, 'Need ≥2 solutions for diversity analysis', ...
             'HorizontalAlignment', 'center', 'FontSize', 12);
        title('Solution Diversity Analysis', 'FontSize', 14, 'FontWeight', 'bold');
    end
    saveAnalysisPlot(gcf, 'analysis', 'solution_diversity', timestamp);
    
    % 7. Best solution visualization
    figure('Position', [350, 350, 1200, 800]);
    [~, bestIdx] = min(validAvgSPs);
    bestSolution = validSolutions{bestIdx};
    
    % Create a simple network plot if network is small enough
    if numnodes(G) <= 50
        h = plot(G, 'Layout', 'circle', 'NodeColor', [0.8 0.8 0.8], 'MarkerSize', 6);
        highlight(h, bestSolution, 'NodeColor', 'red', 'MarkerSize', 10);
        title(sprintf('Best Solution Visualization (avgSP: %.4f)', min(validAvgSPs)), ...
              'FontSize', 14, 'FontWeight', 'bold');
        legend('Regular nodes', 'Selected controllers', 'FontSize', 11);
    else
        % For large networks, show solution as bar plot
        solutionVector = zeros(nNodes, 1);
        solutionVector(bestSolution) = 1;
        bar(solutionVector, 'FaceColor', 'red', 'EdgeColor', 'darkred');
        title(sprintf('Best Solution Controller Nodes (avgSP: %.4f)', min(validAvgSPs)), ...
              'FontSize', 14, 'FontWeight', 'bold');
        xlabel('Node ID', 'FontSize', 12);
        ylabel('Selected as Controller', 'FontSize', 12);
        ylim([0, 1.2]);
        grid on;
    end
    set(gca, 'FontSize', 11);
    saveAnalysisPlot(gcf, 'analysis', 'best_solution_visualization', timestamp);
    
    % 8. Quality improvement over runs (if data available)
    if ~isempty(convergenceData)
        figure('Position', [400, 400, 1200, 800]);
        histogram(convergenceData, 'Normalization', 'probability', ...
                  'FaceColor', [0.2 0.8 0.4], 'EdgeColor', [0.1 0.6 0.3]);
        title('Quality Improvement Distribution Across Runs', 'FontSize', 14, 'FontWeight', 'bold');
        xlabel('Improvement (%)', 'FontSize', 12);
        ylabel('Probability', 'FontSize', 12);
        grid on;
        set(gca, 'FontSize', 11);
        
        % Add statistics
        text(0.7, 0.8, sprintf('Mean: %.2f%%\nStd: %.2f%%\nMax: %.2f%%', ...
             mean(convergenceData), std(convergenceData), max(convergenceData)), ...
             'Units', 'normalized', 'FontSize', 11, 'FontWeight', 'bold', ...
             'BackgroundColor', 'white', 'EdgeColor', 'black');
        
        saveAnalysisPlot(gcf, 'analysis', 'improvement_distribution', timestamp);
    end
    
    fprintf('Individual analysis plots saved in: plots/analysis/\n');
    
    % === SAVE ANALYSIS RESULTS ===
    analysisResults = struct();
    analysisResults.numValid = numValid;
    analysisResults.successRate = 100 * numValid / length(allResults);
    analysisResults.avgSP_stats = struct('mean', mean(validAvgSPs), 'std', std(validAvgSPs), ...
                                        'min', min(validAvgSPs), 'max', max(validAvgSPs));
    analysisResults.nodeFrequency = nodeFrequencyPercent;
    analysisResults.coreNodes = coreNodes;
    analysisResults.topCoreNodes = topCoreNodes;
    analysisResults.bestSolution = bestSolution;
    analysisResults.bestAvgSP = min(validAvgSPs);
    
    resultsFilename = sprintf('results/existing_analysis_%s.mat', timestamp);
    save(resultsFilename, 'analysisResults');
    fprintf('Analysis results saved as: %s\n', resultsFilename);
    
    fprintf('\n=== Analysis Complete ===\n');
    fprintf('Key findings:\n');
    fprintf('- Success rate: %.1f%%\n', analysisResults.successRate);
    fprintf('- Best solution quality: %.6f\n', analysisResults.bestAvgSP);
    fprintf('- Core nodes identified: %d\n', length(coreNodes));
    fprintf('- Quality variation: %.6f (std dev)\n', std(validAvgSPs));
end