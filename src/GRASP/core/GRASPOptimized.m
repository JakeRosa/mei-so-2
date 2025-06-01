function [bestSolution, bestAvgSP, bestMaxSP, results] = GRASPOptimized(G, n, Cmax, r, maxTime, options)
% Optimized GRASP algorithm for Server Node Selection problem
% Inputs:
%   G - graph representing the network
%   n - number of nodes to select
%   Cmax - maximum allowed shortest path length between controllers
%   r - parameter for greedy randomized selection
%   maxTime - maximum running time in seconds
%   options - struct with optimization options:
%     useCaching - enable solution caching (default: true)
%     stagnationLimit - early termination after no improvement (default: 50)
%     trackNodeFreq - track node selection frequency (default: false)
%     verbose - print detailed output (default: true)
% Outputs:
%   bestSolution - best solution found
%   bestAvgSP - avgSP value of best solution
%   bestMaxSP - maximum shortest path between controllers in best solution
%   results - struct with detailed results

    % Default options
    if nargin < 6
        options = struct();
    end
    if ~isfield(options, 'useCaching'), options.useCaching = true; end
    if ~isfield(options, 'stagnationLimit'), options.stagnationLimit = 50; end
    if ~isfield(options, 'trackNodeFreq'), options.trackNodeFreq = false; end
    if ~isfield(options, 'verbose'), options.verbose = true; end

    if options.verbose
        fprintf('Starting Optimized GRASP with n=%d, Cmax=%d, r=%d, maxTime=%d seconds\n', ...
                n, Cmax, r, maxTime);
        if options.useCaching
            fprintf('  - Caching enabled\n');
        end
        if options.stagnationLimit > 0
            fprintf('  - Early termination after %d stagnant iterations\n', options.stagnationLimit);
        end
    end

    % Initialize
    bestSolution = [];
    bestAvgSP = inf;
    bestMaxSP = inf;
    iteration = 0;
    stagnationCount = 0;
    lastImprovementIter = 0;
    startTime = tic;

    % Initialize cache
    if options.useCaching
        cache = containers.Map('KeyType', 'char', 'ValueType', 'any');
        % Initialize stats in the cache
        stats = struct('hits', 0, 'misses', 0);
        cache('stats') = stats;
    end

    % Initialize node frequency tracking
    if options.trackNodeFreq
        nNodes = numnodes(G);
        nodeFrequency = zeros(nNodes, 1);
        bestSolutions = {};
    end

    % Results tracking - pre-allocate for efficiency
    maxIterations = max(1000, maxTime * 10); % Estimate
    results.avgSPs = nan(1, maxIterations);
    results.maxSPs = nan(1, maxIterations);
    results.times = nan(1, maxIterations);
    results.iterations = nan(1, maxIterations);
    results.constructionAvgSPs = nan(1, maxIterations);
    results.improvements = nan(1, maxIterations);

    while toc(startTime) < maxTime && stagnationCount < options.stagnationLimit
        iteration = iteration + 1;

        % Phase 1: Greedy Randomized Construction
        if options.useCaching
            constructedSolution = greedyRandomizedOptimized(G, n, r, Cmax, cache);
        else
            constructedSolution = greedyRandomized(G, n, r, Cmax);
        end

        if isempty(constructedSolution)
            if options.verbose && mod(iteration, 50) == 0
                fprintf('Warning: No valid solution found in iteration %d\n', iteration);
            end
            continue;
        end

        % Evaluate construction phase
        [constructionAvgSP, ~] = PerfSNS(G, constructedSolution);

        % Phase 2: Local Search (Steepest Ascent Hill Climbing)
        solution = steepestAscentHillClimbing(G, constructedSolution, Cmax);

        % Evaluate final solution
        [avgSP, maxSP] = PerfSNS(G, solution);
        improvement = constructionAvgSP - avgSP;

        % Update best solution if better
        improved = false;
        if avgSP < bestAvgSP && maxSP <= Cmax
            bestSolution = solution;
            bestAvgSP = avgSP;
            bestMaxSP = maxSP;
            lastImprovementIter = iteration;
            stagnationCount = 0;
            improved = true;
            
            if options.verbose
                fprintf('New best solution found at iteration %d: %.4f (maxSP: %.4f)\n', ...
                        iteration, bestAvgSP, bestMaxSP);
            end

            % Track node frequency for best solutions
            if options.trackNodeFreq
                bestSolutions{end+1} = solution;
                for node = solution
                    nodeFrequency(node) = nodeFrequency(node) + 1;
                end
            end
        else
            stagnationCount = stagnationCount + 1;
        end

        % Store results
        if iteration <= length(results.avgSPs)
            results.avgSPs(iteration) = avgSP;
            results.maxSPs(iteration) = maxSP;
            results.times(iteration) = toc(startTime);
            results.iterations(iteration) = iteration;
            results.constructionAvgSPs(iteration) = constructionAvgSP;
            results.improvements(iteration) = improvement;
        end

        % Progress report every 50 iterations
        if options.verbose && mod(iteration, 50) == 0
            if options.useCaching && isKey(cache, 'stats')
                cacheStats = cache('stats');
                cacheTotal = cacheStats.hits + cacheStats.misses;
                hitRate = 100 * cacheStats.hits / max(1, cacheTotal);
                fprintf('Iteration %d, Time: %.2f s, Best: %.4f, Cache hit rate: %.1f%%\n', ...
                        iteration, toc(startTime), bestAvgSP, hitRate);
            else
                fprintf('Iteration %d, Time: %.2f s, Best: %.4f, Stagnation: %d\n', ...
                        iteration, toc(startTime), bestAvgSP, stagnationCount);
            end
        end
    end

    % Trim results arrays
    validIdx = ~isnan(results.iterations);
    results.avgSPs = results.avgSPs(validIdx);
    results.maxSPs = results.maxSPs(validIdx);
    results.times = results.times(validIdx);
    results.iterations = results.iterations(validIdx);
    results.constructionAvgSPs = results.constructionAvgSPs(validIdx);
    results.improvements = results.improvements(validIdx);

    totalTime = toc(startTime);
    
    % Add optimization statistics
    results.totalIterations = iteration;
    results.totalTime = totalTime;
    results.lastImprovementIter = lastImprovementIter;
    results.terminationReason = '';
    
    if toc(startTime) >= maxTime
        results.terminationReason = 'time_limit';
    elseif stagnationCount >= options.stagnationLimit
        results.terminationReason = 'stagnation';
    end

    if options.useCaching && isKey(cache, 'stats')
        cacheStats = cache('stats');
        results.cacheHits = cacheStats.hits;
        results.cacheMisses = cacheStats.misses;
        results.cacheHitRate = 100 * cacheStats.hits / max(1, cacheStats.hits + cacheStats.misses);
    end

    if options.trackNodeFreq
        results.nodeFrequency = nodeFrequency;
        results.bestSolutions = bestSolutions;
        results.coreNodes = find(nodeFrequency > 0.5 * length(bestSolutions));
    end

    if options.verbose
        fprintf('\nOptimized GRASP completed:\n');
        fprintf('Total iterations: %d\n', iteration);
        fprintf('Total time: %.2f seconds\n', totalTime);
        fprintf('Termination reason: %s\n', results.terminationReason);
        fprintf('Last improvement at iteration: %d\n', lastImprovementIter);
        fprintf('Best average shortest path: %.4f\n', bestAvgSP);
        fprintf('Best max shortest path: %.4f\n', bestMaxSP);
        fprintf('Best solution: [%s]\n', num2str(bestSolution));
        
        if options.useCaching && isKey(cache, 'stats')
            cacheStats = cache('stats');
            fprintf('Cache statistics: %.1f%% hit rate (%d hits, %d misses)\n', ...
                    results.cacheHitRate, cacheStats.hits, cacheStats.misses);
        end
        
        if options.trackNodeFreq && ~isempty(results.coreNodes)
            fprintf('Core nodes (>50%% frequency): [%s]\n', num2str(results.coreNodes'));
        end
    end

    % Final validation
    if bestMaxSP > Cmax
        warning('Best solution violates Cmax constraint (%.4f > %d)', bestMaxSP, Cmax);
    end

end