function mutatedIndividual = mutation(individual, nNodes, mutationRate)
% Mutation operator
% Inputs:
%   individual - individual to mutate (vector of selected nodes)
%   nNodes - total number of nodes in network
% Output:
%   mutatedIndividual - mutated individual
    
    n = length(individual);
    mutatedIndividual = individual;
    
    % Get nodes not currently selected
    allNodes = 1:nNodes;
    notSelected = setdiff(allNodes, individual);
    
    % Only mutate if there are available nodes to swap with
    if ~isempty(notSelected)
        % Randomly select one position to mutate
        mutationPosition = randi(n);
        
        % Randomly select one non-selected node
        newNodeIdx = randi(length(notSelected));
        newNode = notSelected(newNodeIdx);
        
        % Replace the selected node with the new node
        mutatedIndividual(mutationPosition) = newNode;
        
        % Ensure the result is sorted
        mutatedIndividual = sort(mutatedIndividual);
    end
end
