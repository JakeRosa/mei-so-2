function exportParameterTuningResults(results, timestamp)
% Export parameter tuning results to CSV

    fprintf('Exporting parameter tuning results...\n');
    
    % Prepare data
    numConfigs = length(results);
    tuningData = cell(numConfigs + 1, 10);
    
    % Headers
    tuningData(1, :) = {'PopSize', 'MutRate', 'EliteCount', ...
                        'MinObjective', 'AvgObjective', 'StdObjective', ...
                        'SuccessRate', 'AvgRuntime', 'NumTests', 'Rank'};
    
    % Sort by average objective
    [~, sortIdx] = sort([results.avgObjective]);
    
    % Fill data
    for i = 1:numConfigs
        idx = sortIdx(i);
        tuningData{i+1, 1} = results(idx).popSize;
        tuningData{i+1, 2} = results(idx).mutRate;
        tuningData{i+1, 3} = results(idx).eliteCount;
        tuningData{i+1, 4} = results(idx).minObjective;
        tuningData{i+1, 5} = results(idx).avgObjective;
        tuningData{i+1, 6} = results(idx).stdObjective;
        tuningData{i+1, 7} = results(idx).successRate;
        tuningData{i+1, 8} = mean(results(idx).times);
        tuningData{i+1, 9} = length(results(idx).objectives);
        tuningData{i+1, 10} = i;  % Rank
    end
    
    % Write CSV
    tuningFile = sprintf('results/GA_parameter_tuning_%s.csv', timestamp);
    writeCSV(tuningFile, tuningData);
    
    % Export detailed test results
    detailedData = {};
    rowIdx = 1;
    
    % Headers
    detailedData(rowIdx, :) = {'ConfigID', 'PopSize', 'MutRate', 'EliteCount', ...
                               'TestNum', 'Objective', 'MaxSP', 'Runtime'};
    rowIdx = rowIdx + 1;
    
    for i = 1:numConfigs
        for j = 1:length(results(i).objectives)
            detailedData{rowIdx, 1} = i;
            detailedData{rowIdx, 2} = results(i).popSize;
            detailedData{rowIdx, 3} = results(i).mutRate;
            detailedData{rowIdx, 4} = results(i).eliteCount;
            detailedData{rowIdx, 5} = j;
            detailedData{rowIdx, 6} = results(i).objectives(j);
            detailedData{rowIdx, 7} = results(i).maxSPs(j);
            detailedData{rowIdx, 8} = results(i).times(j);
            rowIdx = rowIdx + 1;
        end
    end
    
    % Write detailed CSV
    detailedFile = sprintf('results/GA_tuning_detailed_%s.csv', timestamp);
    writeCSV(detailedFile, detailedData);
    
    % Create parameter statistics summary
    uniquePopSizes = unique([results.popSize]);
    uniqueMutRates = unique([results.mutRate]);
    uniqueEliteCounts = unique([results.eliteCount]);
    
    % Population size statistics
    popStatsData = cell(length(uniquePopSizes) + 1, 5);
    popStatsData(1, :) = {'PopSize', 'AvgObjective', 'StdObjective', 'SuccessRate', 'NumConfigs'};
    
    for i = 1:length(uniquePopSizes)
        idx = [results.popSize] == uniquePopSizes(i);
        popStatsData{i+1, 1} = uniquePopSizes(i);
        popStatsData{i+1, 2} = mean([results(idx).avgObjective]);
        popStatsData{i+1, 3} = mean([results(idx).stdObjective]);
        popStatsData{i+1, 4} = mean([results(idx).successRate]);
        popStatsData{i+1, 5} = sum(idx);
    end
    
    popStatsFile = sprintf('results/GA_popsize_stats_%s.csv', timestamp);
    writeCSV(popStatsFile, popStatsData);
    
    % Mutation rate statistics
    mutStatsData = cell(length(uniqueMutRates) + 1, 5);
    mutStatsData(1, :) = {'MutRate', 'AvgObjective', 'StdObjective', 'SuccessRate', 'NumConfigs'};
    
    for i = 1:length(uniqueMutRates)
        idx = [results.mutRate] == uniqueMutRates(i);
        mutStatsData{i+1, 1} = uniqueMutRates(i);
        mutStatsData{i+1, 2} = mean([results(idx).avgObjective]);
        mutStatsData{i+1, 3} = mean([results(idx).stdObjective]);
        mutStatsData{i+1, 4} = mean([results(idx).successRate]);
        mutStatsData{i+1, 5} = sum(idx);
    end
    
    mutStatsFile = sprintf('results/GA_mutrate_stats_%s.csv', timestamp);
    writeCSV(mutStatsFile, mutStatsData);
    
    % Elite count statistics
    eliteStatsData = cell(length(uniqueEliteCounts) + 1, 5);
    eliteStatsData(1, :) = {'EliteCount', 'AvgObjective', 'StdObjective', 'SuccessRate', 'NumConfigs'};
    
    for i = 1:length(uniqueEliteCounts)
        idx = [results.eliteCount] == uniqueEliteCounts(i);
        eliteStatsData{i+1, 1} = uniqueEliteCounts(i);
        eliteStatsData{i+1, 2} = mean([results(idx).avgObjective]);
        eliteStatsData{i+1, 3} = mean([results(idx).stdObjective]);
        eliteStatsData{i+1, 4} = mean([results(idx).successRate]);
        eliteStatsData{i+1, 5} = sum(idx);
    end
    
    eliteStatsFile = sprintf('results/GA_elitecount_stats_%s.csv', timestamp);
    writeCSV(eliteStatsFile, eliteStatsData);
    
    fprintf('Parameter tuning results exported successfully.\n');
end