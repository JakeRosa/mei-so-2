function [bestSolution, bestObjective, bestMaxSP, results] = GAOptimized(G, n, Cmax, populationSize, mutationRate, eliteCount, maxTime)
% Optimized Genetic Algorithm with caching for Server Node Selection problem
% Includes fitness caching and improved performance tracking

    fprintf('Starting Optimized GA with popSize=%d, mutRate=%.2f, eliteCount=%d, maxTime=%d seconds\n', ...
            populationSize, mutationRate, eliteCount, maxTime);

    addpath('../../'); % Add path to PerfSNS function
    nNodes = numnodes(G);

    % PRE-COMPUTE ALL DISTANCES (MAJOR OPTIMIZATION)
    fprintf('Pre-computing all shortest path distances...\n');
    precomputeStart = tic;
    D = distances(G); % NxN matrix with all pairwise distances
    precomputeTime = toc(precomputeStart);
    fprintf('Distance pre-computation completed in %.2f seconds\n', precomputeTime);

    % Initialize
    bestSolution = [];
    bestObjective = inf;
    bestMaxSP = inf;
    generation = 0;
    startTime = tic;

    % Initialize cache for fitness evaluations
    fitnessCache = containers.Map('KeyType', 'char', 'ValueType', 'any');
    cacheHits = 0;
    totalEvaluations = 0;

    % Results tracking
    results.objectives = [];
    results.maxSPs = [];
    results.avgFitness = [];
    results.bestFitness = [];
    results.times = [];
    results.generations = [];
    results.cacheHitRate = [];
    results.evaluationsPerGen = [];
    results.diversityMetrics = [];

    % Initialize population
    fprintf('Initializing %d random individuals...\n', populationSize);

    population = cell(populationSize, 1);

    % Generate purely random individuals
    for i = 1:populationSize
        selectedNodes = sort(randperm(nNodes, n));
        population{i} = selectedNodes;
    end

    fprintf('Population initialization completed.\n');

    % Evaluate initial population with caching
    fitnessValues = zeros(populationSize, 1);
    avgSPValues = zeros(populationSize, 1);
    maxSPValues = zeros(populationSize, 1);

    for i = 1:populationSize
        [fitnessValues(i), avgSPValues(i), maxSPValues(i), cacheHit] = ...
            evaluateFitnessOptimized(population{i}, D, nNodes, Cmax, fitnessCache);
        if cacheHit
            cacheHits = cacheHits + 1;
        end
        totalEvaluations = totalEvaluations + 1;
    end

    % Update best solution from initial population
    validIndices = maxSPValues <= Cmax;
    if any(validIndices)
        validAvgSP = avgSPValues(validIndices);
        validMaxSP = maxSPValues(validIndices);
        validIndicesArray = find(validIndices);

        [bestObjective, bestIdx] = min(validAvgSP);
        actualBestIdx = validIndicesArray(bestIdx);
        bestSolution = population{actualBestIdx};
        bestMaxSP = validMaxSP(bestIdx);

        fprintf('Initial best solution found: %.4f (maxSP: %.4f)\n', bestObjective, bestMaxSP);
    end

    % Main GA loop
    while toc(startTime) < maxTime
        generation = generation + 1;
        genEvaluations = 0;

        % Create new population through crossover and mutation
        newPopulation = cell(populationSize, 1);

        for i = 1:populationSize
            % Parent selection using tournament selection
            parent1 = tournamentSelection(population, fitnessValues, 3);
            parent2 = tournamentSelection(population, fitnessValues, 3);

            % Crossover
            offspring = crossover(parent1, parent2, n, nNodes);

            % Mutation
            if rand < mutationRate
                offspring = mutation(offspring, nNodes);
            end

            newPopulation{i} = offspring;
        end

        % Evaluate new population with caching
        newFitnessValues = zeros(populationSize, 1);
        newAvgSPValues = zeros(populationSize, 1);
        newMaxSPValues = zeros(populationSize, 1);

        for i = 1:populationSize
            [newFitnessValues(i), newAvgSPValues(i), newMaxSPValues(i), cacheHit] = ...
                evaluateFitnessOptimized(newPopulation{i}, D, nNodes, Cmax, fitnessCache);
            if cacheHit
                cacheHits = cacheHits + 1;
            end
            totalEvaluations = totalEvaluations + 1;
            genEvaluations = genEvaluations + 1;
        end

        % Elitist selection
        [population, fitnessValues, avgSPValues, maxSPValues] = elitistSelection(population, newPopulation, fitnessValues, newFitnessValues, avgSPValues, newAvgSPValues, maxSPValues, newMaxSPValues, eliteCount);

        % Update best solution
        validIndices = maxSPValues <= Cmax;
        if any(validIndices)
            validAvgSP = avgSPValues(validIndices);
            validMaxSP = maxSPValues(validIndices);
            validIndicesArray = find(validIndices);

            [currentBest, bestIdx] = min(validAvgSP);
            if currentBest < bestObjective
                actualBestIdx = validIndicesArray(bestIdx);
                bestSolution = population{actualBestIdx};
                bestObjective = currentBest;
                bestMaxSP = validMaxSP(bestIdx);

                fprintf('New best solution found at generation %d: %.4f (maxSP: %.4f)\n', ...
                        generation, bestObjective, bestMaxSP);
            end
        end

        % Calculate diversity metric
        diversity = calculateDiversity(population);

        % Store results
        results.objectives = [results.objectives, bestObjective];
        results.maxSPs = [results.maxSPs, bestMaxSP];
        results.avgFitness = [results.avgFitness, mean(fitnessValues)];
        results.bestFitness = [results.bestFitness, max(fitnessValues)];
        results.times = [results.times, toc(startTime)];
        results.generations = [results.generations, generation];
        results.cacheHitRate = [results.cacheHitRate, cacheHits/totalEvaluations];
        results.evaluationsPerGen = [results.evaluationsPerGen, genEvaluations];
        results.diversityMetrics = [results.diversityMetrics, diversity];

        % Progress report every 50 generations
        if mod(generation, 50) == 0
            fprintf('Generation %d, Time: %.2f s, Best: %.4f, Avg fitness: %.4f, Cache hit rate: %.2f%%\n', ...
                    generation, toc(startTime), bestObjective, mean(fitnessValues), ...
                    (cacheHits/totalEvaluations)*100);
        end
    end

    totalTime = toc(startTime);
    fprintf('\nOptimized GA completed:\n');
    fprintf('Total generations: %d\n', generation);
    fprintf('Total time: %.2f seconds\n', totalTime);
    fprintf('Total evaluations: %d\n', totalEvaluations);
    fprintf('Cache hits: %d (%.2f%%)\n', cacheHits, (cacheHits/totalEvaluations)*100);
    fprintf('Best objective: %.4f\n', bestObjective);
    fprintf('Best max shortest path: %.4f\n', bestMaxSP);
    fprintf('Best solution: [%s]\n', num2str(bestSolution));

    % Add cache statistics to results
    results.totalEvaluations = totalEvaluations;
    results.cacheHits = cacheHits;
    results.finalCacheHitRate = cacheHits/totalEvaluations;

    % Final validation
    if bestMaxSP > Cmax
        fprintf('Warning: Best solution violates Cmax constraint (%.4f > %d)\n', bestMaxSP, Cmax);
    end
