function selectedParent = tournamentSelection(population, fitnessValues, tournamentSize)
% Tournament selection for parent selection
% Inputs:
%   population - cell array of individuals
%   fitnessValues - fitness values for each individual
%   tournamentSize - number of individuals in tournament (default: 3)
% Output:
%   selectedParent - selected parent individual

    if nargin < 3
        tournamentSize = 3;
    end

    populationSize = length(population);

    % Randomly select individuals for tournament
    tournamentIndices = randperm(populationSize, min(tournamentSize, populationSize));
    tournamentFitness = fitnessValues(tournamentIndices);

    % Find the best individual in tournament (highest fitness)
    [~, bestIdx] = max(tournamentFitness);
    winnerIdx = tournamentIndices(bestIdx);

    selectedParent = population{winnerIdx};
end