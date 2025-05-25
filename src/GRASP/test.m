function testGRASP()
% Quick test function to verify GRASP implementation
    
    addpath('../'); % Add path to PerfSNS function
    
    % Load network data
    [G, nNodes, nLinks] = loadData();
    
    % Problem parameters
    n = 12;        % Number of nodes to select
    Cmax = 1000;   % Maximum shortest path constraint
    r = 3;         % Greedy randomized parameter
    maxTime = 5;   % seconds
    
    fprintf('Running quick GRASP test...\n');
    
    % Run GRASP
    [solution, objective, maxSP, results] = GRASP(G, n, Cmax, r, maxTime);
    
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
        
        % Test local search separately
        fprintf('\nTesting local search improvement:\n');
        initialSolution = greedyRandomized(G, n, r, Cmax);
        if ~isempty(initialSolution)
            [initial_avgSP, ~] = PerfSNS(G, initialSolution);
            improvedSolution = steepestAscentHillClimbing(G, initialSolution, Cmax);
            [improved_avgSP, ~] = PerfSNS(G, improvedSolution);
            
            fprintf('Initial solution objective: %.4f\n', initial_avgSP);
            fprintf('Improved solution objective: %.4f\n', improved_avgSP);
            fprintf('Improvement: %.4f\n', initial_avgSP - improved_avgSP);
        end
    else
        fprintf('No valid solution found!\n');
    end
end
