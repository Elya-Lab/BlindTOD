% 2021-02-09
% Make a temporary .mat file containing a data struct consisting only of
% cadavers. The purpose of doing this as a separate step is to try and
% minimize the number of times I have to load each data file when I go
% through and perform manual time of death assignment.

function randCadFiles = makeRandMat(randCadArray, convFiles, maxROIperFile, maxLen)
    % Determine total number of ROIs in set
    totalROI = size(randCadArray,2);
    
    % Determine number of output files to make, if each .mat file can only
    % have maxROIperFile # of ROIs
    numFiles = ceil(totalROI/maxROIperFile);
    randCadFiles = cell(1,numFiles);

    % Going to make one struct at a time, so there's only 1 struct present
    % in memory at any given time
    for j=1:numFiles
        randData = struct;
        randData.ypos = NaN(maxLen,maxROIperFile); % array for holding y position data in randData
        randData.speed = NaN(maxLen,maxROIperFile); % array for holding speed data in randData
        randData.survival = cell(1,maxROIperFile);% keep original survival file ID for saving TOD info later
        randData.ogROI = NaN(1,maxROIperFile); % keep original ROI ID for saving TOD info later
        randData.input = convFiles; % to save the files used to make the random data structs!
        
        idxRange = (j-1)*maxROIperFile + 1:(j)*maxROIperFile;
        
        % Means we have to open each data file j number of times to make
        % randomized cadaver structs
        for i=1:length(convFiles)
            % Figure out which idxs in randCadArray came from this dataset
            idxs = find(contains(randCadArray(2,:),convFiles(i)));

            % Determine which of these ROIs are within bounds of current
            % randomized data set (max of maxROIperFile ROIs per file)
            keptIdxs = intersect(idxRange,idxs);            
            
            % Figure out ROI numbers for these cads within data file
            targetROIs = randCadArray(1,keptIdxs);
            targetROIs = cell2mat(targetROIs);
         
            % Load data file
            load(convFiles{i});
            expLen = size(expmt.Centroid.data,1);

            for k = 1:length(targetROIs)
               % Save y position data to randData struct
               randData.ypos(1:expLen,keptIdxs(k)-((j-1)*128)) = expmt.Centroid.data(:,2,targetROIs(k));
               % Save speed data to randData struct
               randData.speed(1:expLen,keptIdxs(k)-((j-1)*128)) = expmt.Speed.data(:,targetROIs(k));
               
               % Save original ROI survival path for saving time of death
               % information later
               randData.survival(keptIdxs(k)-((j-1)*128)) = randCadArray(3,keptIdxs(k));
               % Save original ROI identity for saving time of death
               % information later
               randData.ogROI(keptIdxs(k)-((j-1)*128))=targetROIs(k); 
            end
        end
        
        % Remove any empty entries before saving
        lastEntry = find(isnan(randData.ogROI),1)-1;
        if ~isempty(lastEntry)
            randData.ypos = randData.ypos(:,1:lastEntry);
            randData.speed = randData.speed(:,1:lastEntry);
            randData.survival = randData.survival(1:lastEntry);
            randData.ogROI = randData.ogROI(1:lastEntry);
        end
        
        [ts, ds] = Stamps;
        outPath = strcat("C:\Users\User\Documents\Behavior Analysis\Analysis\Temp\"',ds,'_',ts,'rand_',num2str(j),'.mat');
        save(outPath,'randData','-mat','-v7.3');
        randCadFiles{j} = outPath;
    end
end