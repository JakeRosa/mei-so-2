function plot_ilp_solution()
% Plot the best ILP solution using plotNetworkSolution

% Add path to access loadData and plotNetworkSolution functions
addpath('../');

% Load network data
[G, N, ~] = loadData();

% Best ILP solution details
bestSolution = [14, 18, 40, 52, 78, 90, 107, 108, 129, 150, 154, 163];
avgSP = 145.085;  % Best average shortest path from ILP (29017/200)
maxSP = 1000;      % Assume constraint is satisfied

% Plot the solution
fprintf('\nGenerating plot...\n');
plotNetworkSolution(G, bestSolution, avgSP, maxSP, 'ILP', 1, 'plots/');

fprintf('ILP solution plotted successfully!\n');

end