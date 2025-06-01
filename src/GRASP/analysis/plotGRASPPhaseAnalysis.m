function plotGRASPPhaseAnalysis(csvFolder, timestamp)
% Complete GRASP analysis in one function
% Creates comprehensive analysis plots showing all key GRASP features
%
% Input:
%   csvFolder - folder containing CSV files (e.g., 'results/')
%   timestamp - optional specific timestamp

    if nargin < 1
        csvFolder = '../results/';
    end
    
    fprintf('Creating comprehensive GRASP analysis...\n');
    
    % Find CSV files
    if nargin < 2
        files = dir(sprintf('%sGRASP_convergence_*.csv', csvFolder));
        if isempty(files)
            error('No GRASP convergence files found');
        end
        [~, idx] = max([files.datenum]);
        [~, name, ~] = fileparts(files(idx).name);
        timestamp = name(19:end);
    end
    
    convergenceFile = sprintf('%sGRASP_convergence_%s.csv', csvFolder, timestamp);
    summaryFile = sprintf('%sGRASP_summary_%s.csv', csvFolder, timestamp);
    
    fprintf('Reading data from:\n  %s\n  %s\n', convergenceFile, summaryFile);
    
    % Read convergence data
    fid = fopen(convergenceFile, 'r');
    if fid == -1
        error('Cannot open convergence file');
    end
    fgetl(fid); % Skip header
    convergenceData = [];
    while ~feof(fid)
        line = fgetl(fid);
        if ischar(line) && ~isempty(line)
            values = str2double(strsplit(line, ','));
            convergenceData = [convergenceData; values];
        end
    end
    fclose(fid);
    
    % Read summary data  
    fid = fopen(summaryFile, 'r');
    if fid == -1
        error('Cannot open summary file');
    end
    fgetl(fid); % Skip header
    summaryData = [];
    while ~feof(fid)
        line = fgetl(fid);
        if ischar(line) && ~isempty(line)
            parts = strsplit(line, ',');
            values = str2double(parts(1:7)); % Skip solution string
            summaryData = [summaryData; values];
        end
    end
    fclose(fid);
    
    fprintf('Read %d convergence points and %d run summaries\n', ...
            size(convergenceData, 1), size(summaryData, 1));
    
    % Extract data and calculate statistics
    finalObjectives = summaryData(:, 2); % Final_avgSP
    maxSPs = summaryData(:, 3); % Final_maxSP
    numIterations = summaryData(:, 4); % Num_Iterations
    totalTimes = summaryData(:, 5); % Total_Time
    bestIterations = summaryData(:, 6); % Best_Iteration
    
    % Calculate statistics for both console and file output
    meanObj = mean(finalObjectives);
    stdObj = std(finalObjectives);
    rangeObj = max(finalObjectives) - min(finalObjectives);
    meanIter = mean(numIterations);
    meanBestIter = mean(bestIterations);
    Cmax = 1000;
    
    % Constraint status
    if all(maxSPs <= Cmax)
        constraintStatus = 'Yes';
    else
        constraintStatus = 'No';
    end
    
    % Add path for utility functions
    addpath('../utilities');
    
    % Create individual analysis plots (larger and more readable)
    
    % 1. Best Solution Over Time (Algorithm Efficiency)
    figure('Position', [50, 50, 2200, 1600]);
    allTimes = convergenceData(:, 3);     % Time column
    allObjectives = convergenceData(:, 4); % Objective_avgSP column
    
    % Calculate best-so-far curve
    [sortedTimes, timeIdx] = sort(allTimes);
    sortedObjectives = allObjectives(timeIdx);
    
    bestSoFar = [];
    currentBest = inf;
    for i = 1:length(sortedObjectives)
        if sortedObjectives(i) < currentBest
            currentBest = sortedObjectives(i);
        end
        bestSoFar = [bestSoFar, currentBest];
    end
    
    plot(sortedTimes, bestSoFar, 'b-', 'LineWidth', 4);
    xlabel('Time (seconds)', 'FontSize', 14);
    ylabel('Best Objective Found', 'FontSize', 14);
    title(sprintf('GRASP Algorithm Efficiency: Best Solution Over Time (%s)', timestamp), 'FontSize', 16, 'FontWeight', 'bold');
    set(gca, 'FontSize', 12);
    grid on; grid minor;
    saveAnalysisPlot(gcf, 'convergence', 'best_solution_over_time', timestamp);
    
    % 2. Constraint Satisfaction Analysis
    figure('Position', [100, 100, 2200, 1600]);
    scatter(1:length(maxSPs), maxSPs, 150, 'filled', 'MarkerFaceColor', 'red', 'MarkerEdgeColor', 'black');
    hold on;
    plot([0.5, length(maxSPs)+0.5], [Cmax, Cmax], 'k--', 'LineWidth', 3);
    xlabel('Run Number', 'FontSize', 14);
    ylabel('Maximum Shortest Path', 'FontSize', 14);
    title(sprintf('Constraint Satisfaction Analysis (%s)', timestamp), 'FontSize', 16, 'FontWeight', 'bold');
    legend('MaxSP values', 'Cmax = 1000', 'Location', 'best', 'FontSize', 12);
    set(gca, 'FontSize', 12);
    grid on; grid minor;
    ylim([min(maxSPs)*0.98, max(maxSPs)*1.02]);
    
    % Add constraint satisfaction text
    text(0.5, 0.95, sprintf('All constraints satisfied: %s', constraintStatus), ...
         'Units', 'normalized', 'HorizontalAlignment', 'center', ...
         'FontSize', 14, 'FontWeight', 'bold', 'Color', 'blue', ...
         'BackgroundColor', 'white', 'EdgeColor', 'black');
    saveAnalysisPlot(gcf, 'quality', 'constraint_satisfaction', timestamp);
    
    % 3. Iterations per Run Analysis
    figure('Position', [150, 150, 2200, 1600]);
    bar(1:length(numIterations), numIterations, 'FaceColor', [0.5 1 0.5], 'EdgeColor', 'black', 'LineWidth', 1.5);
    xlabel('Run Number', 'FontSize', 14);
    ylabel('Number of Iterations', 'FontSize', 14);
    title(sprintf('Iterations per GRASP Run (%s)', timestamp), 'FontSize', 16, 'FontWeight', 'bold');
    set(gca, 'FontSize', 12);
    grid on; grid minor;
    
    % Add mean line
    hold on;
    plot([0.5, length(numIterations)+0.5], [meanIter, meanIter], 'r--', 'LineWidth', 3);
    text(0.7, 0.9, sprintf('Mean: %.1f iterations', meanIter), 'Units', 'normalized', ...
         'BackgroundColor', 'white', 'EdgeColor', 'black', 'FontSize', 12, 'FontWeight', 'bold');
    saveAnalysisPlot(gcf, 'convergence', 'iterations_per_run', timestamp);
    
    % 4. Time vs Iterations Relationship
    figure('Position', [200, 200, 2200, 1600]);
    scatter(numIterations, totalTimes, 150, 'filled', 'MarkerFaceColor', 'magenta', 'MarkerEdgeColor', 'black');
    xlabel('Number of Iterations', 'FontSize', 14);
    ylabel('Total Time (seconds)', 'FontSize', 14);
    title(sprintf('Time vs Iterations Relationship (%s)', timestamp), 'FontSize', 16, 'FontWeight', 'bold');
    set(gca, 'FontSize', 12);
    grid on; grid minor;
    
    % Add trend line if we have enough points
    if length(numIterations) > 2
        p = polyfit(numIterations, totalTimes, 1);
        hold on;
        iterRange = [min(numIterations), max(numIterations)];
        plot(iterRange, polyval(p, iterRange), 'r--', 'LineWidth', 3);
        
        % Calculate R-squared
        yfit = polyval(p, numIterations);
        SSres = sum((totalTimes - yfit).^2);
        SStot = sum((totalTimes - mean(totalTimes)).^2);
        rsq = 1 - SSres/SStot;
        text(0.05, 0.9, sprintf('R² = %.3f\nSlope = %.2f s/iter', rsq, p(1)), 'Units', 'normalized', ...
             'BackgroundColor', 'white', 'EdgeColor', 'black', 'FontSize', 12, 'FontWeight', 'bold');
    end
    saveAnalysisPlot(gcf, 'convergence', 'time_vs_iterations', timestamp);
    
    % 5. Solution Quality Distribution
    figure('Position', [250, 250, 2200, 1600]);
    histogram(finalObjectives, 'Normalization', 'probability', 'FaceColor', [0.3 0.7 0.9], 'EdgeColor', 'black');
    xlabel('Final Solution Quality (Average Shortest Path)', 'FontSize', 14);
    ylabel('Probability', 'FontSize', 14);
    title(sprintf('Solution Quality Distribution (%s)', timestamp), 'FontSize', 16, 'FontWeight', 'bold');
    set(gca, 'FontSize', 12);
    grid on; grid minor;
    
    % Add statistics
    text(0.65, 0.8, sprintf('Mean: %.4f\nStd: %.4f\nBest: %.4f\nWorst: %.4f', ...
        meanObj, stdObj, min(finalObjectives), max(finalObjectives)), ...
        'Units', 'normalized', 'BackgroundColor', 'white', ...
        'FontSize', 12, 'FontWeight', 'bold', 'EdgeColor', 'black');
    saveAnalysisPlot(gcf, 'quality', 'solution_quality_distribution', timestamp);
    
    % 6. When Best Solutions Are Found (Convergence Timing)
    figure('Position', [300, 300, 2200, 1600]);
    histogram(bestIterations, max(3, floor(length(bestIterations)/2)), ...
              'FaceColor', [1 0.8 0.2], 'EdgeColor', 'black');
    xlabel('Iteration When Best Solution Found', 'FontSize', 14);
    ylabel('Frequency', 'FontSize', 14);
    title(sprintf('Convergence Timing Analysis (%s)', timestamp), 'FontSize', 16, 'FontWeight', 'bold');
    set(gca, 'FontSize', 12);
    grid on; grid minor;
    
    % Add statistics and early/late convergence analysis
    earlyConv = sum(bestIterations <= mean(numIterations)*0.5);
    lateConv = sum(bestIterations > mean(numIterations)*0.5);
    text(0.65, 0.8, sprintf('Mean: %.1f\nMedian: %.1f\nEarly: %d runs\nLate: %d runs', ...
        meanBestIter, median(bestIterations), earlyConv, lateConv), ...
        'Units', 'normalized', 'BackgroundColor', 'white', ...
        'FontSize', 12, 'FontWeight', 'bold', 'EdgeColor', 'black');
    saveAnalysisPlot(gcf, 'convergence', 'convergence_timing', timestamp);
    
    fprintf('\nGRASP phase analysis complete! Individual plots saved in organized folders:\n');
    fprintf('  - Convergence plots: plots/convergence/\n');
    fprintf('  - Quality plots: plots/quality/\n');
    
    % Save analysis to text file
    if ~exist('results', 'dir')
        mkdir('results');
    end
    analysisFile = sprintf('../results/GRASP_analysis_report_%s.txt', timestamp);
    
    % Write comprehensive analysis to file
    fid = fopen(analysisFile, 'w');
    fprintf(fid, '=== GRASP COMPREHENSIVE ANALYSIS REPORT ===\n');
    fprintf(fid, 'Generated: %s\n', datestr(now));
    fprintf(fid, 'Data timestamp: %s\n\n', timestamp);
    
    fprintf(fid, 'DATASET OVERVIEW:\n');
    fprintf(fid, '  Total runs analyzed: %d\n', length(finalObjectives));
    fprintf(fid, '  Total iterations: %d\n', sum(numIterations));
    fprintf(fid, '  Total computation time: %.1f seconds\n\n', sum(totalTimes));
    
    fprintf(fid, 'SOLUTION QUALITY ANALYSIS:\n');
    fprintf(fid, '  Best objective: %.6f\n', min(finalObjectives));
    fprintf(fid, '  Average objective: %.6f\n', meanObj);
    fprintf(fid, '  Worst objective: %.6f\n', max(finalObjectives));
    fprintf(fid, '  Standard deviation: %.6f\n', stdObj);
    fprintf(fid, '  Coefficient of variation: %.2f%%\n', (stdObj/meanObj)*100);
    fprintf(fid, '  Range: %.6f\n\n', rangeObj);
    
    fprintf(fid, 'CONSTRAINT SATISFACTION ANALYSIS:\n');
    fprintf(fid, '  All solutions satisfy Cmax ≤ 1000: %s\n', constraintStatus);
    fprintf(fid, '  Average MaxSP: %.2f\n', mean(maxSPs));
    fprintf(fid, '  Minimum MaxSP: %.2f\n', min(maxSPs));
    fprintf(fid, '  Maximum MaxSP: %.2f\n', max(maxSPs));
    fprintf(fid, '  Tightest constraint: %.2f (%.1f%% of limit)\n', ...
            max(maxSPs), (max(maxSPs)/Cmax)*100);
    fprintf(fid, '  Constraint margin: %.2f\n\n', Cmax - max(maxSPs));
    
    fprintf(fid, 'ALGORITHM EFFICIENCY ANALYSIS:\n');
    fprintf(fid, '  Average iterations per run: %.1f\n', meanIter);
    fprintf(fid, '  Minimum iterations: %d\n', min(numIterations));
    fprintf(fid, '  Maximum iterations: %d\n', max(numIterations));
    fprintf(fid, '  Average time per run: %.2f seconds\n', mean(totalTimes));
    fprintf(fid, '  Average time per iteration: %.3f seconds\n', mean(totalTimes./numIterations));
    fprintf(fid, '  Fastest run: %.2f seconds\n', min(totalTimes));
    fprintf(fid, '  Slowest run: %.2f seconds\n\n', max(totalTimes));
    
    fprintf(fid, 'CONVERGENCE BEHAVIOR ANALYSIS:\n');
    fprintf(fid, '  Best solutions found on average at iteration: %.1f\n', meanBestIter);
    fprintf(fid, '  Earliest convergence: iteration %d\n', min(bestIterations));
    fprintf(fid, '  Latest convergence: iteration %d\n', max(bestIterations));
    earlyConv = sum(bestIterations <= numIterations*0.5);
    lateConv = sum(bestIterations > numIterations*0.5);
    fprintf(fid, '  Early convergence (≤50%% iterations): %d runs (%.1f%%)\n', ...
            earlyConv, (earlyConv/length(bestIterations))*100);
    fprintf(fid, '  Late convergence (>50%% iterations): %d runs (%.1f%%)\n\n', ...
            lateConv, (lateConv/length(bestIterations))*100);
    
    fprintf(fid, 'DETAILED RUN BREAKDOWN:\n');
    fprintf(fid, 'Run | Final_Obj | MaxSP | Iters | Time(s) | Best_Iter\n');
    fprintf(fid, '----|-----------|-------|-------|---------|----------\n');
    for i = 1:length(finalObjectives)
        fprintf(fid, '%3d | %9.4f | %5.0f | %5d | %7.2f | %9d\n', ...
                i, finalObjectives(i), maxSPs(i), numIterations(i), ...
                totalTimes(i), bestIterations(i));
    end
    
    fprintf(fid, '\n=== END OF ANALYSIS ===\n');
    fclose(fid);
    
    % Print comprehensive summary
    fprintf('\n=== COMPREHENSIVE GRASP ANALYSIS SUMMARY ===\n');
    fprintf('Timestamp: %s\n', timestamp);
    fprintf('Total runs analyzed: %d\n', length(finalObjectives));
    fprintf('Total iterations: %d\n', sum(numIterations));
    fprintf('\nSOLUTION QUALITY:\n');
    fprintf('  Best objective: %.4f\n', min(finalObjectives));
    fprintf('  Average objective: %.4f\n', meanObj);
    fprintf('  Worst objective: %.4f\n', max(finalObjectives));
    fprintf('  Standard deviation: %.4f\n', stdObj);
    fprintf('  Coefficient of variation: %.2f%%\n', (stdObj/meanObj)*100);
    
    fprintf('\nCONSTRAINT SATISFACTION:\n');
    fprintf('  All solutions satisfy Cmax ≤ 1000: %s\n', constraintStatus);
    fprintf('  Average MaxSP: %.2f\n', mean(maxSPs));
    fprintf('  Tightest constraint: %.2f (%.1f%% of limit)\n', ...
            max(maxSPs), (max(maxSPs)/Cmax)*100);
    
    fprintf('\nALGORITHM EFFICIENCY:\n');
    fprintf('  Average iterations per run: %.1f\n', meanIter);
    fprintf('  Average time per run: %.1f seconds\n', mean(totalTimes));
    fprintf('  Average time per iteration: %.2f seconds\n', mean(totalTimes./numIterations));
    
    fprintf('\nCONVERGENCE BEHAVIOR:\n');
    fprintf('  Best solutions found on average at iteration: %.1f\n', meanBestIter);
    fprintf('  Early convergence (≤50%% iterations): %d runs\n', ...
            sum(bestIterations <= numIterations*0.5));
    fprintf('  Late convergence (>50%% iterations): %d runs\n', ...
            sum(bestIterations > numIterations*0.5));
    
    fprintf('Analysis report saved to: %s\n', analysisFile);
    fprintf('Analysis complete!\n');
end