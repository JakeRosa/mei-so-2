function testGA()
% Quick test function to verify GA implementation
    
    addpath('../'); % Add path to PerfSNS function
    
    % Load network data
    [G, nNodes, nLinks] = loadData();
    
    % Problem parameters
    n = 12;              % Number of nodes to select
    Cmax = 1000;         % Maximum shortest path constraint
    populationSize = 30; % Small population for quick test
    mutationRate = 0.2;  % 20% mutation rate
    eliteCount = 3;      % Keep 3 best individuals
    maxTime = 10;        % seconds
    
    fprintf('Running quick GA test...\n');
    
    % Run GA
    [solution, objective, maxSP, results] = GA(G, n, Cmax, populationSize, ...
                                              mutationRate, eliteCount, maxTime);
    
    % Validate solution
    if ~isempty(solution)
        fprintf('\nSolution validation:\n');
        fprintf('Selected nodes: [%s]\n', num2str(solution));
        fprintf('Number of nodes selected: %d (expected: %d)\n', length(solution), n);
        
        % Verify with PerfSNS
        [avgSP_check, maxSP_check] = PerfSNS(G, solution);
        fprintf('Objective (avgSP): %.4f\n', avgSP_check);
        fprintf('Max shortest path: %.4f (constraint: %d)\n', maxSP_check, Cmax);
        fprintf('Constraint satisfied: %s\n', string(maxSP_check <= Cmax));
        
        % Display some evolution statistics
        if ~isempty(results.generations)
            fprintf('\nEvolution statistics:\n');
            fprintf('Generations completed: %d\n', max(results.generations));
            fprintf('Final best fitness: %.6f\n', max(results.bestFitness));
            fprintf('Final average fitness: %.6f\n', results.avgFitness(end));
        end
        
    else
        fprintf('No valid solution found!\n');
    end
end
