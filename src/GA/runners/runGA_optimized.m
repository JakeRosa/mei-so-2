function results = runGA_optimized(config)
% Run optimized GA with given configuration
% Returns results structure

    % Start diary
    timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
    diaryFile = sprintf('output/GAOptimized_execution_%s.txt', timestamp);
    diary(diaryFile);
    diary on;
    
    fprintf('=== OPTIMIZED GA EXECUTION ===\n');
    fprintf('Date and Time: %s\n', datestr(now));
    fprintf('===============================\n\n');
    
    % Load network data
    addpath('../');  % For loadData
    [G, nNodes, nLinks] = loadData();
    
    fprintf('Network loaded: %d nodes, %d links\n', nNodes, nLinks);
    fprintf('Problem parameters: n=%d, Cmax=%d\n', config.problem.n, config.problem.Cmax);
    
    % Display GA parameters
    fprintf('\nOptimized GA Parameters:\n');
    fprintf('Population Size: %d\n', config.params.populationSize);
    fprintf('Mutation Rate: %.2f\n', config.params.mutationRate);
    fprintf('Elite Count: %d\n', config.params.eliteCount);
    fprintf('Number of runs: %d\n', config.execution.numRuns);
    fprintf('Time per run: %d seconds\n\n', config.execution.runTime);
    
    % Initialize results storage
    allResults = [];
    
    % Run GAOptimized multiple times
    for run = 1:config.execution.numRuns
        fprintf('\n--- OPTIMIZED RUN %d/%d ---\n', run, config.execution.numRuns);
        runStart = tic;
        
        [solution, objective, maxSP, runResults] = GAOptimized(G, config.problem.n, config.problem.Cmax, ...
            config.params.populationSize, config.params.mutationRate, ...
            config.params.eliteCount, config.execution.runTime);
        
        runTime = toc(runStart);
        
        % Store results
        result = struct();
        result.run = run;
        result.solution = solution;
        result.objective = objective;
        result.maxSP = maxSP;
        result.runResults = runResults;
        result.runTime = runTime;
        result.valid = ~isinf(objective) && maxSP <= config.problem.Cmax;
        
        allResults = [allResults, result];
        
        fprintf('Optimized Run %d completed in %.2f seconds\n', run, runTime);
        fprintf('Objective: %.4f, MaxSP: %.4f, Valid: %s\n', ...
            objective, maxSP, string(result.valid));
        
        % Create convergence plot for this run
        if result.valid && config.output.savePlots
            createConvergencePlot(runResults, run, timestamp);
        end
    end
    
    % Analyze overall results
    fprintf('\n=== OPTIMIZED GA RESULTS ANALYSIS ===\n');
    
    objectives = [allResults.objective];
    maxSPs = [allResults.maxSP];
    validRuns = [allResults.valid];
    
    % Calculate statistics
    validObjectives = objectives(validRuns);
    validMaxSPs = maxSPs(validRuns);
    
    if ~isempty(validObjectives)
        fprintf('\nValid runs: %d/%d (%.0f%%)\n', sum(validRuns), config.execution.numRuns, ...
            (sum(validRuns)/config.execution.numRuns)*100);
        
        fprintf('\nObjective statistics:\n');
        fprintf('  Minimum: %.4f\n', min(validObjectives));
        fprintf('  Average: %.4f\n', mean(validObjectives));
        fprintf('  Maximum: %.4f\n', max(validObjectives));
        if length(validObjectives) > 1
            fprintf('  Std Dev: %.4f\n', std(validObjectives));
        end
        
        fprintf('\nMax shortest path statistics:\n');
        fprintf('  Minimum: %.4f\n', min(validMaxSPs));
        fprintf('  Average: %.4f\n', mean(validMaxSPs));
        fprintf('  Maximum: %.4f\n', max(validMaxSPs));
        
        % Find best run
        [bestObj, bestIdx] = min(validObjectives);
        validIndices = find(validRuns);
        bestRunIdx = validIndices(bestIdx);
        
        fprintf('\n=== BEST OPTIMIZED SOLUTION ===\n');
        fprintf('Run: %d\n', bestRunIdx);
        fprintf('Objective: %.4f\n', allResults(bestRunIdx).objective);
        fprintf('Max shortest path: %.4f\n', allResults(bestRunIdx).maxSP);
        fprintf('Solution: [%s]\n', num2str(allResults(bestRunIdx).solution));
        
        % Create plots
        if config.output.savePlots
            % Best solution network plot
            plotNetworkSolution(G, allResults(bestRunIdx).solution, ...
                allResults(bestRunIdx).objective, ...
                allResults(bestRunIdx).maxSP, ...
                'GAOptimized', bestRunIdx, 'plots/');
            
            % Summary plots
            createGASummaryPlots(allResults, timestamp);
            
            % Phase analysis plots
            createPhaseAnalysisPlots(allResults, timestamp);
        end
        
        % Export results
        if config.output.saveResults
            % Save MAT file
            save(sprintf('results/GAOptimized_results_%s.mat', timestamp), ...
                'allResults', 'config', 'G');
            
            % Export CSV summaries
            exportGAResults(allResults, timestamp);
            
            fprintf('\nOptimized GA results saved to:\n');
            fprintf('  MAT file: results/GAOptimized_results_%s.mat\n', timestamp);
            fprintf('  CSV files: results/GAOptimized_summary_%s.csv\n', timestamp);
        end
        
        % Display convergence characteristics
        fprintf('\n=== OPTIMIZED GA CONVERGENCE ANALYSIS ===\n');
        for i = find(validRuns)
            gens = allResults(i).runResults.generations;
            if ~isempty(gens)
                fprintf('Run %d: %d generations, final objective: %.4f\n', ...
                    i, gens(end), allResults(i).objective);
            end
        end
        
    else
        fprintf('\nNo valid solutions found!\n');
        fprintf('Consider adjusting parameters or constraints.\n');
    end
    
    % Prepare return value
    results = struct();
    results.allResults = allResults;
    results.timestamp = timestamp;
    results.config = config;
    
    diary off;
    fprintf('\nOptimized GA execution log saved to %s\n', diaryFile);
end