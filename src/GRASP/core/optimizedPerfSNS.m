function [avgSP,maxSP]= optimizedPerfSNS(D, sNodes)
% [out1,out2]= optimizedPerfSNS(D, sNodes)
% Optimized version that uses pre-computed distance matrix
% OUTPUTS:
%   avgSP -   average shortest path length from each node to its closest
%             server node (returns -1 for invalid input data)
%   maxSP -   maximum shortest path length between any pair of server nodes
%             (returns -1 for invalid input data)
% INPUTS:
%   D -       pre-computed NxN distance matrix (from distances(G))
%   sNodes -  a row array with server nodes
    
    nNodes = size(D, 1);
    
    % Input validation
    if length(sNodes) < 1
        avgSP = -1;
        maxSP = -1;
        return
    end
    
    if (max(sNodes) > nNodes || min(sNodes) < 1 || length(unique(sNodes)) < length(sNodes))
        avgSP = -1;
        maxSP = -1;
        return
    end
    
    % Get all client nodes (non-server nodes)
    clients = setdiff(1:nNodes, sNodes);
    
    if length(sNodes) > 1
        % Calculate average shortest path from each node to closest server
        % For each client, find minimum distance to any server
        if ~isempty(clients)
            clientDistances = D(sNodes, clients); % distances from servers to clients
            minDistToServer = min(clientDistances, [], 1); % min distance for each client
        else
            minDistToServer = [];
        end
        
        % For server nodes, distance to closest server is 0 (themselves)
        serverDistances = zeros(1, length(sNodes));
        
        % Combine all distances and calculate average
        allDistances = [minDistToServer, serverDistances];
        avgSP = sum(allDistances) / nNodes;
        
        % Calculate maximum shortest path between server nodes
        serverDistMatrix = D(sNodes, sNodes);
        maxSP = max(serverDistMatrix(:));
        
    else
        % Single server case
        % Distance from server to itself is 0
        % Distance from clients to server
        if ~isempty(clients)
            clientDistances = D(sNodes, clients);
            avgSP = sum(clientDistances) / nNodes; % includes the server (distance 0)
        else
            avgSP = 0; % only one node which is the server
        end
        maxSP = 0; % no pairs of servers
    end
end