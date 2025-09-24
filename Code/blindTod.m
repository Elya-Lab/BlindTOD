% 2025-09-02
% Call time of death blinded
% Goal: 
% 1) allow user to load any number of .mat files containing
% (denoised) summiting data.
% 2) determine which ROIs in files are cadavers and save these in list.
% 3) scramble ROI list and write temporary scrambled .mat data structs to
% call time of death
% 4) go through each ROI and call time of death (no box, date, ROI,
% genotype info is provided) and save new time of death in separate column
% in survival data
%
% Afterwards, I can compare the times of death that I called when blinded
% to genotype etc vs my initial calls to (hopefully) demonstrate that there
% isn't systematic bias in how I call tod.

%% Load in files

plotBoards = 1; % plot entire board, to check for any ROIs that weren't tracked
doDenoise = 1; % run denoising
overwriteROICalls = 0; % 0 = only call tod for ROIs that have not been previously called blinded 
                  % (i.e. if value already in Blind_TOD column of survival spreadsheet); 
                  % 1 = call every tod regardless
analyzeAtEnd = 1;

% Directory to look in when selecting data file
baseDir = '/Users/brandonfricker/Documents/MATLAB/Elya Margo/Behavior Analysis'; %Set this to the basedirectory for YOUR computer.

% Define subdirectories (OS-agnostic with fullfile)
dataDir     = fullfile(baseDir, 'Behavior data');
analysisDir = fullfile(baseDir, 'Analysis');

% If convFiles hasn't already been initialized, set it to []
if exist('convFiles','var') == 0
    convFiles = [];
end

% Check if files have been previously loaded (still in memory) &
% ask if user wants to select new files or use what's saved in convFiles
[convFiles, fileChoice] = askForNewFiles(convFiles);

% Load data files if no files were previously loaded or user wants to input
% new files
if strcmp(fileChoice,'Yes') || isempty(convFiles)
    convFiles = selectMatFiles(dataDir);
end

% Go through each file, if not yet converted will do so
convFiles = convertMargo(convFiles);

if doDenoise
    convFiles = autoDenoise(convFiles, 40, 20);
end

if plotBoards
   [startList, dateList, survivalList, boxList] = pullFileInfo(convFiles);
   for i=1:length(convFiles)
       survival=readtable(survivalList{i});
       load(convFiles{i}); % load expmt struct
       plotAllROIs(convFiles{i},survival,expmt);
   end
end

%% Find cadaver ROIs
% maxLen = length (in frames) of longest experiment
% cadArray = 3 by ROI array, where ROI = number of cadavers found in all
% files, row 1 = ROI number in file, row 2 = file path, row 3 = survival
% file path
% localTime = 2 x # files cell array, where 1st row is local time array,
% 2nd row is survival data path (effectively a label for each local time
% array)
[cadArray, localTandSurvival] = returnCadROIs(convFiles);

% Find length of each array in localTime
[s,d] = cellfun(@size,localTandSurvival);

% Find maximum length of these arrays, to figure out longest experiment
maxLen = max(max(d));
clear s d;

%% Randomize cadaver ROIS
% Randomizes order of cadavers in array
randCadArray = cadArray(:,randperm(length(cadArray)));
totalCads = size(randCadArray,2);
disp(strcat("Total cadavers = ", num2str(totalCads)));

%% Generate temporary scrambled .mat file
% Generate .mat files that contain up to data for X cadavers (set with maxROIperFile)
maxROIperFile = 128;
randCadFiles = makeRandMat(randCadArray, convFiles, maxROIperFile, maxLen);

%% Go through scrambled .mat files and call times of death
manuallyCallTod(randCadFiles, localTandSurvival, totalCads, overwriteROICalls);
disp("Times of death done!");

% % Takes in cell array of survival files
if analyzeAtEnd
   

    %% Run analyses
    phaseShift = 0;          % Difference between assumed light cycle and actual light cycle, in hours. Put '0' if none.
    useKnownBounds = 0;      % use row-wide y min and y max ypos to ensure scaling is correct for all ROIs
    sexDiff = 0;             % separate data by sex and output separate data structs and plots
    splitDays = 1;           % split time of death by day of death? (irrelevant for experiments shorter than 24 hours)
    hrBeforeDeath = 12;      % how many hours of data do you want to align before death
    dayLoaded = 1;           % day that flies were loaded (only used to properly offset day of death histogram)
    standardExp = 1;

    data = triggerOnDeath2019Fun(analysisDir, convFiles, useKnownBounds, sexDiff, splitDays, hrBeforeDeath, dayLoaded, phaseShift, standardExp);
end