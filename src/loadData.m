function [G, nNodes, nLinks] = loadData()
% Load network data and create graph structure
% Returns:
%   G - MATLAB graph object representing the network
%   nNodes - number of nodes in the network
%   nLinks - number of links in the network

    % Load files
    nodes = load('../../data/Nodes200.txt');
    links = load('../../data/Links200.txt');
    L = load('../../data/L200.txt');
    
    % Extract adjacency information from L matrix
    [i, j] = find(L > 0);
    weights = L(L > 0);
    
    % Create graph with edge weights
    G = graph(i, j, weights);
    
    % Set node positions (optional, for visualization)
    G.Nodes.x = nodes(:, 1);
    G.Nodes.y = nodes(:, 2);
    
    nNodes = numnodes(G);
    nLinks = numedges(G);
    
    fprintf('Loaded network with %d nodes and %d links\n', nNodes, nLinks);
end
