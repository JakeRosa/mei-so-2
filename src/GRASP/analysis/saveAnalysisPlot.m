function filename = saveAnalysisPlot(figHandle, plotType, plotName, timestamp, varargin)
% Standardized plot saving utility for GRASP analysis
% Inputs:
%   figHandle - figure handle or 'gcf' for current figure
%   plotType - folder name (e.g., 'parameters', 'quality', 'nodes', 'phases', 'comparisons')
%   plotName - specific plot name (e.g., 'sensitivity_heatmap', 'convergence')
%   timestamp - timestamp string for uniqueness
%   varargin - optional arguments:
%     'Resolution', dpi - set resolution (default: 300)
%     'Format', ext - set format (default: 'png')
%     'Size', [w,h] - set figure size in pixels (default: [2000, 1400])
% Output:
%   filename - full path of saved file

    % Parse optional arguments
    p = inputParser;
    addParameter(p, 'Resolution', 300, @isnumeric);
    addParameter(p, 'Format', 'png', @ischar);
    addParameter(p, 'Size', [2000, 1400], @isnumeric);
    parse(p, varargin{:});
    
    resolution = p.Results.Resolution;
    format = p.Results.Format;
    figSize = p.Results.Size;
    
    % Ensure figure handle
    if ischar(figHandle) && strcmp(figHandle, 'gcf')
        figHandle = gcf;
    end
    
    % Set figure size for better readability
    set(figHandle, 'Position', [100, 100, figSize(1), figSize(2)]);
    
    % Create organized folder structure
    baseDir = 'plots';
    plotDir = fullfile(baseDir, plotType);
    
    % Create directories if they don't exist
    if ~exist(baseDir, 'dir')
        mkdir(baseDir);
    end
    if ~exist(plotDir, 'dir')
        mkdir(plotDir);
    end
    
    % Generate filename
    filename = fullfile(plotDir, sprintf('%s_%s.%s', plotName, timestamp, format));
    
    % Save with high resolution
    if strcmp(format, 'png')
        saveas(figHandle, filename);
        % Also save high-res version
        print(figHandle, filename, '-dpng', sprintf('-r%d', resolution));
    elseif strcmp(format, 'fig')
        savefig(figHandle, filename);
    else
        saveas(figHandle, filename);
    end
    
    fprintf('Plot saved: %s\n', filename);
end