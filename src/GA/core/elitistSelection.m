function newPopulation = elitistSelection(oldPopulation, newPopulation, oldFitness, newFitness, eliteCount)
% Elitist selection: keep best individuals from combined populations
% Inputs:
%   oldPopulation - previous generation population
%   newPopulation - offspring population
%   oldFitness - fitness values of old population
%   newFitness - fitness values of new population
%   eliteCount - number of elite individuals to preserve
% Output:
%   newPopulation - selected population for next generation

    if nargin < 5
        eliteCount = max(1, round(0.1 * length(oldPopulation))); % Default: 10% elitism
    end

    % Combine populations and fitness values
    combinedPopulation = [oldPopulation; newPopulation];
    combinedFitness = [oldFitness; newFitness];

    % Sort by fitness (descending - higher fitness is better)
    [~, sortedIndices] = sort(combinedFitness, 'descend');

    % Select top individuals
    populationSize = length(newPopulation);
    selectedIndices = sortedIndices(1:populationSize);

    % Create new population
    newPopulation = cell(populationSize, 1);
    for i = 1:populationSize
        newPopulation{i} = combinedPopulation{selectedIndices(i)};
    end
end