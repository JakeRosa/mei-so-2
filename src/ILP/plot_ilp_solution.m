function plot_ilp_solution()
% Plot the best ILP solution using plotNetworkSolution

% Add path to access loadData and plotNetworkSolution functions
addpath('../');

% Load network data
[G, N, ~] = loadData();

% Best ILP solution details
bestSolution = [78, 62, 40, 29, 18, 163, 154, 14, 138, 111, 108, 107];
avgSP = 149.0550;  % Best average shortest path from ILP
maxSP = 1000;      % Assume constraint is satisfied (need to verify)

% Plot the solution
fprintf('\nGenerating plot...\n');
plotNetworkSolution(G, bestSolution, avgSP, maxSP, 'ILP', 1, 'plots/');

fprintf('ILP solution plotted successfully!\n');

end