function exportGAResults(allResults, timestamp)
% Export GA results to CSV files

    fprintf('Exporting GA results to CSV...\n');
    
    % Prepare summary data
    numRuns = length(allResults);
    summaryData = cell(numRuns + 1, 10);
    
    % Headers
    summaryData(1, :) = {'Run', 'Objective', 'MaxSP', 'Valid', 'Runtime', ...
                         'Generations', 'FinalFitness', 'AvgFitness', ...
                         'CacheHitRate', 'TotalEvaluations'};
    
    % Fill data
    for i = 1:numRuns
        summaryData{i+1, 1} = i;
        summaryData{i+1, 2} = allResults(i).objective;
        summaryData{i+1, 3} = allResults(i).maxSP;
        summaryData{i+1, 4} = allResults(i).valid;
        summaryData{i+1, 5} = allResults(i).runTime;
        
        if isfield(allResults(i).runResults, 'generations') && ...
           ~isempty(allResults(i).runResults.generations)
            summaryData{i+1, 6} = allResults(i).runResults.generations(end);
        else
            summaryData{i+1, 6} = 0;
        end
        
        if isfield(allResults(i).runResults, 'bestFitness') && ...
           ~isempty(allResults(i).runResults.bestFitness)
            summaryData{i+1, 7} = allResults(i).runResults.bestFitness(end);
        else
            summaryData{i+1, 7} = NaN;
        end
        
        if isfield(allResults(i).runResults, 'avgFitness') && ...
           ~isempty(allResults(i).runResults.avgFitness)
            summaryData{i+1, 8} = mean(allResults(i).runResults.avgFitness);
        else
            summaryData{i+1, 8} = NaN;
        end
        
        if isfield(allResults(i).runResults, 'finalCacheHitRate')
            summaryData{i+1, 9} = allResults(i).runResults.finalCacheHitRate;
        else
            summaryData{i+1, 9} = NaN;
        end
        
        if isfield(allResults(i).runResults, 'totalEvaluations')
            summaryData{i+1, 10} = allResults(i).runResults.totalEvaluations;
        else
            summaryData{i+1, 10} = NaN;
        end
    end
    
    % Write summary CSV
    summaryFile = sprintf('results/GA_summary_%s.csv', timestamp);
    writeCSV(summaryFile, summaryData);
    
    % Export convergence data for valid runs
    validRuns = find([allResults.valid]);
    
    for i = 1:length(validRuns)
        runIdx = validRuns(i);
        
        if isfield(allResults(runIdx).runResults, 'generations')
            convergenceData = cell(length(allResults(runIdx).runResults.generations) + 1, 6);
            
            % Headers
            convergenceData(1, :) = {'Generation', 'Time', 'BestObjective', ...
                                     'AvgFitness', 'BestFitness', 'CacheHitRate'};
            
            % Fill data
            for j = 1:length(allResults(runIdx).runResults.generations)
                convergenceData{j+1, 1} = allResults(runIdx).runResults.generations(j);
                
                if isfield(allResults(runIdx).runResults, 'times') && ...
                   j <= length(allResults(runIdx).runResults.times)
                    convergenceData{j+1, 2} = allResults(runIdx).runResults.times(j);
                else
                    convergenceData{j+1, 2} = NaN;
                end
                
                if isfield(allResults(runIdx).runResults, 'objectives') && ...
                   j <= length(allResults(runIdx).runResults.objectives)
                    convergenceData{j+1, 3} = allResults(runIdx).runResults.objectives(j);
                else
                    convergenceData{j+1, 3} = NaN;
                end
                
                if isfield(allResults(runIdx).runResults, 'avgFitness') && ...
                   j <= length(allResults(runIdx).runResults.avgFitness)
                    convergenceData{j+1, 4} = allResults(runIdx).runResults.avgFitness(j);
                else
                    convergenceData{j+1, 4} = NaN;
                end
                
                if isfield(allResults(runIdx).runResults, 'bestFitness') && ...
                   j <= length(allResults(runIdx).runResults.bestFitness)
                    convergenceData{j+1, 5} = allResults(runIdx).runResults.bestFitness(j);
                else
                    convergenceData{j+1, 5} = NaN;
                end
                
                if isfield(allResults(runIdx).runResults, 'cacheHitRate') && ...
                   j <= length(allResults(runIdx).runResults.cacheHitRate)
                    convergenceData{j+1, 6} = allResults(runIdx).runResults.cacheHitRate(j);
                else
                    convergenceData{j+1, 6} = NaN;
                end
            end
            
            % Write convergence CSV
            convergenceFile = sprintf('results/GA_convergence_run%d_%s.csv', runIdx, timestamp);
            writeCSV(convergenceFile, convergenceData);
        end
    end
    
    % Export best solution
    validObjectives = [allResults([allResults.valid]).objective];
    if ~isempty(validObjectives)
        [~, bestIdx] = min(validObjectives);
        validIndices = find([allResults.valid]);
        bestRunIdx = validIndices(bestIdx);
        
        bestSolutionData = cell(length(allResults(bestRunIdx).solution) + 1, 2);
        bestSolutionData(1, :) = {'NodeIndex', 'NodeID'};
        
        for i = 1:length(allResults(bestRunIdx).solution)
            bestSolutionData{i+1, 1} = i;
            bestSolutionData{i+1, 2} = allResults(bestRunIdx).solution(i);
        end
        
        bestSolutionFile = sprintf('results/GA_best_solution_%s.csv', timestamp);
        writeCSV(bestSolutionFile, bestSolutionData);
        
        % Also create a metadata file
        metadataData = cell(7, 2);
        metadataData(1, :) = {'Parameter', 'Value'};
        metadataData(2, :) = {'Timestamp', timestamp};
        metadataData(3, :) = {'BestObjective', allResults(bestRunIdx).objective};
        metadataData(4, :) = {'BestMaxSP', allResults(bestRunIdx).maxSP};
        metadataData(5, :) = {'BestRunNumber', bestRunIdx};
        metadataData(6, :) = {'TotalRuns', numRuns};
        metadataData(7, :) = {'ValidRuns', sum([allResults.valid])};
        
        metadataFile = sprintf('results/GA_metadata_%s.csv', timestamp);
        writeCSV(metadataFile, metadataData);
    end
    
    fprintf('GA results exported successfully.\n');
end