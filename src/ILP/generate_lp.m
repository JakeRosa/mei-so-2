function generate_lp()
% Generate LP file for SDN Controller Placement Problem
% Minimizes average shortest path length with controller distance constraint
% Parameters: n = 12 controllers, Cmax = 1000

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
fprintf(fid, 'min: ');
first_term = true;
for s = 1:N
    for i = 1:N
        if first_term
            fprintf(fid, '%.0f g_%d_%d ', D(s,i), s, i);
            first_term = false;
        else
            fprintf(fid, '+ %.0f g_%d_%d ', D(s,i), s, i);
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
for s = 1:N
    for i = 1:N
        if i == 1
            fprintf(fid, 'g_%d_%d ', s, i);
        else
            fprintf(fid, '+ g_%d_%d ', s, i);
        end
    end
    fprintf(fid, '= 1;\n');
end
fprintf(fid, '\n');

% Constraint 3: Nodes can only be assigned to selected controllers
for s = 1:N
    for i = 1:N
        fprintf(fid, 'g_%d_%d - z_%d <= 0;\n', s, i, i);
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
        fprintf(fid, 'bin g_%d_%d;\n', s, i);
    end
end

% Close file
fclose(fid);

fprintf('\n=== LP FILE GENERATED ===\n');
fprintf('File: ILP.lp\n');
fprintf('Problem size: %d nodes, %d controllers, Cmax = %d\n', N, n, Cmax);
fprintf('Variables: %d z-variables + %d g-variables = %d total\n', N, N*N, N + N*N);
fprintf('Controller distance constraints: %d\n', constraint_count);

end