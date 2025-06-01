% Standalone script to run GRASP analysis functions independently
% This script allows you to run specific analysis without full GRASP execution

fprintf('=== GRASP Standalone Analysis Menu ===\n\n');

% Setup paths for organized structure
currentDir = fileparts(mfilename('fullpath'));
graspDir = fileparts(currentDir);  % Go up one level to GRASP/

% Add all necessary paths
addpath(fullfile(graspDir, 'core'));
addpath(fullfile(graspDir, 'analysis'));
addpath(fullfile(graspDir, 'exports'));
addpath(fullfile(graspDir, 'lib'));
addpath(fullfile(graspDir, 'utilities'));

% Add parent directory for shared functions
addpath(fullfile(graspDir, '..'));

% Load data
[G, n, Cmax] = loadData();
fprintf('Loaded network: %d nodes, target n=%d, Cmax=%d\n\n', numnodes(G), n, Cmax);

% Default parameters
r = 5;          % GRASP parameter
maxTime = 60;   % Time limit
numRuns = 20;   % Number of runs for analysis

% Menu options
fprintf('Available analysis functions:\n');
fprintf('1. Phase Contribution Analysis\n');
fprintf('2. Node Frequency Analysis\n');
fprintf('3. Parameter Sensitivity Heat Map\n');
fprintf('4. Implementation Comparison\n');
fprintf('5. Run All Analysis\n');
fprintf('6. Exit\n\n');

choice = input('Select analysis (1-6): ');

switch choice
    case 1
        fprintf('\n=== Phase Contribution Analysis ===\n');
        fprintf('Analyzing construction vs local search phases...\n');
        phaseResults = analyzePhaseContribution(G, n, Cmax, r, numRuns);
        
    case 2
        fprintf('\n=== Node Frequency Analysis ===\n');
        fprintf('Identifying important nodes in solutions...\n');
        nodeAnalysis = analyzeNodeFrequency(G, n, Cmax, r, numRuns, 10);
        
    case 3
        fprintf('\n=== Parameter Sensitivity Analysis ===\n');
        fprintf('Creating parameter sensitivity heat maps...\n');
        fprintf('Warning: This may take several minutes!\n');
        sensitivityResults = plotParameterSensitivityHeatMap(G, n, Cmax);
        
    case 4
        fprintf('\n=== Implementation Comparison ===\n');
        fprintf('Comparing original vs optimized GRASP...\n');
        comparisonResults = compareOptimizations(G, n, Cmax, r, maxTime, 10);
        
    case 5
        fprintf('\n=== Running All Analysis ===\n');
        fprintf('This will run all analysis functions sequentially...\n');
        
        fprintf('\n1/4: Phase Contribution Analysis...\n');
        phaseResults = analyzePhaseContribution(G, n, Cmax, r, 15);
        
        fprintf('\n2/4: Node Frequency Analysis...\n');
        nodeAnalysis = analyzeNodeFrequency(G, n, Cmax, r, 15, 10);
        
        fprintf('\n3/4: Implementation Comparison...\n');
        comparisonResults = compareOptimizations(G, n, Cmax, r, maxTime, 8);
        
        fprintf('\n4/4: Parameter Sensitivity Analysis...\n');
        fprintf('Warning: This may take several minutes!\n');
        proceed = input('Continue with sensitivity analysis? (y/n): ', 's');
        if strcmpi(proceed, 'y')
            sensitivityResults = plotParameterSensitivityHeatMap(G, n, Cmax);
        else
            fprintf('Skipping sensitivity analysis\n');
        end
        
    case 6
        fprintf('Exiting...\n');
        return;
        
    otherwise
        fprintf('Invalid choice. Exiting...\n');
        return;
end

fprintf('\n=== Analysis Complete ===\n');
fprintf('Check the plots/ and results/ directories for outputs\n');

% Optionally save workspace
saveWorkspace = input('\nSave analysis results to workspace file? (y/n): ', 's');
if strcmpi(saveWorkspace, 'y')
    timestamp = datestr(now, 'yyyy-mm-dd_HH-MM-SS');
    filename = sprintf('results/standalone_analysis_%s.mat', timestamp);
    save(filename);
    fprintf('Workspace saved to: %s\n', filename);
end