% Enhanced standalone script to run GRASP analysis using existing results or fresh runs
% This script can load previous GRASP results or run fresh analysis

fprintf('=== Enhanced GRASP Analysis Menu ===\n\n');

% Setup paths for organized structure
currentDir = fileparts(mfilename('fullpath'));
graspDir = fileparts(currentDir);  % Go up one level to GRASP/

% Add all necessary paths
addpath(fullfile(graspDir, 'core'));
addpath(fullfile(graspDir, 'analysis'));
addpath(fullfile(graspDir, 'exports'));
addpath(fullfile(graspDir, 'lib'));
addpath(fullfile(graspDir, 'utilities'));

% Add parent directory for shared functions
addpath(fullfile(graspDir, '..'));

% Load data
[G, n, Cmax] = loadData();
fprintf('Loaded network: %d nodes, target n=%d, Cmax=%d\n\n', numnodes(G), n, Cmax);

% Check for existing results
resultsFile = 'results/GRASP_results.mat';
hasExistingResults = exist(resultsFile, 'file') == 2;

if hasExistingResults
    fprintf('Found existing GRASP results in: %s\n', resultsFile);
    
    % Load and inspect existing results
    load(resultsFile);
    if exist('allResults', 'var') && exist('bestR', 'var')
        validResults = ~cellfun(@isempty, {allResults.solution});
        numValidResults = sum(validResults);
        
        fprintf('Existing results summary:\n');
        fprintf('  - Total runs: %d\n', length(allResults));
        fprintf('  - Valid solutions: %d\n', numValidResults);
        fprintf('  - Best r parameter: %d\n', bestR);
        
        if numValidResults > 0
            avgSPs = [allResults(validResults).avgSP];
            fprintf('  - Best avgSP: %.6f\n', min(avgSPs));
            fprintf('  - Average avgSP: %.6f\n', mean(avgSPs));
        end
        
        useExisting = input('\nUse existing results for analysis? (y/n): ', 's');
        if strcmpi(useExisting, 'y')
            runMode = 'existing';
        else
            runMode = 'fresh';
        end
    else
        fprintf('Warning: Results file found but data structure is unexpected\n');
        runMode = 'fresh';
    end
else
    fprintf('No existing GRASP results found. Will run fresh analysis.\n');
    runMode = 'fresh';
end

% Default parameters for fresh runs
r = hasExistingResults && exist('bestR', 'var') ? bestR : 5;
maxTime = 60;
numRuns = 20;

fprintf('\n=== Analysis Options ===\n');
fprintf('1. Phase Contribution Analysis\n');
fprintf('2. Node Frequency Analysis (from existing solutions)\n');
fprintf('3. Parameter Sensitivity Heat Map\n');
fprintf('4. Implementation Comparison\n');
fprintf('5. Solution Quality Distribution\n');
fprintf('6. Run All Available Analysis\n');
fprintf('7. Exit\n\n');

choice = input('Select analysis (1-7): ');

