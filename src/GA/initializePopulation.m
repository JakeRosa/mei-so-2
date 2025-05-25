function population = initializePopulation(populationSize, n, nNodes, Cmax, G)
% Initialize population with random individuals (no constraint checking needed)
% Inputs:
%   populationSize - number of individuals in population
%   n - number of nodes to select in each individual
%   nNodes - total number of nodes in the network
%   Cmax - maximum allowed shortest path length between controllers (unused)
%   G - graph representing the network (unused)
% Output:
%   population - cell array containing individuals

    population = cell(populationSize, 1);
    
    fprintf('Initializing %d random individuals...\n', populationSize);
    
    % Generate purely random individuals - no constraint checking
    for i = 1:populationSize
        % Generate random individual (select n nodes randomly)
        selectedNodes = sort(randperm(nNodes, n));
        population{i} = selectedNodes;
    end
    
    fprintf('Population initialization completed.\n');
end
