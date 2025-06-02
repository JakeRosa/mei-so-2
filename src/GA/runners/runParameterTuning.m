function bestParams = runParameterTuning(config)
% Run parameter tuning for GA
% Returns the best parameters found

    % Start diary
    timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
    diaryFile = sprintf('output/GA_tuning_%s.txt', timestamp);
    diary(diaryFile);
    diary on;
    
    fprintf('=== GA PARAMETER TUNING ===\n');
    fprintf('Date and Time: %s\n', datestr(now));
    fprintf('===========================\n\n');
    
    % Load network data
    addpath('../');  % For loadData
    [G, nNodes, nLinks] = loadData();
    
    fprintf('Network loaded: %d nodes, %d links\n', nNodes, nLinks);
    fprintf('Problem parameters: n=%d, Cmax=%d\n', config.problem.n, config.problem.Cmax);
    
    % Extract parameters to test
    populationSizes = config.tuning.populationSizes;
    mutationRates = config.tuning.mutationRates;
    eliteCounts = config.tuning.eliteCounts;
    testTime = config.tuning.testTime;
    numberOfTests = config.tuning.numberOfTests;
    
    fprintf('\nParameter ranges:\n');
    fprintf('Population sizes: %s\n', mat2str(populationSizes));
    fprintf('Mutation rates: %s\n', mat2str(mutationRates));
    fprintf('Elite counts: %s\n', mat2str(eliteCounts));
    fprintf('Test time: %d seconds\n', testTime);
    fprintf('Tests per configuration: %d\n\n', numberOfTests);
    
    % Initialize results storage
    allResults = [];
    paramCount = 0;
    totalTests = length(populationSizes) * length(mutationRates) * length(eliteCounts);
    
    bestParams = struct();
    bestTestObjective = inf;
    
    % Test each parameter combination
    for popSize = populationSizes
        for mutRate = mutationRates
            for eliteCount = eliteCounts
                paramCount = paramCount + 1;
                fprintf('\nTesting configuration %d/%d:\n', paramCount, totalTests);
                fprintf('PopSize=%d, MutRate=%.2f, EliteCount=%d\n', popSize, mutRate, eliteCount);
                
                % Run multiple tests for this configuration
                testObjectives = [];
                testMaxSPs = [];
                testTimes = [];
                
                for test = 1:numberOfTests
                    fprintf('  Test %d/%d: ', test, numberOfTests);
                    testStart = tic;
                    
                    [~, objective, maxSP, ~] = GA(G, config.problem.n, config.problem.Cmax, ...
                        popSize, mutRate, eliteCount, testTime);
                    
                    testTimes(test) = toc(testStart);
                    testObjectives(test) = objective;
                    testMaxSPs(test) = maxSP;
                    
                    if isinf(objective)
                        fprintf('No valid solution\n');
                    else
                        fprintf('Obj=%.4f, MaxSP=%.4f\n', objective, maxSP);
                    end
                end
                
                % Calculate statistics for this configuration
                validIdx = ~isinf(testObjectives);
                if any(validIdx)
                    validObjectives = testObjectives(validIdx);
                    avgObjective = mean(validObjectives);
                    stdObjective = std(validObjectives);
                    minObjective = min(validObjectives);
                    successRate = sum(validIdx) / numberOfTests;
                    
                    fprintf('Configuration results:\n');
                    fprintf('  Success rate: %.0f%%\n', successRate * 100);
                    fprintf('  Min objective: %.4f\n', minObjective);
                    fprintf('  Avg objective: %.4f (±%.4f)\n', avgObjective, stdObjective);
                    
                    % Store results
                    result = struct();
                    result.popSize = popSize;
                    result.mutRate = mutRate;
                    result.eliteCount = eliteCount;
                    result.objectives = testObjectives;
                    result.maxSPs = testMaxSPs;
                    result.times = testTimes;
                    result.avgObjective = avgObjective;
                    result.stdObjective = stdObjective;
                    result.minObjective = minObjective;
                    result.successRate = successRate;
                    
                    allResults = [allResults, result];
                    
                    % Update best parameters
                    if minObjective < bestTestObjective
                        bestTestObjective = minObjective;
                        bestParams.populationSize = popSize;
                        bestParams.mutationRate = mutRate;
                        bestParams.eliteCount = eliteCount;
                    end
                else
                    fprintf('  No valid solutions found\n');
                end
            end
        end
    end
    
    % Analyze and display results
    fprintf('\n=== TUNING RESULTS SUMMARY ===\n');
    fprintf('Total configurations tested: %d\n', totalTests);
    fprintf('Total individual tests: %d\n', totalTests * numberOfTests);
    
    if ~isempty(allResults)
        % Create parameter analysis plots
        createParameterAnalysisPlots(allResults, timestamp);
        
        % Export results
        exportParameterTuningResults(allResults, timestamp);
        
        % Display best parameters
        fprintf('\n=== BEST PARAMETERS FOUND ===\n');
        fprintf('Population Size: %d\n', bestParams.populationSize);
        fprintf('Mutation Rate: %.2f\n', bestParams.mutationRate);
        fprintf('Elite Count: %d\n', bestParams.eliteCount);
        fprintf('Best objective achieved: %.4f\n', bestTestObjective);
        
        % Find configuration with best average performance
        avgObjectives = [allResults.avgObjective];
        [bestAvg, bestAvgIdx] = min(avgObjectives);
        bestAvgConfig = allResults(bestAvgIdx);
        
        fprintf('\n=== BEST AVERAGE PERFORMANCE ===\n');
        fprintf('Population Size: %d\n', bestAvgConfig.popSize);
        fprintf('Mutation Rate: %.2f\n', bestAvgConfig.mutRate);
        fprintf('Elite Count: %d\n', bestAvgConfig.eliteCount);
        fprintf('Average objective: %.4f (±%.4f)\n', bestAvgConfig.avgObjective, bestAvgConfig.stdObjective);
        
        % Find most stable configuration
        stdObjectives = [allResults.stdObjective];
        validStd = stdObjectives(~isnan(stdObjectives));
        if ~isempty(validStd)
            [minStd, stableIdx] = min(stdObjectives);
            stableConfig = allResults(stableIdx);
            
            fprintf('\n=== MOST STABLE CONFIGURATION ===\n');
            fprintf('Population Size: %d\n', stableConfig.popSize);
            fprintf('Mutation Rate: %.2f\n', stableConfig.mutRate);
            fprintf('Elite Count: %d\n', stableConfig.eliteCount);
            fprintf('Standard deviation: %.4f\n', stableConfig.stdObjective);
            fprintf('Average objective: %.4f\n', stableConfig.avgObjective);
        end
        
        % Save best parameters
        save('results/GA_best_params.mat', 'bestParams');
        save(sprintf('results/GA_tuning_results_%s.mat', timestamp), 'allResults', 'bestParams');
        
        fprintf('\nTuning results saved to results/GA_tuning_results_%s.mat\n', timestamp);
        fprintf('Best parameters saved to results/GA_best_params.mat\n');
    else
        fprintf('\nNo valid configurations found!\n');
    end
    
    diary off;
    fprintf('Tuning log saved to %s\n', diaryFile);
end