end

function [fitness, avgSP, maxSP, cacheHit] = evaluateFitnessOptimized(individual, D, nNodes, Cmax, cache, penaltyFactor)
% Optimized fitness evaluation using pre-computed distances
% Inputs:
%   individual - vector of selected node indices
%   D - pre-computed distance matrix (NxN)
%   nNodes - total number of nodes
%   Cmax - maximum allowed shortest path length between controllers
%   cache - fitness cache
%   penaltyFactor - penalty factor for constraint violations (optional)

    if nargin < 6
        penaltyFactor = 1000; % Default penalty factor
    end

    % Create cache key from individual
    key = mat2str(individual);
    cacheHit = false;

    % Check cache first
    if isKey(cache, key)
        cachedValue = cache(key);
        fitness = cachedValue.fitness;
        avgSP = cachedValue.avgSP;
        maxSP = cachedValue.maxSP;
        cacheHit = true;
        return;
    end

    % OPTIMIZED EVALUATION - no calls to distances() function
    sNodes = individual;
    
    % Validate input (same as PerfSNS)
    if length(sNodes) < 1
        avgSP = -1;
        maxSP = -1;
        fitness = 0;
        return;
    end
    
    if (max(sNodes) > nNodes || min(sNodes) < 1 || length(unique(sNodes)) < length(sNodes))
        avgSP = -1;
        maxSP = -1;
        fitness = 0;
        return;
    end
    
    % Calculate avgSP using pre-computed distances
    clients = setdiff(1:nNodes, sNodes);
    
    if length(sNodes) > 1
        % Extract distances from servers to clients
        dist_servers_to_clients = D(sNodes, clients);
        
        % For each client, find minimum distance to any server
        min_distances_clients = min(dist_servers_to_clients, [], 1);
        
        % For servers, distance to closest server is 0 (themselves)
        min_distances_servers = zeros(1, length(sNodes));
        
        % Average shortest path for all nodes
        avgSP = (sum(min_distances_clients) + sum(min_distances_servers)) / nNodes;
        
        % Maximum distance between any pair of servers
        dist_servers_to_servers = D(sNodes, sNodes);
        maxSP = max(dist_servers_to_servers(:));
        
    else
        % Single server case
        dist_server_to_clients = D(sNodes, clients);
        avgSP = sum(dist_server_to_clients) / nNodes;
        maxSP = 0;
    end

    % Handle constraint violation
    if maxSP > Cmax
        % Apply penalty for constraint violation
        penalty = penaltyFactor * (maxSP - Cmax);
        objective = avgSP + penalty;
    else
        objective = avgSP;
    end

    % Convert to maximization problem (GA typically maximizes fitness)
    fitness = 1 / (1 + objective); % Higher fitness = better solution

    % Store in cache
    cachedValue.fitness = fitness;
    cachedValue.avgSP = avgSP;
    cachedValue.maxSP = maxSP;
    cache(key) = cachedValue;
end

function diversity = calculateDiversity(population)
    % Calculate population diversity (percentage of unique genes)
    allGenes = [];
    for i = 1:length(population)
        allGenes = [allGenes, population{i}];
    end
    uniqueGenes = length(unique(allGenes));
    totalGenes = length(allGenes);
    diversity = uniqueGenes / totalGenes;
end