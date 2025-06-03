function offspring = crossover(parent1, parent2, n, nNodes)
% Crossover operator for creating offspring
% Inputs:
%   parent1, parent2 - parent individuals (vectors of selected nodes)
%   n - number of nodes to select
%   nNodes - total number of nodes in network
% Output:
%   offspring - new individual created from parents

    % Use Order Crossover (OX) adapted for set-based representation
    % Since we need exactly n unique nodes, we'll use a modified approach

    % Method: Partially inherit from parents, fill gaps randomly

    % Determine crossover points
    crossoverPoint1 = randi([1, n-1]);
    crossoverPoint2 = randi([crossoverPoint1+1, n]);

    % Initialize offspring
    offspring = zeros(1, n);

    % Copy segment from parent1
    offspring(crossoverPoint1:crossoverPoint2) = parent1(crossoverPoint1:crossoverPoint2);

    % Fill remaining positions with nodes from parent2 (if not already present)
    % Then fill with random nodes if needed
    usedNodes = offspring(crossoverPoint1:crossoverPoint2);
    availableFromParent2 = setdiff(parent2, usedNodes);
    allAvailableNodes = setdiff(1:nNodes, usedNodes);

    % Positions to fill
    emptyPositions = [1:(crossoverPoint1-1), (crossoverPoint2+1):n];

    % Fill from parent2 first
    fillCount = 0;
    for i = 1:length(availableFromParent2)
        if fillCount < length(emptyPositions)
            fillCount = fillCount + 1;
            offspring(emptyPositions(fillCount)) = availableFromParent2(i);
        else
            break;
        end
    end

    % Fill remaining positions randomly
    if fillCount < length(emptyPositions)
        remainingNodes = setdiff(allAvailableNodes, availableFromParent2);
        remainingToFill = length(emptyPositions) - fillCount;

        if length(remainingNodes) >= remainingToFill
            randomNodes = remainingNodes(randperm(length(remainingNodes), remainingToFill));
            offspring(emptyPositions((fillCount+1):end)) = randomNodes;
        else
            % Fallback: generate completely random solution
            offspring = sort(randperm(nNodes, n));
        end
    end

    % Ensure offspring is sorted and contains exactly n unique nodes
    offspring = sort(unique(offspring));

    % Handle case where offspring doesn't have exactly n nodes
    if length(offspring) ~= n
        offspring = sort(randperm(nNodes, n));
    end
end