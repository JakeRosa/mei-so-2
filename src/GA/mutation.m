function mutatedIndividual = mutation(individual, nNodes, mutationRate)
% Mutation operator
% Inputs:
%   individual - individual to mutate (vector of selected nodes)
%   nNodes - total number of nodes in network
%   mutationRate - probability of mutation (default: 0.1)
% Output:
%   mutatedIndividual - mutated individual

    if nargin < 3
        mutationRate = 0.1;
    end
    
    n = length(individual);
    mutatedIndividual = individual;
    
    % Determine number of genes to mutate
    numMutations = max(1, round(mutationRate * n));
    
    % Randomly select positions to mutate
    mutationPositions = randperm(n, numMutations);
    
    % Get nodes not currently selected
    allNodes = 1:nNodes;
    notSelected = setdiff(allNodes, individual);
    
    % Perform mutations (swap selected nodes with non-selected ones)
    for i = 1:length(mutationPositions)
        pos = mutationPositions(i);
        
        if ~isempty(notSelected)
            % Replace current node with a random non-selected node
            newNodeIdx = randi(length(notSelected));
            newNode = notSelected(newNodeIdx);
            
            % Update the individual and available nodes
            oldNode = mutatedIndividual(pos);
            mutatedIndividual(pos) = newNode;
            
            % Update notSelected list
            notSelected = setdiff(notSelected, newNode);
            notSelected = [notSelected, oldNode];
        end
    end
    
    % Ensure the result is sorted
    mutatedIndividual = sort(mutatedIndividual);
end
