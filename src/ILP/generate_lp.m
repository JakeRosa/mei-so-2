function generate_lp()
    % Generate LP file for SDN Controller Placement Problem
    % Minimizes average shortest path length with controller distance constraint
    % Parameters: n = 12 controllers, Cmax = 1000
    % OPTIMIZED: Excludes self-assignment variables (g_i_i)
    
    addpath('../');
    
    % Load network data using existing loadData function
    [G, N, ~] = loadData();
    
    % Compute shortest path distances between all node pairs
    D = distances(G);
    
    % Replace infinite distances with large number
    D(isinf(D)) = 99999;
    
    n = 12; % Number of controllers to select
    Cmax = 1000; % Maximum distance between controllers
    
    % Validation
    fprintf('Network loaded: %d nodes\n', N);
    
    % Open LP file for writing
    fid = fopen('ILP.lp', 'wt');
    
    % Write objective function (LPSOLVE FORMAT)
    % Only include terms where s != i (exclude self-assignments)
    fprintf(fid, 'min: ');
    first_term = true;
    for s = 1:N
        for i = 1:N
            if s ~= i  % Skip diagonal terms (self-assignments)
                if first_term
                    fprintf(fid, '%.0f g_%d_%d ', D(s,i), s, i);
                    first_term = false;
                else
                    fprintf(fid, '+ %.0f g_%d_%d ', D(s,i), s, i);
                end
            end
        end
    end
    fprintf(fid, ';\n\n');
    
    % Constraint 1: Exactly n controllers must be selected
    for i = 1:N
        if i == 1
            fprintf(fid, 'z_%d ', i);
        else
            fprintf(fid, '+ z_%d ', i);
        end
    end
    fprintf(fid, '= %d;\n\n', n);
    
    % Constraint 2: Each node must be assigned to exactly one controller
    % Modified to handle the case where a node can be a controller itself
    for s = 1:N
        first_var = true;
        for i = 1:N
            if s ~= i  % Non-self assignments
                if first_var
                    fprintf(fid, 'g_%d_%d ', s, i);
                    first_var = false;
                else
                    fprintf(fid, '+ g_%d_%d ', s, i);
                end
            end
        end
        % Add the controller selection variable for this node
        if first_var
            fprintf(fid, 'z_%d ', s);
        else
            fprintf(fid, '+ z_%d ', s);
        end
        fprintf(fid, '= 1;\n');
    end
    fprintf(fid, '\n');
    
    % Constraint 3: Nodes can only be assigned to selected controllers
    % Only for non-self assignments
    for s = 1:N
        for i = 1:N
            if s ~= i  % Skip self-assignments
                fprintf(fid, 'g_%d_%d - z_%d <= 0;\n', s, i, i);
            end
        end
    end
    fprintf(fid, '\n');
    
    % Constraint 4: Distance between any pair of controllers <= Cmax
    constraint_count = 0;
    for i = 1:N
        for j = i+1:N
            if D(i,j) > Cmax
                fprintf(fid, 'z_%d + z_%d <= 1;\n', i, j);
                constraint_count = constraint_count + 1;
            end
        end
    end
    fprintf(fid, '\n');
    
    % Binary variable declarations (LPSOLVE FORMAT)
    for i = 1:N
        fprintf(fid, 'bin z_%d;\n', i);
    end
    for s = 1:N
        for i = 1:N
            if s ~= i  % Only declare non-self assignment variables
                fprintf(fid, 'bin g_%d_%d;\n', s, i);
            end
        end
    end
    
    % Close file
    fclose(fid);
    
    % Calculate variable counts
    g_variables = N * (N - 1);  % N*N minus N diagonal elements
    total_variables = N + g_variables;
    
    fprintf('\n=== OPTIMIZED LP FILE GENERATED ===\n');
    fprintf('File: ILP.lp\n');
    fprintf('Problem size: %d nodes, %d controllers, Cmax = %d\n', N, n, Cmax);
    fprintf('Variables: %d z-variables + %d g-variables = %d total\n', N, g_variables, total_variables);
    fprintf('Eliminated %d unnecessary self-assignment variables\n', N);
    fprintf('Controller distance constraints: %d\n', constraint_count);
    fprintf('Reduced problem size by %.1f%%\n', (N / (N + N*N)) * 100);
    
end