switch choice
    case 1
        fprintf('\n=== Phase Contribution Analysis ===\n');
        if strcmp(runMode, 'existing')
            fprintf('Note: This analysis requires fresh GRASP runs to separate phases\n');
            runFresh = input('Run fresh phase analysis? (y/n): ', 's');
            if strcmpi(runFresh, 'y')
                phaseResults = analyzePhaseContribution(G, n, Cmax, r, numRuns);
            else
                fprintf('Phase analysis skipped\n');
            end
        else
            phaseResults = analyzePhaseContribution(G, n, Cmax, r, numRuns);
        end
        
    case 2
        fprintf('\n=== Node Frequency Analysis ===\n');
        if strcmp(runMode, 'existing') && exist('allResults', 'var')
            fprintf('Using existing solutions for node frequency analysis...\n');
            nodeAnalysis = analyzeExistingSolutions(G, n, Cmax, allResults);
        else
            fprintf('Running fresh node frequency analysis...\n');
            nodeAnalysis = analyzeNodeFrequency(G, n, Cmax, r, numRuns, 10);
        end
        
    case 3
        fprintf('\n=== Parameter Sensitivity Analysis ===\n');
        fprintf('Creating parameter sensitivity heat maps...\n');
        fprintf('Warning: This may take several minutes!\n');
        sensitivityResults = plotParameterSensitivityHeatMap(G, n, Cmax);
        
    case 4
        fprintf('\n=== Implementation Comparison ===\n');
        fprintf('Comparing original vs optimized GRASP...\n');
        comparisonResults = compareOptimizations(G, n, Cmax, r, maxTime, 8);
        
    case 5
        fprintf('\n=== Solution Quality Distribution ===\n');
        if strcmp(runMode, 'existing') && exist('allResults', 'var')
            fprintf('Analyzing existing solution quality distribution...\n');
            qualityAnalysis = analyzeSolutionQuality(allResults, G, n, Cmax);
        else
            fprintf('Need existing results for quality distribution analysis\n');
        end
        
    case 6
        fprintf('\n=== Running All Available Analysis ===\n');
        
        if strcmp(runMode, 'existing') && exist('allResults', 'var')
            fprintf('\n1. Node Frequency Analysis (from existing)...\n');
            nodeAnalysis = analyzeExistingSolutions(G, n, Cmax, allResults);
            
            fprintf('\n2. Solution Quality Analysis (from existing)...\n');
            qualityAnalysis = analyzeSolutionQuality(allResults, G, n, Cmax);
            
            fprintf('\n3. Implementation Comparison (fresh)...\n');
            comparisonResults = compareOptimizations(G, n, Cmax, r, maxTime, 6);
            
            runMore = input('\nRun additional fresh analysis (phase & sensitivity)? (y/n): ', 's');
            if strcmpi(runMore, 'y')
                fprintf('\n4. Phase Contribution Analysis (fresh)...\n');
                phaseResults = analyzePhaseContribution(G, n, Cmax, r, 15);
                
                fprintf('\n5. Parameter Sensitivity Analysis (fresh)...\n');
                sensitivityResults = plotParameterSensitivityHeatMap(G, n, Cmax);
            end
        else
            fprintf('Running all fresh analysis...\n');
            
            fprintf('\n1/4: Phase Contribution Analysis...\n');
            phaseResults = analyzePhaseContribution(G, n, Cmax, r, 15);
            
            fprintf('\n2/4: Node Frequency Analysis...\n');
            nodeAnalysis = analyzeNodeFrequency(G, n, Cmax, r, 15, 10);
            
            fprintf('\n3/4: Implementation Comparison...\n');
            comparisonResults = compareOptimizations(G, n, Cmax, r, maxTime, 6);
            
            fprintf('\n4/4: Parameter Sensitivity Analysis...\n');
            proceed = input('Continue with sensitivity analysis? (y/n): ', 's');
            if strcmpi(proceed, 'y')
                sensitivityResults = plotParameterSensitivityHeatMap(G, n, Cmax);
            end
        end
        
    case 7
        fprintf('Exiting...\n');
        return;
        
    otherwise
        fprintf('Invalid choice. Exiting...\n');
        return;
end

fprintf('\n=== Analysis Complete ===\n');
fprintf('Check the plots/ and results/ directories for outputs\n');

% Save analysis workspace
saveWorkspace = input('\nSave analysis results to workspace file? (y/n): ', 's');
if strcmpi(saveWorkspace, 'y')
    timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
    filename = sprintf('results/enhanced_analysis_%s.mat', timestamp);
    save(filename);
    fprintf('Workspace saved to: %s\n', filename);
end

% ========================================================================
% HELPER FUNCTIONS FOR ANALYZING EXISTING RESULTS
% ========================================================================

