function results = runGAComparison(config)
% Compare standard GA vs optimized GA with caching

    % Start diary
    timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
    diaryFile = sprintf('output/GA_comparison_%s.txt', timestamp);
    diary(diaryFile);
    diary on;
    
    fprintf('=== GA COMPARISON: STANDARD vs OPTIMIZED ===\n');
    fprintf('Date and Time: %s\n', datestr(now));
    fprintf('============================================\n\n');
    
    % Load network data
    addpath('../');  % For loadData
    [G, nNodes, nLinks] = loadData();
    
    fprintf('Network loaded: %d nodes, %d links\n', nNodes, nLinks);
    fprintf('Problem parameters: n=%d, Cmax=%d\n', config.problem.n, config.problem.Cmax);
    
    % Use shorter runs for comparison
    comparisonRuns = min(5, config.execution.numRuns);
    comparisonTime = min(20, config.execution.runTime);
    
    fprintf('\nComparison settings:\n');
    fprintf('Number of runs: %d\n', comparisonRuns);
    fprintf('Time per run: %d seconds\n', comparisonTime);
    
    % Run standard GA
    fprintf('\n=== RUNNING STANDARD GA ===\n');
    standardResults = [];
    
    for run = 1:comparisonRuns
        fprintf('\nStandard GA - Run %d/%d\n', run, comparisonRuns);
        runStart = tic;
        
        [solution, objective, maxSP, runResults] = GA(G, config.problem.n, config.problem.Cmax, ...
            config.params.populationSize, config.params.mutationRate, ...
            config.params.eliteCount, comparisonTime);
        
        runTime = toc(runStart);
        
        result = struct();
        result.run = run;
        result.solution = solution;
        result.objective = objective;
        result.maxSP = maxSP;
        result.runResults = runResults;
        result.runTime = runTime;
        result.valid = ~isinf(objective) && maxSP <= config.problem.Cmax;
        result.type = 'Standard';
        
        standardResults = [standardResults, result];
        
        fprintf('Completed: Obj=%.4f, Time=%.2fs, Generations=%d\n', ...
            objective, runTime, length(runResults.generations));
    end
    
    % Run optimized GA
    fprintf('\n=== RUNNING OPTIMIZED GA ===\n');
    optimizedResults = [];
    
    for run = 1:comparisonRuns
        fprintf('\nOptimized GA - Run %d/%d\n', run, comparisonRuns);
        runStart = tic;
        
        [solution, objective, maxSP, runResults] = GAOptimized(G, config.problem.n, config.problem.Cmax, ...
            config.params.populationSize, config.params.mutationRate, ...
            config.params.eliteCount, comparisonTime);
        
        runTime = toc(runStart);
        
        result = struct();
        result.run = run;
        result.solution = solution;
        result.objective = objective;
        result.maxSP = maxSP;
        result.runResults = runResults;
        result.runTime = runTime;
        result.valid = ~isinf(objective) && maxSP <= config.problem.Cmax;
        result.type = 'Optimized';
        result.cacheHitRate = runResults.finalCacheHitRate;
        result.totalEvaluations = runResults.totalEvaluations;
        
        optimizedResults = [optimizedResults, result];
        
        fprintf('Completed: Obj=%.4f, Time=%.2fs, Generations=%d, Cache hit rate=%.1f%%\n', ...
            objective, runTime, length(runResults.generations), result.cacheHitRate*100);
    end
    
    % Analyze comparison results
    fprintf('\n=== COMPARISON RESULTS ===\n');
    
    % Standard GA statistics
    standardValid = [standardResults.valid];
    if any(standardValid)
        standardObjs = [standardResults(standardValid).objective];
        standardTimes = [standardResults(standardValid).runTime];
        standardGens = arrayfun(@(r) length(r.runResults.generations), standardResults(standardValid));
        
        fprintf('\nStandard GA:\n');
        fprintf('  Valid runs: %d/%d\n', sum(standardValid), comparisonRuns);
        fprintf('  Avg objective: %.4f (±%.4f)\n', mean(standardObjs), std(standardObjs));
        fprintf('  Avg runtime: %.2f seconds\n', mean(standardTimes));
        fprintf('  Avg generations: %.0f\n', mean(standardGens));
    end
    
    % Optimized GA statistics
    optimizedValid = [optimizedResults.valid];
    if any(optimizedValid)
        optimizedObjs = [optimizedResults(optimizedValid).objective];
        optimizedTimes = [optimizedResults(optimizedValid).runTime];
        optimizedGens = arrayfun(@(r) length(r.runResults.generations), optimizedResults(optimizedValid));
        optimizedCacheRates = [optimizedResults(optimizedValid).cacheHitRate];
        optimizedEvals = [optimizedResults(optimizedValid).totalEvaluations];
        
        fprintf('\nOptimized GA:\n');
        fprintf('  Valid runs: %d/%d\n', sum(optimizedValid), comparisonRuns);
        fprintf('  Avg objective: %.4f (±%.4f)\n', mean(optimizedObjs), std(optimizedObjs));
        fprintf('  Avg runtime: %.2f seconds\n', mean(optimizedTimes));
        fprintf('  Avg generations: %.0f\n', mean(optimizedGens));
        fprintf('  Avg cache hit rate: %.1f%%\n', mean(optimizedCacheRates)*100);
        fprintf('  Avg evaluations: %.0f\n', mean(optimizedEvals));
    end
    
    % Performance comparison
    if any(standardValid) && any(optimizedValid)
        fprintf('\n=== PERFORMANCE COMPARISON ===\n');
        
        % Solution quality
        qualityImprovement = (mean(standardObjs) - mean(optimizedObjs)) / mean(standardObjs) * 100;
        fprintf('Solution quality improvement: %.2f%%\n', qualityImprovement);
        
        % Speed
        speedup = mean(standardTimes) / mean(optimizedTimes);
        fprintf('Speed improvement: %.2fx faster\n', speedup);
        
        % Efficiency
        standardEvalsPerGen = config.params.populationSize;
        optimizedEvalsPerGen = mean(optimizedEvals) / mean(optimizedGens);
        evalReduction = (1 - optimizedEvalsPerGen/standardEvalsPerGen) * 100;
        fprintf('Evaluation reduction: %.1f%%\n', evalReduction);
        
        % Create comparison plots
        createComparisonPlots(standardResults, optimizedResults, timestamp);
    end
    
    % Save results
    results = struct();
    results.standardResults = standardResults;
    results.optimizedResults = optimizedResults;
    results.config = config;
    results.timestamp = timestamp;
    
    save(sprintf('results/GA_comparison_%s.mat', timestamp), 'results');
    
    diary off;
    fprintf('\nComparison log saved to %s\n', diaryFile);
    fprintf('Results saved to results/GA_comparison_%s.mat\n', timestamp);
end