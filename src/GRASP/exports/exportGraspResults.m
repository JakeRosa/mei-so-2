function exportGraspResults(allResults, bestR, timestamp)
% Export GRASP results to CSV files for easy analysis and plotting
%
% Inputs:
%   allResults - results from multiple GRASP runs
%   bestR - best r parameter found
%   timestamp - timestamp string for filenames

    if ~exist('results', 'dir')
        mkdir('results');
    end
    
    fprintf('Exporting GRASP results to CSV files...\n');
    
    % 1. Export summary results (one row per run)
    summaryFile = sprintf('results/GRASP_summary_%s.csv', timestamp);
    
    summaryData = {};
    summaryData{1, 1} = 'Run';
    summaryData{1, 2} = 'Final_avgSP';
    summaryData{1, 3} = 'Final_maxSP';
    summaryData{1, 4} = 'Num_Iterations';
    summaryData{1, 5} = 'Total_Time';
    summaryData{1, 6} = 'Best_Iteration';
    summaryData{1, 7} = 'Best_avgSP';
    summaryData{1, 8} = 'Solution';
    
    for run = 1:length(allResults)
        summaryData{run + 1, 1} = run;
        summaryData{run + 1, 2} = allResults(run).avgSP;
        summaryData{run + 1, 3} = allResults(run).maxSP;
        
        if ~isempty(allResults(run).results.avgSPs)
            summaryData{run + 1, 4} = length(allResults(run).results.avgSPs);
            summaryData{run + 1, 5} = max(allResults(run).results.times);
            [bestObj, bestIdx] = min(allResults(run).results.avgSPs);
            summaryData{run + 1, 6} = bestIdx;
            summaryData{run + 1, 7} = bestObj;
        else
            summaryData{run + 1, 4} = 0;
            summaryData{run + 1, 5} = 0;
            summaryData{run + 1, 6} = 0;
            summaryData{run + 1, 7} = inf;
        end
        
        if ~isempty(allResults(run).solution)
            solutionStr = sprintf('[%s]', num2str(allResults(run).solution));
            summaryData{run + 1, 8} = solutionStr;
        else
            summaryData{run + 1, 8} = '[]';
        end
    end
    
    addpath("lib/")
    writeCSV(summaryFile, summaryData);
    fprintf('Summary results saved to: %s\n', summaryFile);
    
    % 2. Export detailed convergence data (one row per iteration)
    convergenceFile = sprintf('results/GRASP_convergence_%s.csv', timestamp);
    
    convergenceData = {};
    convergenceData{1, 1} = 'Run';
    convergenceData{1, 2} = 'Iteration';
    convergenceData{1, 3} = 'Time';
    convergenceData{1, 4} = 'Objective_avgSP';
    convergenceData{1, 5} = 'Objective_maxSP';
    
    rowIdx = 2;
    for run = 1:length(allResults)
        if ~isempty(allResults(run).results.avgSPs)
            for iter = 1:length(allResults(run).results.avgSPs)
                convergenceData{rowIdx, 1} = run;
                convergenceData{rowIdx, 2} = allResults(run).results.iterations(iter);
                convergenceData{rowIdx, 3} = allResults(run).results.times(iter);
                convergenceData{rowIdx, 4} = allResults(run).results.avgSPs(iter);
                convergenceData{rowIdx, 5} = allResults(run).results.maxSPs(iter);
                rowIdx = rowIdx + 1;
            end
        end
    end
    
    writeCSV(convergenceFile, convergenceData);
    fprintf('Convergence data saved to: %s\n', convergenceFile);
    
    % 3. Export metadata
    metadataFile = sprintf('results/GRASP_metadata_%s.csv', timestamp);
    
    metadataData = {};
    metadataData{1, 1} = 'Parameter';
    metadataData{1, 2} = 'Value';
    metadataData{2, 1} = 'Best_r';
    metadataData{2, 2} = bestR;
    metadataData{3, 1} = 'Total_Runs';
    metadataData{3, 2} = length(allResults);
    metadataData{4, 1} = 'Timestamp';
    metadataData{4, 2} = timestamp;
    
    % Add overall statistics
    finalResults = [allResults.avgSP];
    validResults = finalResults(~isinf(finalResults));
    
    if ~isempty(validResults)
        metadataData{5, 1} = 'Best_Overall';
        metadataData{5, 2} = min(validResults);
        metadataData{6, 1} = 'Average_Overall';
        metadataData{6, 2} = mean(validResults);
        metadataData{7, 1} = 'Worst_Overall';
        metadataData{7, 2} = max(validResults);
        metadataData{8, 1} = 'Std_Dev';
        metadataData{8, 2} = std(validResults);
    end
    
    writeCSV(metadataFile, metadataData);
    fprintf('Metadata saved to: %s\n', metadataFile);
    
    fprintf('\nCSV Export Summary:\n');
    fprintf('- Summary: %s (one row per run)\n', summaryFile);
    fprintf('- Convergence: %s (one row per iteration)\n', convergenceFile);
    fprintf('- Metadata: %s (parameters and statistics)\n', metadataFile);
end