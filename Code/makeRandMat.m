% 2021-02-09
% Make a temporary .mat file containing a data struct consisting only of
% cadavers. The purpose of doing this as a separate step is to try and
% minimize the number of times I have to load each data file when I go
% through and perform manual time of death assignment.

function randCadFiles = makeRandMat(randCadArray, convFiles, maxROIperFile, maxLen, outDir)

    % --- NEW: build output directory robustly ---
    % outDir should be something like analysisDir (e.g., fullfile(baseDir,'Analysis'))
    tempDir = fullfile(outDir, 'Temp');
    if ~exist(tempDir, 'dir')
        mkdir(tempDir);
    end

    % Determine total number of ROIs in set
    totalROI = size(randCadArray, 2);

    % Determine number of output files to make, if each .mat file can only
    % have maxROIperFile # of ROIs
    numFiles = ceil(totalROI / maxROIperFile);
    randCadFiles = cell(1, numFiles);

    % Going to make one struct at a time, so there's only 1 struct present
    % in memory at any given time
    for j = 1:numFiles
        randData = struct;
        randData.ypos = NaN(maxLen, maxROIperFile);   % array for holding y position data in randData
        randData.speed = NaN(maxLen, maxROIperFile);  % array for holding speed data in randData
        randData.survival = cell(1, maxROIperFile);   % keep original survival file ID for saving TOD info later
        randData.ogROI = NaN(1, maxROIperFile);       % keep original ROI ID for saving TOD info later
        randData.input = convFiles;                   % to save the files used to make the random data structs!

        idxRange = (j - 1) * maxROIperFile + 1 : (j) * maxROIperFile;

        % Means we have to open each data file j number of times to make
        % randomized cadaver structs
        for i = 1:length(convFiles)

            % Figure out which idxs in randCadArray came from this dataset
            idxs = find(contains(randCadArray(2, :), convFiles(i)));

            % Determine which of these ROIs are within bounds of current
            % randomized data set (max of maxROIperFile ROIs per file)
            keptIdxs = intersect(idxRange, idxs);

            % If none from this file belong in this output chunk, skip work
            if isempty(keptIdxs)
                continue;
            end

            % Figure out ROI numbers for these cads within data file
            targetROIs = randCadArray(1, keptIdxs);
            targetROIs = cell2mat(targetROIs);

            % Load data file
            load(convFiles{i}); %#ok<LOAD> loads expmt
            expLen = size(expmt.Centroid.data, 1);

            for k = 1:length(targetROIs)
                % Map global cad index -> local column index in this output file
                localCol = keptIdxs(k) - (j - 1) * maxROIperFile;

                % Save y position data to randData struct
                randData.ypos(1:expLen, localCol) = expmt.Centroid.data(:, 2, targetROIs(k));

                % Save speed data to randData struct
                randData.speed(1:expLen, localCol) = expmt.Speed.data(:, targetROIs(k));

                % Save original ROI survival path for saving time of death later
                randData.survival(localCol) = randCadArray(3, keptIdxs(k));

                % Save original ROI identity for saving time of death later
                randData.ogROI(localCol) = targetROIs(k);
            end
        end

        % Remove any empty entries before saving
        firstEmpty = find(isnan(randData.ogROI), 1, 'first');
        if ~isempty(firstEmpty)
            lastEntry = firstEmpty - 1;
            randData.ypos = randData.ypos(:, 1:lastEntry);
            randData.speed = randData.speed(:, 1:lastEntry);
            randData.survival = randData.survival(1:lastEntry);
            randData.ogROI = randData.ogROI(1:lastEntry);
        end

        [ts, ds] = Stamps;

        % --- NEW: build filename + full path robustly ---
        fileName = sprintf('%s_%s_rand_%d.mat', ds, ts, j);
        outPath  = fullfile(tempDir, fileName);

        save(outPath, 'randData', '-mat', '-v7.3');
        randCadFiles{j} = outPath;
    end
end