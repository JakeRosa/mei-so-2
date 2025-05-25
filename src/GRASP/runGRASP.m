function runGRASP()
% Main script to run GRASP algorithm with different parameter settings
% and find the best configuration

    % Create timestamped log filename
    timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
    logFilename = sprintf('output/GRASP_output_%s.txt', timestamp);
    
    fprintf('Starting GRASP run - output will be saved to: %s\n', logFilename);
    
    % Start logging to file
    diary(logFilename);
    diary on;

    addpath('../'); % Add path to PerfSNS and plotting functions

    % Load network data
    [G, nNodes, nLinks] = loadData();

    % Problem parameters
    n = 12;        % Number of nodes to select
    Cmax = 1000;   % Maximum shortest path constraint

    % Test different parameter values to find best settings
    fprintf('=== PARAMETER TUNING ===\n');

    % Test different r values
    rValues = [1, 2, 3, 5, 8, 10];
    testTime = 60; % seconds for each test

    bestR = 2;
    bestTestAvgSP = inf;

    for r = rValues
        fprintf('\nTesting r = %d...\n', r);
        [~, avgSP, ~, ~] = GRASP(G, n, Cmax, r, testTime);

        if avgSP < bestTestAvgSP
            bestTestAvgSP = avgSP;
            bestR = r;
        end

        fprintf('r = %d, Best average shortest path = %.4f\n', r, avgSP);
    end

    fprintf('\n=== BEST PARAMETER FOUND ===\n');
    fprintf('Best r = %d with average shortest path = %.4f\n', bestR, bestTestAvgSP);

    % Now run 10 times with best parameters and 30 seconds each
    fprintf('\n=== RUNNING 10 TIMES WITH BEST SETTINGS ===\n');

    numRuns = 10;
    runTime = 30; % seconds per run

    allResults = [];

    for run = 1:numRuns
        fprintf('\n--- RUN %d/%d ---\n', run, numRuns);

        [solution, avgSP, maxSP, results] = GRASP(G, n, Cmax, bestR, runTime);

        allResults(run).solution = solution;
        allResults(run).avgSP = avgSP;
        allResults(run).maxSP = maxSP;
        allResults(run).results = results;

        fprintf('Run %d completed: avgSP = %.4f, maxSP = %.4f\n', ...
                run, avgSP, maxSP);
    end

    % Analyze results
    fprintf('\n=== FINAL RESULTS ANALYSIS ===\n');

    avgSPs = [allResults.avgSP];
    maxSPs = [allResults.maxSP];

    % Remove invalid results (inf values)
    validIdx = ~isinf(avgSPs);
    validAvgSPs = avgSPs(validIdx);
    validMaxSPs = maxSPs(validIdx);

    if ~isempty(validAvgSPs)
        fprintf('Valid runs: %d/%d\n', sum(validIdx), numRuns);
        fprintf('Minimum avgSP: %.4f\n', min(validAvgSPs));
        fprintf('Average avgSP: %.4f\n', mean(validAvgSPs));
        fprintf('Maximum avgSP: %.4f\n', max(validAvgSPs));
        fprintf('Standard deviation: %.4f\n', std(validAvgSPs));

        fprintf('\nMaximum shortest path statistics:\n');
        fprintf('Minimum maxSP: %.4f\n', min(validMaxSPs));
        fprintf('Average maxSP: %.4f\n', mean(validMaxSPs));
        fprintf('Maximum maxSP: %.4f\n', max(validMaxSPs));

        % Find best run
        [bestAvgSP, bestIdx] = min(validAvgSPs);
        validIndices = find(validIdx);
        bestRunIdx = validIndices(bestIdx);

        fprintf('\nBest run (#%d):\n', bestRunIdx);
        fprintf('Solution: [%s]\n', num2str(allResults(bestRunIdx).solution));
        fprintf('Average shortest path: %.4f\n', allResults(bestRunIdx).avgSP);
        fprintf('Max shortest path: %.4f\n', allResults(bestRunIdx).maxSP);

        % Create special plot for best solution
        if ~isempty(allResults(bestRunIdx).solution)
            plotNetworkSolution(G, allResults(bestRunIdx).solution, ...
                              allResults(bestRunIdx).avgSP, ...
                              allResults(bestRunIdx).maxSP, ...
                              'GRASP_BEST', bestRunIdx, 'plots/');
        end

        % Save results
        save('results/GRASP_results.mat', 'allResults', 'bestR', 'G', 'n', 'Cmax');
        fprintf('\nResults saved to GRASP_results.mat\n');
    else
        fprintf('No valid solutions found!\n');
    end

    % Stop logging
    diary off;
    
    fprintf('\nOutput successfully saved to: %s\n', logFilename);
    fprintf('Plots saved to plots/ directory\n');
end
