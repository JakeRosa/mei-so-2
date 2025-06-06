function checkOrganization()
% Check if GRASP files are properly organized
% This function verifies that all files are in their correct locations

    fprintf('=== GRASP Organization Check ===\n\n');
    
    % Define expected structure
    expectedFiles = struct();
    expectedFiles.core = {'GRASP.m', 'GRASPOptimized.m', 'greedyRandomized.m', ...
                         'greedyRandomizedOptimized.m', 'steepestAscentHillClimbing.m'};
    expectedFiles.analysis = {'analyzeExistingResults.m', 'analyzeNodeFrequency.m', ...
                             'analyzePhaseContribution.m', 'compareOptimizations.m', ...
                             'plotGRASPPhaseAnalysis.m', 'plotParameterSensitivityHeatMap.m', ...
                             'plotParameterVariation.m'};
    expectedFiles.runners = {'runGRASP.m', 'runStandaloneAnalysis.m'};
    expectedFiles.utilities = {'debugGRASPData.m'};
    expectedFiles.exports = {'exportGraspResults.m', 'exportParameterStats.m'};
    expectedFiles.lib = {'writeCSV.m'};
    
    % Check each folder
    folders = fieldnames(expectedFiles);
    allGood = true;
    
    for i = 1:length(folders)
        folder = folders{i};
        files = expectedFiles.(folder);
        
        fprintf('Checking %s/\n', folder);
        
        % Check if folder exists
        if ~exist(folder, 'dir')
            fprintf('   Folder %s/ does not exist\n', folder);
            allGood = false;
            continue;
        end
        
        % Check each file
        missingFiles = {};
        for j = 1:length(files)
            filePath = fullfile(folder, files{j});
            if exist(filePath, 'file') == 2
                fprintf('%s\n', files{j});
            else
                fprintf('Missing: %s\n', files{j});
                missingFiles{end+1} = files{j};
                allGood = false;
            end
        end
        
        if isempty(missingFiles)
            fprintf('All files present in %s/\n', folder);
        end
        fprintf('\n');
    end
    
    % Check main files
    fprintf('Checking main directory\n');
    mainFiles = {'main.m', 'README.md'};
    for i = 1:length(mainFiles)
        if exist(mainFiles{i}, 'file') == 2
            fprintf('%s\n', mainFiles{i});
        else
            fprintf('Missing: %s\n', mainFiles{i});
            allGood = false;
        end
    end
    
    % Check required directories
    fprintf('\nChecking output directories\n');
    outputDirs = {'output', 'plots', 'results'};
    for i = 1:length(outputDirs)
        if exist(outputDirs{i}, 'dir')
            fprintf('%s/\n', outputDirs{i});
        else
            fprintf('Missing: %s/\n', outputDirs{i});
            allGood = false;
        end
    end
    
    % Final status
    fprintf('\n=== Organization Status ===\n');
    if allGood
        fprintf('All files properly organized!\n');
        fprintf('You can now use: main() or main(''help'')\n');
    else
        fprintf('Some files are missing or misplaced.\n');
        fprintf('Run the reorganization script to fix issues.\n');
    end
    
    % Test path setup
    fprintf('\n=== Testing Path Setup ===\n');
    try
        currentPath = path();
        if contains(currentPath, 'core') && contains(currentPath, 'analysis')
            fprintf('Paths appear to be set correctly\n');
        else
            fprintf('Paths may need to be set up\n');
            fprintf('Run main() to automatically set up paths\n');
        end
    catch
        fprintf('Error checking paths\n');
    end
    
    % Quick functionality test
    fprintf('\n=== Quick Functionality Test ===\n');
    try
        if exist('loadData', 'file')
            fprintf('loadData() function accessible\n');
        else
            fprintf('loadData() function not found\n');
            fprintf('Make sure you run from the GRASP directory\n');
        end
        
        if exist('GRASP.m', 'file')
            fprintf('Main GRASP functions accessible\n');
        else
            fprintf('GRASP functions not accessible\n');
            fprintf('Paths may not be set up correctly\n');
        end
    catch ME
        fprintf('Error during functionality test: %s\n', ME.message);
    end
    
    fprintf('\n=== Usage Instructions ===\n');
    fprintf('To get started:\n');
    fprintf('1. Run: main()                    % Interactive menu\n');
    fprintf('2. Or:  main(''help'')             % Show all options\n');
    fprintf('3. Or:  main(''existing'')         % Analyze existing results\n');
    fprintf('4. Or:  main(''optimized'', ''analysis'')  % Full run\n');
end