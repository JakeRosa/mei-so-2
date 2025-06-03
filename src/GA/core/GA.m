function [bestSolution, bestObjective, bestMaxSP, results] = GA(G, n, Cmax, populationSize, mutationRate, eliteCount, maxTime)
% Genetic Algorithm with elitist selection for Server Node Selection problem
% Inputs:
%   G - graph representing the network
%   n - number of nodes to select
%   Cmax - maximum allowed shortest path length between controllers
%   populationSize - size of population
%   mutationRate - probability of mutation
%   eliteCount - number of elite individuals to preserve
%   maxTime - maximum running time in seconds
% Outputs:
%   bestSolution - best solution found
%   bestObjective - objective value of best solution (avgSP)
%   bestMaxSP - maximum shortest path between controllers in best solution
%   results - struct with detailed results

    fprintf('Starting GA with popSize=%d, mutRate=%.2f, eliteCount=%d, maxTime=%d seconds\n', ...
            populationSize, mutationRate, eliteCount, maxTime);
    
    addpath('../../'); % Add path to PerfSNS function
    nNodes = numnodes(G);
    
    % Initialize
    bestSolution = [];
    bestObjective = inf;
    bestMaxSP = inf;
    generation = 0;
    startTime = tic;
    
    % Results tracking
    results.objectives = [];
    results.maxSPs = [];
    results.avgFitness = [];
    results.bestFitness = [];
    results.times = [];
    results.generations = [];
    
    % Initialize population
    fprintf('Initializing %d random individuals...\n', populationSize);

    population = cell(populationSize, 1);

    % Generate purely random individuals - no constraint checkingAdd commentMore actions
    for i = 1:populationSize
        % Generate random individual (select n nodes randomly)
        selectedNodes = sort(randperm(nNodes, n));
        population{i} = selectedNodes;
    end
    
    fprintf('Population initialization completed.\n');
    
    % Evaluate initial population
    fitnessValues = zeros(populationSize, 1);
    avgSPValues = zeros(populationSize, 1);
    maxSPValues = zeros(populationSize, 1);
    
    for i = 1:populationSize
        [fitnessValues(i), avgSPValues(i), maxSPValues(i)] = evaluateFitness(population{i}, G, Cmax);
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
        
        % Create new population through crossover and mutation
        newPopulation = cell(populationSize, 1);
        
        for i = 1:populationSize
            % Parent selection using tournament selection
            parent1 = tournamentSelection(population, fitnessValues, 2);
            parent2 = tournamentSelection(population, fitnessValues, 2);
            
            % Crossover
            offspring = crossover(parent1, parent2, n, nNodes);
            
            % Mutation
            if rand < mutationRate
                offspring = mutation(offspring, nNodes);
            end
            
            newPopulation{i} = offspring;
        end
        
        % Evaluate new population
        newFitnessValues = zeros(populationSize, 1);
        newAvgSPValues = zeros(populationSize, 1);
        newMaxSPValues = zeros(populationSize, 1);
        
        for i = 1:populationSize
            [newFitnessValues(i), newAvgSPValues(i), newMaxSPValues(i)] = ...
                evaluateFitness(newPopulation{i}, G, Cmax);
        end
        
        % Elitist selection
        population = elitistSelection(population, newPopulation, fitnessValues, newFitnessValues, eliteCount);
        
        % Re-evaluate population after selection (combine old and new evaluations)
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
        
        % Store results
        results.objectives = [results.objectives, bestObjective];
        results.maxSPs = [results.maxSPs, bestMaxSP];
        results.avgFitness = [results.avgFitness, mean(fitnessValues)];
        results.bestFitness = [results.bestFitness, max(fitnessValues)];
        results.times = [results.times, toc(startTime)];
        results.generations = [results.generations, generation];
        
        % Progress report every 50 generations
        if mod(generation, 50) == 0
            fprintf('Generation %d, Time: %.2f s, Best: %.4f, Avg fitness: %.4f\n', ...
                    generation, toc(startTime), bestObjective, mean(fitnessValues));
        end
    end
    
    totalTime = toc(startTime);
    fprintf('\nGA completed:\n');
    fprintf('Total generations: %d\n', generation);
    fprintf('Total time: %.2f seconds\n', totalTime);
    fprintf('Best objective: %.4f\n', bestObjective);
    fprintf('Best max shortest path: %.4f\n', bestMaxSP);
    fprintf('Best solution: [%s]\n', num2str(bestSolution));
    
    % Final validation
    if bestMaxSP > Cmax
        fprintf('Warning: Best solution violates Cmax constraint (%.4f > %d)\n', bestMaxSP, Cmax);
    end
end
