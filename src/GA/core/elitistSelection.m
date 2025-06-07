function [newPopulation, newFitnessValues, newAvgSPValues, newMaxSPValues] = elitistSelection(oldPopulation, offspring, oldFitness, newFitness, oldAvgSP, newAvgSP, oldMaxSP, newMaxSP, eliteCount)
% Elitist selection: keep best individuals from combined populations
% Inputs:
%   oldPopulation - previous generation population
%   offspring - offspring population
%   oldFitness - fitness values of old population
%   newFitness - fitness values of offspring
%   oldAvgSP - average SP values of old population
%   newAvgSP - average SP values of offspring
%   oldMaxSP - max SP values of old population
%   newMaxSP - max SP values of offspring
%   eliteCount - number of elite individuals to preserve
% Outputs:
%   newPopulation - selected population for next generation
%   newFitnessValues - fitness values of new population
%   newAvgSPValues - average SP values of new population
%   newMaxSPValues - max SP values of new population

    if nargin < 9
        eliteCount = max(1, round(0.1 * length(oldPopulation)));
    end
    
    populationSize = length(oldPopulation);
    
    % Sort old population by fitness (descending) to find elite
    [~, oldSortedIndices] = sort(oldFitness, 'descend');
    
    % Select elite individuals from old population
    eliteIndices = oldSortedIndices(1:min(eliteCount, length(oldPopulation)));
    
    % Sort offspring by fitness (descending)
    [~, offspringSortedIndices] = sort(newFitness, 'descend');
    
    % Calculate how many offspring to include
    remainingSlots = populationSize - length(eliteIndices);
    offspringToInclude = offspringSortedIndices(1:min(remainingSlots, length(offspring)));
    
    % Create new population with corresponding fitness values
    newPopulation = cell(populationSize, 1);
    newFitnessValues = zeros(populationSize, 1);
    newAvgSPValues = zeros(populationSize, 1);
    newMaxSPValues = zeros(populationSize, 1);
    
    % Add elite individuals
    for i = 1:length(eliteIndices)
        idx = eliteIndices(i);
        newPopulation{i} = oldPopulation{idx};
        newFitnessValues(i) = oldFitness(idx);
        newAvgSPValues(i) = oldAvgSP(idx);
        newMaxSPValues(i) = oldMaxSP(idx);
    end
    
    % Add best offspring to fill remaining slots
    for i = 1:length(offspringToInclude)
        idx = offspringToInclude(i);
        position = length(eliteIndices) + i;
        newPopulation{position} = offspring{idx};
        newFitnessValues(position) = newFitness(idx);
        newAvgSPValues(position) = newAvgSP(idx);
        newMaxSPValues(position) = newMaxSP(idx);
    end
end