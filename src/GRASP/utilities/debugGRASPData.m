function debugGRASPData(allResults)
% Debug function to check what's in your GRASP results
% This will help us understand the data structure

    fprintf('=== DEBUGGING GRASP DATA ===\n');
    fprintf('Total allResults length: %d\n', length(allResults));
    
    for run = 1:length(allResults)
        fprintf('\n--- Run %d ---\n', run);
        
        % Check basic fields
        fprintf('avgSP: ');
        if isfield(allResults(run), 'avgSP')
            fprintf('%.4f\n', allResults(run).avgSP);
        else
            fprintf('MISSING\n');
        end
        
        fprintf('maxSP: ');
        if isfield(allResults(run), 'maxSP')
            fprintf('%.4f\n', allResults(run).maxSP);
        else
            fprintf('MISSING\n');
        end
        
        % Check results structure
        if isfield(allResults(run), 'results')
            fprintf('results field: EXISTS\n');
            
            if isfield(allResults(run).results, 'avgSPs')
                fprintf('  avgSPs: length = %d\n', length(allResults(run).results.avgSPs));
                if ~isempty(allResults(run).results.avgSPs)
                    fprintf('    First few values: [%.2f', allResults(run).results.avgSPs(1));
                    for i = 2:min(3, length(allResults(run).results.avgSPs))
                        fprintf(', %.2f', allResults(run).results.avgSPs(i));
                    end
                    fprintf(', ...]\n');
                end
            else
                fprintf('  avgSPs: MISSING\n');
            end
            
            if isfield(allResults(run).results, 'times')
                fprintf('  times: length = %d\n', length(allResults(run).results.times));
            else
                fprintf('  times: MISSING\n');
            end
            
            if isfield(allResults(run).results, 'iterations')
                fprintf('  iterations: length = %d\n', length(allResults(run).results.iterations));
            else
                fprintf('  iterations: MISSING\n');
            end
            
        else
            fprintf('results field: MISSING\n');
        end
    end
    
    fprintf('\n=== END DEBUG ===\n');
end