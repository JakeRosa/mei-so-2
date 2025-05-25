function generate_sdn_lp()
% Generate LP file for SDN Controller Placement Problem
% Minimizes average shortest path length with controller distance constraint
% Parameters: n = 12 controllers, Cmax = 1000

addpath('../');

% Load network data using existing loadData function
[G, N, ~] = loadData();

% Compute shortest path distances between all node pairs
D = distances(G);

n = 12; % Number of controllers to select
Cmax = 1000; % Maximum distance between controllers

% Open LP file for writing
fid = fopen('sdn_placement.lp', 'wt');

% Write objective function (minimize average shortest path)
fprintf(fid, 'min: ');
for s = 1:N
    for i = 1:N
        if s == 1 && i == 1
            fprintf(fid, '%.1f g_%d_%d ', D(s,i), s, i);
        else
            fprintf(fid, '+ %.1f g_%d_%d ', D(s,i), s, i);
        end
    end
end
fprintf(fid, ';\n\n');

% Constraint 1: Exactly n controllers must be selected
fprintf(fid, '// Exactly %d controllers must be selected\n', n);
for i = 1:N
    if i == 1
        fprintf(fid, 'z_%d ', i);
    else
        fprintf(fid, '+ z_%d ', i);
    end
end
fprintf(fid, '= %d;\n\n', n);

% Constraint 2: Each node must be assigned to exactly one controller
fprintf(fid, '// Each node must be assigned to exactly one controller\n');
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
fprintf(fid, '// Nodes can only be assigned to selected controllers\n');
for s = 1:N
    for i = 1:N
        fprintf(fid, 'g_%d_%d - z_%d <= 0;\n', s, i, i);
    end
end
fprintf(fid, '\n');

% Constraint 4: Distance between any pair of controllers <= Cmax
fprintf(fid, '// Maximum distance between controllers constraint\n');
for i = 1:N
    for j = i+1:N
        if D(i,j) > Cmax
            fprintf(fid, 'z_%d + z_%d <= 1;\n', i, j);
        end
    end
end
fprintf(fid, '\n');

% Binary variable declarations
fprintf(fid, '// Binary variables for controller selection\n');
for i = 1:N
    fprintf(fid, 'bin z_%d;\n', i);
end
fprintf(fid, '\n');

fprintf(fid, '// Binary variables for node assignments\n');
for s = 1:N
    for i = 1:N
        fprintf(fid, 'bin g_%d_%d;\n', s, i);
    end
end

% Close file
fclose(fid);

fprintf('LP file "sdn_placement.lp" generated successfully!\n');
fprintf('Problem size: %d nodes, %d controllers, Cmax = %d\n', N, n, Cmax);
fprintf('Variables: %d z-variables + %d g-variables = %d total\n', N, N*N, N + N*N);

% Count controller distance constraints
constraint_count = 0;
for i = 1:N
    for j = i+1:N
        if D(i,j) > Cmax
            constraint_count = constraint_count + 1;
        end
    end
end
fprintf('Controller distance constraints: %d\n', constraint_count);

end