% 2025-02-09
% Takes in list of file paths pointing to (denoised) summit data structs,
% goes through and finds all cadaver ROIs, returns list of these along with
% corresponding data file and survival data files

function [cadArray, localTime] = returnCadROIs(convFiles)
% Takes in list of file paths to (denoised) expmt structs (.mat),
% finds all cadaver ROIs, and returns [ROI, dataFile, survivalFile] plus localTime.
%
% OS-agnostic: uses fileparts/fullfile (no backslash joins).

    % Preallocate (max cadavers per typical board)
    cadArray  = cell(3, numel(convFiles)*96);
    cadCt     = 0;
    localTime = cell(2, numel(convFiles));

    for i = 1:numel(convFiles)
        thisPath = char(convFiles{i});
        load(thisPath);  % loads 'expmt'

        % ----- OS-agnostic path handling -----
        [expDir, expBase, ~] = fileparts(thisPath);   % expBase = filename without extension

        % Dates/times from filename (use basename)
        expDate   = returnExpDate(string(expBase));
        startHour = returnExpStartTime(string(expBase));

        % Survival Excel path (same folder as .mat)
        survivalFile = fullfile(expDir, sprintf('%s-survival_data.xlsx', expDate));

        % Local time metadata outputs
        localTime{1,i} = convertToLocalTime(expmt, startHour);
        localTime{2,i} = survivalFile;

        % Load survival sheet
        survival = readtable(survivalFile);

        % Scan ROIs for "Cadaver"
        for roi = 1:expmt.nTracks
            if strcmp(classifyROI(survival, roi), 'Cadaver')
                cadCt = cadCt + 1;
                cadArray{1, cadCt} = roi;
                cadArray{2, cadCt} = thisPath;
                cadArray{3, cadCt} = survivalFile;
            end
        end
    end

    % Trim to actual count
    cadArray = cadArray(:, 1:cadCt);
end