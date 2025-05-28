function writeCSV(filename, cellArray)
    fid = fopen(filename, 'w');
    if fid == -1
        error('Could not open file %s for writing', filename);
    end
    
    for row = 1:size(cellArray, 1)
        for col = 1:size(cellArray, 2)
            if isnumeric(cellArray{row, col})
                if cellArray{row, col} == inf
                    fprintf(fid, 'inf');
                else
                    fprintf(fid, '%.6f', cellArray{row, col});
                end
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