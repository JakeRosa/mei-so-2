function runGA()
% Main script to run GA algorithm with different parameter settings
% and find the best configuration

    % Start diary to capture all output
    diary('output/GA_output.txt');
    diary on;
    
    fprintf('=== GENETIC ALGORITHM EXECUTION LOG ===\n');
    fprintf('Date and Time: %s\n', datestr(now));
    fprintf('========================================\n\n');
    
    addpath('../'); % Add path to PerfSNS and plotting functions
    
    % Load network data
    [G, nNodes, nLinks] = loadData();
    
    % Problem parameters
    n = 12;        % Number of nodes to select
    Cmax = 1000;   % Maximum shortest path constraint
    
    % Test different parameter values to find best settings
    fprintf('=== PARAMETER TUNING ===\n');
    
    % GA Parameters to test
    populationSizes = [20, 50, 100, 150];
    mutationRates = [0.05, 0.1, 0.2];
    eliteCounts = [1, 5, 10];
    testTime = 30; % seconds for each test
    
    bestParams = struct();
    bestTestObjective = inf;
    
    paramCount = 0;
    totalTests = length(populationSizes) * length(mutationRates) * length(eliteCounts);
    
    for popSize = populationSizes
        for mutRate = mutationRates
            for eliteCount = eliteCounts
                paramCount = paramCount + 1;
                fprintf('\nTesting configuration %d/%d:\n', paramCount, totalTests);
                fprintf('PopSize=%d, MutRate=%.1f, EliteCount=%d\n', popSize, mutRate, eliteCount);
                
                [~, objective, ~, ~] = GA(G, n, Cmax, popSize, mutRate, eliteCount, testTime);
                
                if objective < bestTestObjective && ~isinf(objective)
                    bestTestObjective = objective;
                    bestParams.populationSize = popSize;
                    bestParams.mutationRate = mutRate;
                    bestParams.eliteCount = eliteCount;
                end
                
                fprintf('Result: %.4f\n', objective);
            end
        end
    end
    
    fprintf('\n=== BEST PARAMETERS FOUND ===\n');
    fprintf('Population Size: %d\n', bestParams.populationSize);
    fprintf('Mutation Rate: %.1f\n', bestParams.mutationRate);
    fprintf('Elite Count: %d\n', bestParams.eliteCount);
    fprintf('Best objective: %.4f\n', bestTestObjective);
    
    % Now run 10 times with best parameters and 30 seconds each
    fprintf('\n=== RUNNING 10 TIMES WITH BEST SETTINGS ===\n');
    
    numRuns = 10;
    runTime = 30; % seconds per run
    
    allResults = [];
    
    for run = 1:numRuns
        fprintf('\n--- RUN %d/%d ---\n', run, numRuns);
        
        [solution, objective, maxSP, results] = GA(G, n, Cmax, ...
            bestParams.populationSize, bestParams.mutationRate, ...
            bestParams.eliteCount, runTime);
        
        allResults(run).solution = solution;
        allResults(run).objective = objective;
        allResults(run).maxSP = maxSP;
        allResults(run).results = results;
        
        fprintf('Run %d completed: objective = %.4f, maxSP = %.4f\n', ...
                run, objective, maxSP);
    end
    
    % Analyze results
    fprintf('\n=== FINAL RESULTS ANALYSIS ===\n');
    
    objectives = [allResults.objective];
    maxSPs = [allResults.maxSP];
    
    % Remove invalid results (inf values)
    validIdx = ~isinf(objectives);
    validObjectives = objectives(validIdx);
    validMaxSPs = maxSPs(validIdx);
    
    if ~isempty(validObjectives)
        fprintf('Valid runs: %d/%d\n', sum(validIdx), numRuns);
        fprintf('Minimum objective: %.4f\n', min(validObjectives));
        fprintf('Average objective: %.4f\n', mean(validObjectives));
        fprintf('Maximum objective: %.4f\n', max(validObjectives));
        
        if length(validObjectives) > 1
            fprintf('Standard deviation: %.4f\n', std(validObjectives));
        end
        
        fprintf('\nMaximum shortest path statistics:\n');
        fprintf('Minimum maxSP: %.4f\n', min(validMaxSPs));
        fprintf('Average maxSP: %.4f\n', mean(validMaxSPs));
        fprintf('Maximum maxSP: %.4f\n', max(validMaxSPs));
        
        % Find best run
        [bestObj, bestIdx] = min(validObjectives);
        validIndices = find(validIdx);
        bestRunIdx = validIndices(bestIdx);
        
        fprintf('\nBest run (#%d):\n', bestRunIdx);
        fprintf('Solution: [%s]\n', num2str(allResults(bestRunIdx).solution));
        fprintf('Objective: %.4f\n', allResults(bestRunIdx).objective);
        fprintf('Max shortest path: %.4f\n', allResults(bestRunIdx).maxSP);
        
        % Create special plot for best solution
        if ~isempty(allResults(bestRunIdx).solution)
            plotNetworkSolution(G, allResults(bestRunIdx).solution, ...
                              allResults(bestRunIdx).objective, ...
                              allResults(bestRunIdx).maxSP, ...
                              'GA_BEST', bestRunIdx, 'plots/');
        end
        
        % Save results
        save('results/GA_results.mat', 'allResults', 'bestParams', 'G', 'n', 'Cmax');
        fprintf('\nResults saved to GA_results.mat\n');
        
        % Additional detailed statistics
        fprintf('\n=== DETAILED STATISTICS ===\n');
        fprintf('Best parameters found:\n');
        fprintf('  Population Size: %d\n', bestParams.populationSize);
        fprintf('  Mutation Rate: %.1f\n', bestParams.mutationRate);
        fprintf('  Elite Count: %d\n', bestParams.eliteCount);
        fprintf('Runtime per test: %d seconds\n', testTime);
        fprintf('Runtime per final run: %d seconds\n', runTime);
        fprintf('Problem instance: n = %d, Cmax = %d\n', n, Cmax);
        fprintf('Network size: %d nodes, %d links\n', nNodes, nLinks);
        
        fprintf('\nAll run results:\n');
        fprintf('Run\tObjective\tmaxSP\t\tConstraint OK\n');
        fprintf('---\t---------\t-----\t\t-------------\n');
        for i = 1:numRuns
            constraintOK = allResults(i).maxSP <= Cmax;
            fprintf('%d\t%.4f\t\t%.4f\t\t%s\n', i, allResults(i).objective, ...
                   allResults(i).maxSP, string(constraintOK));
        end
        
    else
        fprintf('No valid solutions found!\n');
    end
    
    % Stop diary
    diary off;
    fprintf('\nOutput saved to GA_output.txt\n');
    fprintf('Plots saved to plots/ directory\n');
end
