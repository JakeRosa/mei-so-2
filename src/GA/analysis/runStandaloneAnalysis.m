function runStandaloneAnalysis()
% Run standalone analysis on existing GA results

    fprintf('=== GA STANDALONE ANALYSIS ===\n');
    fprintf('Date and Time: %s\n', datestr(now));
    fprintf('==============================\n\n');
    
    % Load most recent results
    resultFiles = dir('results/GA_results_*.mat');
    
    if isempty(resultFiles)
        fprintf('No GA results found in results directory.\n');
        return;
    end
    
    % Sort by date (newest first)
    [~, idx] = sort([resultFiles.datenum], 'descend');
    resultFiles = resultFiles(idx);
    
    fprintf('Found %d result files.\n', length(resultFiles));
    fprintf('Loading most recent: %s\n', resultFiles(1).name);
    
    % Load results
    load(fullfile('results', resultFiles(1).name));
    
    % Extract timestamp from filename
    tokens = regexp(resultFiles(1).name, 'GA_results_(.+)\.mat', 'tokens');
    if ~isempty(tokens)
        timestamp = tokens{1}{1};
    else
        timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
    end
    
    % Run comprehensive analysis
    fprintf('\n=== ANALYZING RESULTS ===\n');
    
    % Basic statistics
    analyzeBasicStatistics(allResults);
    
    % Convergence analysis
    analyzeConvergence(allResults);
    
    % Solution quality analysis
    analyzeSolutionQuality(allResults, G);
    
    % Node frequency analysis
    analyzeNodeFrequency(allResults);
    
    % Create all plots
    fprintf('\n=== CREATING ANALYSIS PLOTS ===\n');
    
    % Summary plots
    createGASummaryPlots(allResults, timestamp);
    
    % Phase analysis
    createPhaseAnalysisPlots(allResults, timestamp);
    
    % Additional analysis plots
    createDetailedAnalysisPlots(allResults, timestamp);
    
    % Export detailed report
    exportAnalysisReport(allResults, timestamp);
    
    fprintf('\n=== ANALYSIS COMPLETE ===\n');
    fprintf('Plots saved to plots/ directory\n');
    fprintf('Report saved to results/GA_analysis_report_%s.txt\n', timestamp);
end

function analyzeBasicStatistics(allResults)
    fprintf('\n--- Basic Statistics ---\n');
    
    objectives = [allResults.objective];
    validRuns = [allResults.valid];
    validObjectives = objectives(validRuns);
    
    fprintf('Total runs: %d\n', length(allResults));
    fprintf('Valid runs: %d (%.1f%%)\n', sum(validRuns), sum(validRuns)/length(allResults)*100);
    
    if ~isempty(validObjectives)
        fprintf('Best objective: %.4f\n', min(validObjectives));
        fprintf('Average objective: %.4f ± %.4f\n', mean(validObjectives), std(validObjectives));
        fprintf('Worst objective: %.4f\n', max(validObjectives));
        fprintf('Coefficient of variation: %.2f%%\n', std(validObjectives)/mean(validObjectives)*100);
    end
end

function analyzeConvergence(allResults)
    fprintf('\n--- Convergence Analysis ---\n');
    
    validResults = allResults([allResults.valid]);
    
    if isempty(validResults)
        fprintf('No valid results for convergence analysis.\n');
        return;
    end
    
    % Average generations
    generations = arrayfun(@(r) length(r.runResults.generations), validResults);
    fprintf('Average generations: %.0f ± %.0f\n', mean(generations), std(generations));
    
    % Convergence speed
    convergenceTimes = [];
    for i = 1:length(validResults)
        if isfield(validResults(i).runResults, 'objectives') && ...
           isfield(validResults(i).runResults, 'times')
            objs = validResults(i).runResults.objectives;
            times = validResults(i).runResults.times;
            
            if length(objs) > 1
                % Time to reach 90% of improvement
                initialObj = objs(1);
                finalObj = objs(end);
                target = initialObj - 0.9 * (initialObj - finalObj);
                
                idx = find(objs <= target, 1);
                if ~isempty(idx) && idx <= length(times)
                    convergenceTimes(end+1) = times(idx);
                end
            end
        end
    end
    
    if ~isempty(convergenceTimes)
        fprintf('Average time to 90%% convergence: %.1f ± %.1f seconds\n', ...
            mean(convergenceTimes), std(convergenceTimes));
    end
    
    % Improvement frequency
    totalImprovements = 0;
    totalGenerations = 0;
    
    for i = 1:length(validResults)
        if isfield(validResults(i).runResults, 'objectives')
            objs = validResults(i).runResults.objectives;
            if length(objs) > 1
                totalImprovements = totalImprovements + sum(diff(objs) < 0);
                totalGenerations = totalGenerations + length(objs) - 1;
            end
        end
    end
    
    if totalGenerations > 0
        fprintf('Overall improvement rate: %.1f%%\n', totalImprovements/totalGenerations*100);
    end
