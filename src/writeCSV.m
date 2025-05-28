function writeCSV(filename, cellArray)
% Write cell array to CSV file
% This is a simple CSV writer in case cell2csv is not available
%
% Inputs:
%   filename - output CSV filename
%   cellArray - cell array with data to write

    fid = fopen(filename, 'w');
    if fid == -1
        error('Could not open file %s for writing', filename);
    end
    
    for row = 1:size(cellArray, 1)
        for col = 1:size(cellArray, 2)
            if isnumeric(cellArray{row, col})
                fprintf(fid, '%.4f', cellArray{row, col});
            else
                fprintf(fid, '%s', cellArray{row, col});
            end
            if col < size(cellArray, 2)
                fprintf(fid, ',');
            end
        end
        fprintf(fid, '\n');
    end
    
    fclose(fid);
end