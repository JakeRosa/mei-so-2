function [bestSolution, bestObjective, bestMaxSP, results] = GAOptimized(G, n, Cmax, populationSize, mutationRate, eliteCount, maxTime)
% Optimized Genetic Algorithm with caching for Server Node Selection problem
% Includes fitness caching and improved performance tracking

    fprintf('Starting Optimized GA with popSize=%d, mutRate=%.2f, eliteCount=%d, maxTime=%d seconds\n', ...
            populationSize, mutationRate, eliteCount, maxTime);
    
    addpath('../../'); % Add path to PerfSNS function
    nNodes = numnodes(G);
    
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
            evaluateFitnessCached(population{i}, G, Cmax, fitnessCache);
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
            
            % Mutation (only on first node as specified)
            if rand < mutationRate
                offspring = mutationFirstNode(offspring, nNodes);
            end
            
            newPopulation{i} = offspring;
        end
        
        % Evaluate new population with caching
        newFitnessValues = zeros(populationSize, 1);
        newAvgSPValues = zeros(populationSize, 1);
        newMaxSPValues = zeros(populationSize, 1);
        
        for i = 1:populationSize
            [newFitnessValues(i), newAvgSPValues(i), newMaxSPValues(i), cacheHit] = ...
                evaluateFitnessCached(newPopulation{i}, G, Cmax, fitnessCache);
            if cacheHit
                cacheHits = cacheHits + 1;
            end
            totalEvaluations = totalEvaluations + 1;
            genEvaluations = genEvaluations + 1;
        end
        
        % Elitist selection
        population = elitistSelection(population, newPopulation, fitnessValues, newFitnessValues, eliteCount);
        
        % Re-evaluate population after selection
        combinedPopulation = [population; newPopulation];
        combinedFitness = [fitnessValues; newFitnessValues];
        combinedAvgSP = [avgSPValues; newAvgSPValues];
        combinedMaxSP = [maxSPValues; newMaxSPValues];
        
        % Get final fitness values for selected population
        [~, sortedIndices] = sort(combinedFitness, 'descend');
        selectedIndices = sortedIndices(1:populationSize);
        
        fitnessValues = combinedFitness(selectedIndices);
        avgSPValues = combinedAvgSP(selectedIndices);
        maxSPValues = combinedMaxSP(selectedIndices);
        
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

function [fitness, avgSP, maxSP, cacheHit] = evaluateFitnessCached(individual, G, Cmax, cache)
    % Create cache key from individual
    key = mat2str(individual);
    cacheHit = false;
    
    % Check cache
    if isKey(cache, key)
        cachedValue = cache(key);
        fitness = cachedValue.fitness;
        avgSP = cachedValue.avgSP;
        maxSP = cachedValue.maxSP;
        cacheHit = true;
        return;
    end
    
    % Evaluate if not in cache
    [fitness, avgSP, maxSP] = evaluateFitness(individual, G, Cmax);
    
    % Store in cache
    cachedValue.fitness = fitness;
    cachedValue.avgSP = avgSP;
    cachedValue.maxSP = maxSP;
    cache(key) = cachedValue;
end

function mutatedIndividual = mutationFirstNode(individual, nNodes)
    % Mutation operator that only mutates the first node
    n = length(individual);
    mutatedIndividual = individual;
    
    % Get nodes not currently selected
    allNodes = 1:nNodes;
    notSelected = setdiff(allNodes, individual);
    
    % Only mutate if there are available nodes to swap with
    if ~isempty(notSelected)
        % Always mutate the first position
        newNodeIdx = randi(length(notSelected));
        newNode = notSelected(newNodeIdx);
        
        % Replace the first node with the new node
        mutatedIndividual(1) = newNode;
        
        % Ensure the result is sorted
        mutatedIndividual = sort(mutatedIndividual);
    end
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