end

function analyzeSolutionQuality(allResults, G)
    fprintf('\n--- Solution Quality Analysis ---\n');
    
    validResults = allResults([allResults.valid]);
    
    if isempty(validResults)
        fprintf('No valid results for quality analysis.\n');
        return;
    end
    
    % Constraint satisfaction
    maxSPs = [validResults.maxSP];
    Cmax = 1000;  % Should get from config
    
    fprintf('Constraint satisfaction: %d/%d (%.1f%%)\n', ...
        sum(maxSPs <= Cmax), length(maxSPs), sum(maxSPs <= Cmax)/length(maxSPs)*100);
    
    % Solution diversity
    solutions = {validResults.solution};
    uniqueSolutions = unique(cellfun(@(x) mat2str(sort(x)), solutions, 'UniformOutput', false));
    
    fprintf('Unique solutions found: %d/%d (%.1f%%)\n', ...
        length(uniqueSolutions), length(solutions), ...
        length(uniqueSolutions)/length(solutions)*100);
    
    % Best solution details
    [bestObj, bestIdx] = min([validResults.objective]);
    bestSolution = validResults(bestIdx).solution;
    
    fprintf('\nBest solution found:\n');
    fprintf('  Objective: %.4f\n', bestObj);
    fprintf('  Max shortest path: %.4f\n', validResults(bestIdx).maxSP);
    fprintf('  Nodes: [%s]\n', num2str(bestSolution));
end

function analyzeNodeFrequency(allResults)
    fprintf('\n--- Node Frequency Analysis ---\n');
    
    validResults = allResults([allResults.valid]);
    
    if isempty(validResults)
        fprintf('No valid results for node frequency analysis.\n');
        return;
    end
    
    % Count node appearances
    nodeCount = containers.Map('KeyType', 'int32', 'ValueType', 'int32');
    
    for i = 1:length(validResults)
        solution = validResults(i).solution;
        for node = solution
            if isKey(nodeCount, node)
                nodeCount(node) = nodeCount(node) + 1;
            else
                nodeCount(node) = 1;
            end
        end
    end
    
    % Sort by frequency
    nodes = keys(nodeCount);
    counts = values(nodeCount);
    nodes = cell2mat(nodes);
    counts = cell2mat(counts);
    
    [sortedCounts, sortIdx] = sort(counts, 'descend');
    sortedNodes = nodes(sortIdx);
    
    % Display top 10 most frequent nodes
    fprintf('\nTop 10 most frequently selected nodes:\n');
    for i = 1:min(10, length(sortedNodes))
        fprintf('  Node %d: %d times (%.1f%%)\n', ...
            sortedNodes(i), sortedCounts(i), ...
            sortedCounts(i)/length(validResults)*100);
    end
end

