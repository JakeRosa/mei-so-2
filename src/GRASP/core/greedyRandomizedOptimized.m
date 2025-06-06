function solution = greedyRandomizedOptimized(G, D, n, r, Cmax, cache)
% Optimized Greedy Randomized construction with caching for the Server Node Selection problem
% Inputs:
%   G - graph representing the network
%   n - number of nodes to select
%   r - parameter for greedy randomized selection (r >= 2)
%   Cmax - maximum allowed shortest path length between controllers
%   cache - containers.Map for caching PerfSNS results
% Output:
%   solution - vector of selected node indices

    nNodes = numnodes(G);
    solution = [];
    E = 1:nNodes;  % Available elements to select
    
    % Initialize cache statistics if not present
    if ~isKey(cache, 'stats')
        stats = struct('hits', 0, 'misses', 0);
        cache('stats') = stats;
    else
        stats = cache('stats');
    end
    
    for i = 1:n
        % Find the r best candidates
        R = [];
        bestValues = [];
        
        for j = 1:length(E)
            candidate = E(j);
            tempSolution = [solution, candidate];
            
            % Create cache key for this solution
            cacheKey = sprintf('%s', num2str(sort(tempSolution)));
            
            % Check cache first
            if isKey(cache, cacheKey)
                cachedResult = cache(cacheKey);
                avgSP = cachedResult.avgSP;
                maxSP = cachedResult.maxSP;
                stats.hits = stats.hits + 1;
            else
                % Evaluate objective function
                [avgSP, maxSP] = optimizedPerfSNS(D, tempSolution);
                
                % Store in cache
                result = struct('avgSP', avgSP, 'maxSP', maxSP);
                cache(cacheKey) = result;
                stats.misses = stats.misses + 1;
            end
            
            % Update cache statistics
            cache('stats') = stats;
            
            % Check Cmax constraint
            if length(tempSolution) > 1 && maxSP > Cmax
                continue; % Skip this candidate as it violates constraint
            end
            
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