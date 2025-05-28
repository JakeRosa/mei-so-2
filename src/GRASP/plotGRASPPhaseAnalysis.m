function plotGRASPPhaseAnalysis(csvFolder, timestamp)
% Complete GRASP analysis in one function
% Creates comprehensive analysis plots showing all key GRASP features
%
% Input:
%   csvFolder - folder containing CSV files (e.g., 'results/')
%   timestamp - optional specific timestamp

    if nargin < 1
        csvFolder = 'results/';
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
    
    % Create comprehensive analysis figure
    figure('Position', [50, 50, 1600, 1200]);
    
    % 1. Best Solution Over Time (Algorithm Efficiency)
    subplot(2, 3, 1);
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
    
    plot(sortedTimes, bestSoFar, 'b-', 'LineWidth', 3);
    xlabel('Time (seconds)');
    ylabel('Best Objective Found');
    title('GRASP Efficiency: Best Solution Over Time');
    grid on;
    
    % 2. Solution Quality Distribution
    subplot(2, 3, 2);
    histogram(finalObjectives, 8, 'FaceColor', [0.5 0.8 1], 'EdgeColor', 'black');
    xlabel('Final Objective Value');
    ylabel('Frequency');
    title('Solution Quality Distribution');
    grid on;
    
    % Add statistics text
    text(0.65, 0.8, sprintf('Mean: %.3f\nStd: %.3f\nRange: %.3f', ...
        meanObj, stdObj, rangeObj), ...
        'Units', 'normalized', 'BackgroundColor', 'white', ...
        'FontSize', 9, 'EdgeColor', 'black');
    
    % 3. Constraint Satisfaction (MaxSP vs Cmax)
    subplot(2, 3, 3);
    scatter(1:length(maxSPs), maxSPs, 100, 'filled', 'MarkerFaceColor', 'red');
    hold on;
    plot([0.5, length(maxSPs)+0.5], [Cmax, Cmax], 'k--', 'LineWidth', 2);
    xlabel('Run Number');
    ylabel('Maximum Shortest Path');
    title('Constraint Satisfaction Analysis');
    legend('MaxSP values', 'Cmax = 1000', 'Location', 'best');
    grid on;
    ylim([min(maxSPs)*0.98, max(maxSPs)*1.02]);
    
    % 4. Iterations per Run
    subplot(2, 3, 4);
    bar(1:length(numIterations), numIterations, 'FaceColor', [0.5 1 0.5], 'EdgeColor', 'black');
    xlabel('Run Number');
    ylabel('Number of Iterations');
    title('Iterations per GRASP Run');
    grid on;
    
    % Add mean line
    hold on;
    plot([0.5, length(numIterations)+0.5], [meanIter, meanIter], 'r--', 'LineWidth', 2);
    text(0.7, 0.9, sprintf('Mean: %.1f', meanIter), 'Units', 'normalized', ...
         'BackgroundColor', 'white', 'EdgeColor', 'black');
    
    % 5. Time vs Iterations Relationship
    subplot(2, 3, 5);
    scatter(numIterations, totalTimes, 100, 'filled', 'MarkerFaceColor', 'magenta');
    xlabel('Number of Iterations');
    ylabel('Total Time (seconds)');
    title('Time vs Iterations Relationship');
    grid on;
    
    % Add trend line if we have enough points
    if length(numIterations) > 2
        p = polyfit(numIterations, totalTimes, 1);
        hold on;
        iterRange = [min(numIterations), max(numIterations)];
        plot(iterRange, polyval(p, iterRange), 'r--', 'LineWidth', 2);
        
        % Calculate R-squared
        yfit = polyval(p, numIterations);
        SSres = sum((totalTimes - yfit).^2);
        SStot = sum((totalTimes - mean(totalTimes)).^2);
        rsq = 1 - SSres/SStot;
        text(0.05, 0.9, sprintf('R² = %.3f', rsq), 'Units', 'normalized', ...
             'BackgroundColor', 'white', 'EdgeColor', 'black');
    end
    
    % 6. When Best Solutions Are Found
    subplot(2, 3, 6);
    histogram(bestIterations, max(3, floor(length(bestIterations)/2)), ...
              'FaceColor', [1 0.8 0.2], 'EdgeColor', 'black');
    xlabel('Iteration When Best Found');
    ylabel('Frequency');
    title('Early vs Late Convergence');
    grid on;
    
    % Add statistics
    text(0.65, 0.8, sprintf('Mean: %.1f\nMedian: %.1f', ...
        meanBestIter, median(bestIterations)), ...
        'Units', 'normalized', 'BackgroundColor', 'white', ...
        'FontSize', 9, 'EdgeColor', 'black');
    
    % Overall title
    sgtitle(sprintf('GRASP Comprehensive Analysis (%s)', timestamp), 'FontSize', 16, 'FontWeight', 'bold');
    
    % Save plot
    if ~exist('plots', 'dir')
        mkdir('plots');
    end
    filename = sprintf('plots/GRASP_comprehensive_analysis_%s.png', timestamp);
    saveas(gcf, filename);
    
    % Save analysis to text file
    if ~exist('results', 'dir')
        mkdir('results');
    end
    analysisFile = sprintf('results/GRASP_analysis_report_%s.txt', timestamp);
    
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
    
    fprintf('\nPlot saved to: %s\n', filename);
    fprintf('Analysis report saved to: %s\n', analysisFile);
    fprintf('Analysis complete!\n');
end