function createDetailedAnalysisPlots(allResults, timestamp)
    % Create additional detailed analysis plots
    
    validResults = allResults([allResults.valid]);
    
    if isempty(validResults)
        return;
    end
    
    %% Node selection heatmap
    figure('Position', [100, 100, 1200, 800]);
    
    % Create node frequency matrix
    maxNode = 200;  % Assuming network has 200 nodes
    nodeMatrix = zeros(length(validResults), maxNode);
    
    for i = 1:length(validResults)
        solution = validResults(i).solution;
        nodeMatrix(i, solution) = 1;
    end
    
    % Create heatmap
    imagesc(nodeMatrix);
    colormap([1 1 1; 0 0 1]);  % White for not selected, blue for selected
    xlabel('Node ID');
    ylabel('Run Number');
    title('Node Selection Pattern Across Runs');
    colorbar;
    
    saveas(gcf, sprintf('plots/analysis/node_selection_heatmap_%s.png', timestamp));
    close(gcf);
    
    %% Solution similarity analysis
    figure('Position', [100, 100, 1000, 800]);
    
    % Calculate Jaccard similarity between solutions
    numSolutions = length(validResults);
    similarity = zeros(numSolutions, numSolutions);
    
    for i = 1:numSolutions
        for j = 1:numSolutions
            sol1 = validResults(i).solution;
            sol2 = validResults(j).solution;
            
            intersection = length(intersect(sol1, sol2));
            union = length(union(sol1, sol2));
            
            similarity(i, j) = intersection / union;
        end
    end
    
    % Plot similarity matrix
    imagesc(similarity);
    colormap('hot');
    colorbar;
    xlabel('Solution Index');
    ylabel('Solution Index');
    title('Solution Similarity Matrix (Jaccard Index)');
    
    saveas(gcf, sprintf('plots/analysis/solution_similarity_%s.png', timestamp));
    close(gcf);
end

function exportAnalysisReport(allResults, timestamp)
    % Export detailed analysis report
    
    reportFile = sprintf('results/GA_analysis_report_%s.txt', timestamp);
    fid = fopen(reportFile, 'w');
    
    fprintf(fid, 'GENETIC ALGORITHM ANALYSIS REPORT\n');
    fprintf(fid, '=================================\n\n');
    fprintf(fid, 'Generated: %s\n\n', datestr(now));
    
    % Summary statistics
    fprintf(fid, '1. SUMMARY STATISTICS\n');
    fprintf(fid, '--------------------\n');
    
    objectives = [allResults.objective];
    validRuns = [allResults.valid];
    validObjectives = objectives(validRuns);
    
    fprintf(fid, 'Total runs: %d\n', length(allResults));
    fprintf(fid, 'Valid runs: %d (%.1f%%)\n', sum(validRuns), sum(validRuns)/length(allResults)*100);
    
    if ~isempty(validObjectives)
        fprintf(fid, 'Best objective: %.4f\n', min(validObjectives));
        fprintf(fid, 'Average objective: %.4f ± %.4f\n', mean(validObjectives), std(validObjectives));
        fprintf(fid, 'Worst objective: %.4f\n', max(validObjectives));
    end
    
    % Detailed results
    fprintf(fid, '\n2. DETAILED RUN RESULTS\n');
    fprintf(fid, '----------------------\n');
    fprintf(fid, 'Run\tObjective\tMaxSP\t\tValid\tGenerations\tRuntime\n');
    fprintf(fid, '---\t---------\t-----\t\t-----\t-----------\t-------\n');
    
    for i = 1:length(allResults)
        gens = 0;
        if isfield(allResults(i).runResults, 'generations') && ...
           ~isempty(allResults(i).runResults.generations)
            gens = allResults(i).runResults.generations(end);
        end
        
        fprintf(fid, '%d\t%.4f\t\t%.4f\t\t%s\t%d\t\t%.1f s\n', ...
            i, allResults(i).objective, allResults(i).maxSP, ...
            string(allResults(i).valid), gens, allResults(i).runTime);
    end
    
    % Best solution
    if ~isempty(validObjectives)
        [~, bestIdx] = min(validObjectives);
        validIndices = find(validRuns);
        bestRunIdx = validIndices(bestIdx);
        
        fprintf(fid, '\n3. BEST SOLUTION DETAILS\n');
        fprintf(fid, '------------------------\n');
        fprintf(fid, 'Run number: %d\n', bestRunIdx);
        fprintf(fid, 'Objective: %.4f\n', allResults(bestRunIdx).objective);
        fprintf(fid, 'Max shortest path: %.4f\n', allResults(bestRunIdx).maxSP);
        fprintf(fid, 'Solution nodes: [%s]\n', num2str(allResults(bestRunIdx).solution));
    end
    
    fclose(fid);
end