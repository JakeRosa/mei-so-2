function [bestSolution, bestAvgSP, bestMaxSP, results] = GRASP(G, n, Cmax, r, maxTime)
% GRASP algorithm for Server Node Selection problem
% Inputs:
%   G - graph representing the network
%   n - number of nodes to select
%   Cmax - maximum allowed shortest path length between controllers
%   r - parameter for greedy randomized selection
%   maxTime - maximum running time in seconds
% Outputs:
%   bestSolution - best solution found
%   bestAvgSP - avgSP value of best solution
%   bestMaxSP - maximum shortest path between controllers in best solution
%   results - struct with detailed results

    fprintf('Starting GRASP with n=%d, Cmax=%d, r=%d, maxTime=%d seconds\n', ...
            n, Cmax, r, maxTime);

    % Initialize
    bestSolution = [];
    bestAvgSP = inf;
    bestMaxSP = inf;
    iteration = 0;
    startTime = tic;

    % Results tracking
    results.avgSPs = [];
    results.maxSPs = [];
    results.times = [];
    results.iterations = [];

    while toc(startTime) < maxTime
        iteration = iteration + 1;

        % Phase 1: Greedy Randomized Construction
        solution = greedyRandomized(G, n, r, Cmax);

        if isempty(solution)
            fprintf('Warning: No valid solution found in iteration %d\n', iteration);
            continue;
        end

        % Phase 2: Local Search (Steepest Ascent Hill Climbing)
        solution = steepestAscentHillClimbing(G, solution, Cmax);

        % Evaluate final solution
        [avgSP, maxSP] = PerfSNS(G, solution);

        % Update best solution if better
        if avgSP < bestAvgSP && maxSP <= Cmax
            bestSolution = solution;
            bestAvgSP = avgSP;
            bestMaxSP = maxSP;
            fprintf('New best solution found at iteration %d: %.4f (maxSP: %.4f)\n', ...
                    iteration, bestAvgSP, bestMaxSP);
        end

        % Store results
        results.avgSPs = [results.avgSPs, avgSP];
        results.maxSPs = [results.maxSPs, maxSP];
        results.times = [results.times, toc(startTime)];
        results.iterations = [results.iterations, iteration];

        % Progress report every 10 iterations
        if mod(iteration, 10) == 0
            fprintf('Iteration %d, Time: %.2f s, Current best: %.4f\n', ...
                    iteration, toc(startTime), bestAvgSP);
        end
    end

    totalTime = toc(startTime);
    fprintf('\nGRASP completed:\n');
    fprintf('Total iterations: %d\n', iteration);
    fprintf('Total time: %.2f seconds\n', totalTime);
    fprintf('Best average shortest path: %.4f\n', bestAvgSP);
    fprintf('Best max shortest path: %.4f\n', bestMaxSP);
    fprintf('Best solution: [%s]\n', num2str(bestSolution));

    % Final validation
    if bestMaxSP > Cmax
        warning('Best solution violates Cmax constraint (%.4f > %d)', bestMaxSP, Cmax);
    end
end
