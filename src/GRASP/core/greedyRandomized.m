function solution = greedyRandomized(G, n, r, Cmax)
% Greedy Randomized construction for the Server Node Selection problem
% Inputs:
%   G - graph representing the network
%   n - number of nodes to select
%   r - parameter for greedy randomized selection (r >= 2)
%   Cmax - maximum allowed shortest path length between controllers
% Output:
%   solution - vector of selected node indices

    nNodes = numnodes(G);
    solution = [];
    E = 1:nNodes;  % Available elements to select
    
    for i = 1:n
        % Find the r best candidates
        R = [];
        bestValues = [];
        
        for j = 1:length(E)
            candidate = E(j);
            tempSolution = [solution, candidate];
            
            % Check Cmax constraint
            if length(tempSolution) > 1
                [~, maxSP] = PerfSNS(G, tempSolution);
                if maxSP > Cmax
                    continue; % Skip this candidate as it violates constraint
                end
            end
            
            % Evaluate objective function (average shortest path)
            [avgSP, ~] = PerfSNS(G, tempSolution);
            
            R = [R, candidate];
            bestValues = [bestValues, avgSP];
        end
        
        % If no valid candidates (due to Cmax constraint), break
        if isempty(R)
            fprintf('Warning: Cannot find valid candidates due to Cmax constraint\n');
            break;
        end
        
        % Sort by objective value (ascending - we want to minimize)
        [sortedValues, idx] = sort(bestValues);
        sortedCandidates = R(idx);
        
        % Select from the r best candidates (or all if fewer than r)
        rBest = min(r, length(sortedCandidates));
        candidateList = sortedCandidates(1:rBest);
        
        % Randomly select from the candidate list
        selectedIdx = randi(length(candidateList));
        selectedNode = candidateList(selectedIdx);
        
        % Add to solution and remove from available elements
        solution = [solution, selectedNode];
        E = setdiff(E, selectedNode);
    end
    
    % Ensure we have exactly n nodes (if possible)
    if length(solution) < n
        fprintf('Warning: Only selected %d nodes instead of %d due to constraints\n', ...
                length(solution), n);
    end
end
