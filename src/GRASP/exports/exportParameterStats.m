function exportParameterStats(stats, randomObjectives, testResults, timestamp)
% Export parameter variation statistics to CSV file
%
% Inputs:
%   stats - struct array with statistics for each r value
%   randomObjectives - array of random solution objectives
%   testResults - struct array with results from parameter tuning
%   timestamp - timestamp string for filename

    % Create results directory if it doesn't exist
    if ~exist('results', 'dir')
        mkdir('results');
    end
    
    csvFilename = sprintf('results/GRASP_parameter_stats_%s.csv', timestamp);
    
    % Prepare data for CSV
    csvData = {};
    csvData{1, 1} = 'Parameter_r';
    csvData{1, 2} = 'Min_Objective';
    csvData{1, 3} = 'Avg_Objective';
    csvData{1, 4} = 'Max_Objective';
    csvData{1, 5} = 'Num_Solutions';
    
    % Add data rows for each r value
    for rIdx = 1:length(stats)
        if isfield(stats, 'r') && ~isempty(stats(rIdx).r)
            csvData{rIdx + 1, 1} = stats(rIdx).r;
            csvData{rIdx + 1, 2} = stats(rIdx).min;
            csvData{rIdx + 1, 3} = stats(rIdx).avg;
            csvData{rIdx + 1, 4} = stats(rIdx).max;
            csvData{rIdx + 1, 5} = stats(rIdx).count;
        end
    end
    
    % Add random baseline if available
    if ~isempty(randomObjectives)
        csvData{end + 1, 1} = 'Random';
        csvData{end, 2} = min(randomObjectives);
        csvData{end, 3} = mean(randomObjectives);
        csvData{end, 4} = max(randomObjectives);
        csvData{end, 5} = length(randomObjectives);
    end
    
    % Add best GRASP result from parameter tuning if available
    if exist('testResults', 'var') && ~isempty(testResults)
        bestIdx = 1;
        bestAvgSP = inf;
        for i = 1:length(testResults)
            if testResults(i).avgSP < bestAvgSP
                bestAvgSP = testResults(i).avgSP;
                bestIdx = i;
            end
        end
        csvData{end + 1, 1} = sprintf('GRASP_Best_r%d', testResults(bestIdx).r);
        csvData{end, 2} = testResults(bestIdx).avgSP;
        csvData{end, 3} = testResults(bestIdx).avgSP;
        csvData{end, 4} = testResults(bestIdx).avgSP;
        csvData{end, 5} = 1;
    end
    
    % Write CSV file
    writeCSV(csvFilename, csvData);
    
    fprintf('Statistics table saved to: %s\n', csvFilename);
end