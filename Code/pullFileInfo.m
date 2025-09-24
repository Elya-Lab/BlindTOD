% 2025-09-02
function [startList,dateList,survivalList, boxList] = pullFileInfo(files)
    n = numel(files);
    [dateList,survivalList,boxList] = deal(strings(1,n));
    startList = zeros(1,n);

    for i = 1:n
        % OS-agnostic split into directory, base name, and extension
        thisFile = char(files(i));
        [expDir, expBase, ~] = fileparts(thisFile);

        % Metadata from filename
        startList(i) = returnExpStartTime(string(expBase));
        expDate     = returnExpDate(string(expBase));
        dateList(i) = expDate;

        % Survival Excel file lives alongside the .mat
        survivalList(i) = fullfile(expDir, sprintf('%s-survival_data.xlsx', expDate));

        % Box ID (if getboxID requires just the folder path)
        try
            boxList(i) = string(getboxID(expDir));
        catch
            boxList(i) = "NA";
        end
    end
end