function nodeAnalysis = analyzeExistingSolutions(G, n, Cmax, allResults)
% Analyze node frequency using existing GRASP solutions
    
    fprintf('Analyzing node frequency from %d existing solutions...\n', length(allResults));
    
    nNodes = numnodes(G);
    validSolutions = {};
    validAvgSPs = [];
    
    % Extract valid solutions
    for i = 1:length(allResults)
        if ~isempty(allResults(i).solution) && ...
           ~isempty(allResults(i).avgSP) && ...
           ~isinf(allResults(i).avgSP) && ...
           allResults(i).maxSP <= Cmax
            validSolutions{end+1} = allResults(i).solution;
            validAvgSPs(end+1) = allResults(i).avgSP;
        end
    end
    
    validRuns = length(validSolutions);
    if validRuns == 0
        error('No valid solutions found in existing results');
    end
    
    % Select top 10% of solutions
    topPercentile = 10;
    threshold = prctile(validAvgSPs, topPercentile);
    topIndices = find(validAvgSPs <= threshold);
    topSolutions = validSolutions(topIndices);
    topAvgSPs = validAvgSPs(topIndices);
    
    fprintf('Using %d solutions in top %d%% (threshold: %.4f)\n', ...
            length(topSolutions), topPercentile, threshold);
    
    % Calculate node frequencies
    nodeFrequency = zeros(nNodes, 1);
    nodeFrequencyInTop = zeros(nNodes, 1);
    
    % Count frequency in all valid solutions
    for i = 1:validRuns
        solution = validSolutions{i};
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
    coreNodes = find(nodeFrequencyTopPercent > 50);
    frequentNodes = find(nodeFrequencyTopPercent > 25);
    
    % Store results
    nodeAnalysis = struct();
    nodeAnalysis.validRuns = validRuns;
    nodeAnalysis.topSolutions = topSolutions;
    nodeAnalysis.topAvgSPs = topAvgSPs;
    nodeAnalysis.nodeFrequency = nodeFrequency;
    nodeAnalysis.nodeFrequencyPercent = nodeFrequencyPercent;
    nodeAnalysis.nodeFrequencyTopPercent = nodeFrequencyTopPercent;
    nodeAnalysis.coreNodes = coreNodes;
    nodeAnalysis.frequentNodes = frequentNodes;
    
    % Create visualization
    figure('Position', [100, 100, 1200, 800]);
    
    % Node frequency bar plot
    subplot(2, 2, 1);
    bar(nodeFrequencyTopPercent);
    title(sprintf('Node Frequency in Top %d%% Solutions', topPercentile));
    xlabel('Node ID');
    ylabel('Frequency (%)');
    grid on;
    if ~isempty(coreNodes)
        hold on;
        bar(coreNodes, nodeFrequencyTopPercent(coreNodes), 'r');
        legend('All nodes', 'Core nodes (>50%)', 'Location', 'best');
    end
    
    % Core nodes details
    subplot(2, 2, 2);
    if ~isempty(coreNodes)
        coreFreqs = nodeFrequencyTopPercent(coreNodes);
        bar(coreFreqs);
        title('Core Nodes Frequency');
        xlabel('Core Node Index');
        ylabel('Frequency in Top Solutions (%)');
        set(gca, 'XTick', 1:length(coreNodes), 'XTickLabel', coreNodes);
        grid on;
    else
        text(0.5, 0.5, 'No core nodes found', 'HorizontalAlignment', 'center', 'FontSize', 14);
        title('No Core Nodes');
    end
    
    % Solution quality distribution
    subplot(2, 2, 3);
    histogram(validAvgSPs, 'Normalization', 'probability');
    hold on;
    xline(threshold, 'r--', 'LineWidth', 2, 'Label', sprintf('Top %d%% threshold', topPercentile));
    title('Solution Quality Distribution');
    xlabel('Average Shortest Path');
    ylabel('Probability');
    grid on;
    
    % Frequency comparison
    subplot(2, 2, 4);
    activeNodes = find(nodeFrequency > 0);
    scatter(nodeFrequencyPercent(activeNodes), nodeFrequencyTopPercent(activeNodes), 'filled');
    hold on;
    plot([0, 100], [0, 100], 'r--', 'LineWidth', 2);
    title('Frequency: All vs Top Solutions');
    xlabel('Frequency in All Solutions (%)');
    ylabel('Frequency in Top Solutions (%)');
    grid on;
    legend('Nodes', 'Equal frequency line', 'Location', 'best');
    
    sgtitle(sprintf('Node Analysis from Existing Results (n=%d, %d solutions)', n, validRuns));
    
    % Save plot
    timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
    filename = sprintf('plots/existing_node_analysis_%s.png', timestamp);
    saveas(gcf, filename);
    fprintf('Node analysis plot saved as: %s\n', filename);
    
    % Print summary
    fprintf('\n=== Node Analysis from Existing Results ===\n');
    fprintf('Valid solutions analyzed: %d\n', validRuns);
    fprintf('Top solutions: %d\n', length(topSolutions));
    fprintf('Core nodes (>50%% frequency): %d\n', length(coreNodes));
    if ~isempty(coreNodes)
        fprintf('Core nodes: [%s]\n', num2str(coreNodes'));
    end
end

function qualityAnalysis = analyzeSolutionQuality(allResults, G, n, Cmax)
% Analyze solution quality distribution from existing results
    
    fprintf('Analyzing solution quality from existing results...\n');
    
    % Extract metrics
    avgSPs = [];
    maxSPs = [];
    solutions = {};
    
    for i = 1:length(allResults)
        if ~isempty(allResults(i).solution) && ~isempty(allResults(i).avgSP)
            avgSPs(end+1) = allResults(i).avgSP;
            maxSPs(end+1) = allResults(i).maxSP;
            solutions{end+1} = allResults(i).solution;
        end
    end
    
    % Filter valid results
    validIdx = ~isinf(avgSPs) & maxSPs <= Cmax;
    validAvgSPs = avgSPs(validIdx);
    validMaxSPs = maxSPs(validIdx);
    validSolutions = solutions(validIdx);
    
    numValid = length(validAvgSPs);
    if numValid == 0
        error('No valid solutions found');
    end
    
    % Calculate statistics
    qualityAnalysis = struct();
    qualityAnalysis.numValid = numValid;
    qualityAnalysis.successRate = 100 * numValid / length(allResults);
    qualityAnalysis.avgSP.mean = mean(validAvgSPs);
    qualityAnalysis.avgSP.std = std(validAvgSPs);
    qualityAnalysis.avgSP.min = min(validAvgSPs);
    qualityAnalysis.avgSP.max = max(validAvgSPs);
    qualityAnalysis.maxSP.mean = mean(validMaxSPs);
    qualityAnalysis.maxSP.std = std(validMaxSPs);
    
    % Create quality analysis plots
    figure('Position', [100, 100, 1200, 600]);
    
    subplot(1, 3, 1);
    histogram(validAvgSPs, 'Normalization', 'probability');
    title('Average Shortest Path Distribution');
    xlabel('Average Shortest Path');
    ylabel('Probability');
    grid on;
    
    subplot(1, 3, 2);
    histogram(validMaxSPs, 'Normalization', 'probability');
    title('Max Shortest Path Distribution');
    xlabel('Max Shortest Path');
    ylabel('Probability');
    grid on;
    
    subplot(1, 3, 3);
    scatter(validAvgSPs, validMaxSPs, 'filled', 'alpha', 0.7);
    xlabel('Average Shortest Path');
    ylabel('Max Shortest Path');
    title('AvgSP vs MaxSP Correlation');
    grid on;
    
    sgtitle(sprintf('Solution Quality Analysis (%d valid solutions)', numValid));
    
    % Save plot
    timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
    filename = sprintf('plots/quality_analysis_%s.png', timestamp);
    saveas(gcf, filename);
    fprintf('Quality analysis plot saved as: %s\n', filename);
    
    % Print summary
    fprintf('\n=== Solution Quality Analysis ===\n');
    fprintf('Total runs: %d\n', length(allResults));
    fprintf('Valid solutions: %d (%.1f%% success rate)\n', numValid, qualityAnalysis.successRate);
    fprintf('Average SP - Mean: %.6f, Std: %.6f, Range: [%.6f, %.6f]\n', ...
            qualityAnalysis.avgSP.mean, qualityAnalysis.avgSP.std, ...
            qualityAnalysis.avgSP.min, qualityAnalysis.avgSP.max);
    fprintf('Max SP - Mean: %.6f, Std: %.6f\n', ...
            qualityAnalysis.maxSP.mean, qualityAnalysis.maxSP.std);
end