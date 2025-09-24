% 2025-09-02
% Analysis script for expmt structs as function (2019-12)
function data = triggerOnDeath2019Fun(defaultDir,files,useKnownBounds,sexDiff, splitDays, hrBeforeDeath, dayLoaded, phaseShift, standardExp)
    tic;

    files = cell2str(files);    % convert file list from cell array to string array
    [startList, dateList, survivalList, boxList] = pullFileInfo(files);
    
    % Pull name of script that's currently running
    fid = strsplit(mfilename('fullpath'),'\');
    fid = fid(length(fid));

    %% Initialize struct "data" and subfields

    data = []; % Initialize struct "data" (which will hold all data to analyze and plot)

    [data.timeStamp, data.dateStamp] = Stamps;
    data.outDir = strcat(defaultDir,"Trigger On Death Output\",data.dateStamp,'\');
    try
        mkdir(data.outDir);
    catch
    end

    data.files = files;

    data.startTime = min(startList);
    
    % For very rare cases, if experiment was started in the morning rather
    % than evening, so you have very little data, add padding
    morningExp = 9;
    if data.startTime < morningExp
        data.startTime = morningExp;
    end

    data.params = struct;
    
    %% Establish parameters (ADJUST AS NEEDED)
    data.params.downSamp = 100;                          % fold by which to downsample data
    data.params.avgWin = 10000;                          % size of sliding window to use for data smoothing
    data.params.fr = 3;                                  % HARD-CODED - frame rate of input experiments
    
    % Initialize LIST of ZT0 times, one for each file, will be populated
    % when going through survival sheets to collect genotypes
    data.params.zt0 = nan(1,length(files));

    data.params.dayLoaded = dayLoaded;
    data.params.hoursBeforeDeath = hrBeforeDeath;           % number of hours to align triggered on death
    data.params.lastFrames = data.params.hoursBeforeDeath...% Number of frames to analyze prior to time of last movement
        * 3600 * data.params.fr; 

    data.params.doSexDiff = sexDiff;             % Look at sex differences
    data.params.doToDHist = 1;                   % Output histogram of times of last movement
    data.params.splitTodByDay = splitDays;       % Output histograms of times of last death by day of death (option made for circaidan exps)
    data.params.saveData = 1;                    % Option to save data struct or not
    data.params.fillNan = 1;                     % Replace NaN values in position matrix with last known position
    data.params.plotAllCads = 1;                 % Plot smoothed y position traces for each cadaver along with mean yposition
    data.params.doPlot = 1;                      % Plot summary graphs

    % Graphing options
    data.graph = {};
    data.graph.xInt = data.params.hoursBeforeDeath/12;  % interval between x ticks in hours
    data.graph.shadeIntensity = 0.8;                    % change intensity of error shading
    data.graph.colors = cneColors(data.graph.shadeIntensity);
    data.graph.legFont = 14;                            % size of legend font, delta AUC shown on graph
    data.graph.tickFont = 14;
    data.graph.labelFont = 18;
    data.graph.titleFont = 14;

    %% Get info about experiment

    if standardExp
        data.rigAngle = "30";
        data.media = "5AS at 0";
    else
        dispPrompt = '? What angle was this experiment(s) run at? ';
    	data.rigAngle = string(input(dispPrompt,'s'));
        dispPrompt = '? Describe media? ';
    	data.media = string(input(dispPrompt,'s'));
    end

    %% Define the various subfields you want to save data for
    data.matrices = {'allMatrix','toDmatrix'};
    plotData = {'se','avg','smoothdata','Allavg','Allse'};
                                                % to save all of your plot data 
                                                %(avg value across all of same fly type, 
                                                % standard error (se) for the avg, fill to shade error bars and 
                                                % matrix to store all data in
                                                % matrix
    data.feat = {'ypos','speed'};          % ypos = y position; expmt.Speed.data = expmt.Speed.data

    data.rXes = {'Alive','Cadavers','Uninfected'};   % 3 possible outcomes for flies - exposed > cadaver or alive and unexposed > uninfected

    if data.params.doSexDiff == true
        data.sexes = {'Female','Male'};
    else
        data.sexes = {'MixedSex'};
    end

    %% Determine # of genotypes in experiment
    % Each genotype will output its individual data struct
    [cohortList,genoList] = deal("");
    count = [];
    [count.Alive,count.Cadavers,count.Uninfected,count.NI] = deal(0);
    expFrames = NaN(1,length(files));
    maxLength = 0;

    % Go through each excel sheet and make a list of all unique genotypes
    % and determine ZT0 for each file
    for a=1:length(survivalList)

        load(files(a));
        
        % Automatically determining whether run on EDT (daylight savings) or EST (standard)
        expRunDate = datenum(dateList(a));    
        if expRunDate >= datenum("01-01-2018") && expRunDate < datenum("01-01-2019")
            edtStart = "03-11-2018";
            edtEnd = "11-04-2018"; 
        elseif expRunDate >= datenum("01-01-2019") && expRunDate < datenum("01-01-2020")
            edtStart = "03-10-2019";
            edtEnd = "11-03-2019"; 
        elseif expRunDate >= datenum("01-01-2020") && expRunDate < datenum("01-01-2021")
            edtStart = "03-08-2020";
            edtEnd = "11-01-2020"; 
        elseif expRunDate >= datenum("01-01-2021") && expRunDate < datenum("01-01-2022")
            edtStart = "03-14-2021";
            edtEnd = "11-07-2021";
        elseif expRunDate >= datenum("01-01-2022") && expRunDate < datenum("01-01-2023")
            edtStart = "03-13-2022";
            edtEnd = "11-06-2022";
        elseif expRunDate >= datenum("01-01-2023") && expRunDate < datenum("01-01-2024")
            edtStart = "03-12-2023";
            edtEnd = "11-05-2023";
        elseif expRunDate >= datenum("01-01-2024") && expRunDate < datenum("01-01-2025")
            edtStart = "03-10-2024";
            edtEnd = "11-03-2024";
        elseif expRunDate >= datenum("01-01-2025") && expRunDate < datenum("01-01-2026")
            edtStart = "03-10-2025";
            edtEnd = "11-03-2025";
        else
            msgbox("WTF year is it?","WTF?");
            pause;
        end
        if expRunDate >= datenum(edtStart) && expRunDate < datenum(edtEnd)
            data.params.zt0(a) = 25;
        else
            data.params.zt0(a) = 24;
        end    
        
        expFrames(a) = length(expmt.Centroid.data); 
        
        % Check that experiment was captured at 3 Hz
        if expmt.parameters.target_rate ~= 3
            disp('Frame rate assumptions are wrong! Experiment was NOT run at 3 Hz!');
            break;
        end
        
        % Establish total length of experiment to align, using experiment that
        % ran longest relative to startTime (earliest starting experiment)
        totLength = expFrames(a) + ceil((startList(a)-data.startTime)*3600*data.params.fr);
        if totLength > maxLength
            maxLength = totLength;
        end

        % Read in survival data to determine # of ROIs and # of genotypes
        survival = readtable(survivalList(a)); 
        roi = 1:height(survival);        
        geno = string(survival{roi,'Geno'});
        uGeno = transpose(unique(geno));

        genoList = [genoList, uGeno(~ismember(uGeno,genoList))]; %#ok<AGROW>
        try
            if ~ismember(survival{1,'Cohort'},cohortList)
                cohortList = [cohortList,survival{1,'Cohort'}];
            end
        catch
        end

        % Count survivors, cadavers, NI and uninfected flies to initialize
        % data structs in next section
        for j=1:max(roi)
            if survival{j,'Outcome'} == 1
                count.Cadavers = count.Cadavers + 1;
            elseif survival{j,'Status'} == 1
                    if strcmp(survival{j,'Rx'},'Uninfected')
                        count.Uninfected = count.Uninfected +1;
                    else
                        count.Alive = count.Alive + 1;
                    end
            else
                count.NI = count.NI+1;
            end
        end
    end

    genoList = genoList(2:length(genoList));
    disp("Genotypes found: ");
    disp(genoList);
    
    %% Make genoListSafe, a list of all genotypes that don't have any illegal characters for Windows files
    % This will be used for naming any output files
    genoListSafe = makeSafeName(genoList);
    
    %% Calculate useful variables 
    % Determine how many hours of data need to be aligned
    data.params.alignLength = ceil(maxLength/(3600*data.params.fr));
    data.params.endTime = data.startTime + data.params.alignLength; 
    
    % Initialize variable to hold how many frames each experiment needs added on front and
    % back to align all experiments (since started at slightly different
    % times)
    data.params.frameBegShift = NaN(1,length(files));
    data.params.frameEndShift = NaN(1,length(files));
    
    % Find the earliest experiment start time and end time and
    % add frames in front of and after current experiment to
    % align within window of length "data.params.alignLength" hours
    
%     if length(survivalList)==1
%         data.params.frameBegShift = 0;
%         data.params.frameEndShift = 0;
%     else
%         data.params.frameBegShift = round((startList - data.startTime) * 3600 * data.params.fr);
%         data.params.frameEndShift = round((data.params.endTime - ...
%         (startList + (expFrames/ (3600*data.params.fr)))) * 3600 * data.params.fr);
%     end
    
    if data.startTime == morningExp
        data.params.frameBegShift = round((startList+24 - data.startTime) * 3600 * data.params.fr);
    else
        data.params.frameBegShift = round((startList - data.startTime) * 3600 * data.params.fr);
    end
    
    data.params.frameEndShift = round((data.params.endTime - ...
        (startList + (expFrames/ (3600*data.params.fr)))) * 3600 * data.params.fr);         

    %% Initialize data subfields

    % Output different data struct for each geno...
    for b=1:length(genoList)
        tic;

        %...and sex
        for i=(1:length(data.sexes))
            
            disp(strcat('Reading experiment data for ',genoList(b),', ',data.sexes{i},'...'));

            % 1st level separates flies by outcome
            for h=(1:length(data.rXes))              
                data.(data.rXes{h})=[];
                initNum = count.(data.rXes{h});
                
                % Initialize field to keep track of day of death for each
                % cadaver
                if strcmp(data.rXes{h},'Cadavers')
                    data.(data.rXes{h}).dayOfDeath = NaN(1,initNum);
                end
                
                % 2nd level contains tracked variable, position or speed (or best tau, which is added separately)
                for g=(1:length(data.feat))         
                    data.(data.rXes{h}).(data.feat{g}) = [];

                    % 3rd level contains variables you will plot 
                    data.(data.rXes{h}).(data.feat{g}).allMatrix = zeros(data.params.alignLength * 3600 * data.params.fr, initNum);
                    data.(data.rXes{h}).(data.feat{g}).toDmatrix = zeros((data.params.alignLength * 3600 * data.params.fr)+1, initNum);

                    for m=(3:length(plotData))  
                        data.(data.rXes{h}).(data.feat{g}).(plotData{m}) = [];
                    end
                end
            end

            %% Use experiment dates to generate a file prefix (filePre)
            f = "";
            if length(dateList) > 6
                maxFiles = 6;
            else
                maxFiles = length(dateList);
            end
            for a = (1:maxFiles)
                f=strcat(boxList(a),"-",dateList(a),", ",f);  
            end

            f = char(f);
            f = string(f(1:length(f)-2));
            if length(dateList) > maxFiles
                fName = strcat(f,"...");
            else
                fName = f;
            end
            
            % 2020-08-08 - Simplified file name (no longer output input
            % experiments in file name, e.g. SUM5-02-06-2020)
            data.filePre = strcat(genoListSafe(b),"-",data.sexes{i});            
            data.geno = genoList(b);
            data.graphTitle = genoList(b) + "-" + data.sexes{i} + "-" ...
                + "Exp. " + f + newline +...
                " avgWin=" + num2str(data.params.avgWin) + " downsample=" + num2str(data.params.downSamp);

            %% Load each expmt struct, grabbing normalized time of last movement for cadavers
            % initialize list of max ROIs, last frames
            [roiMax,last] = deal(zeros(1,numel(files)));  
            currCount = [];
            [currCount.Alive,currCount.Cadavers,currCount.Uninfected] = deal(1);

            % list to hold all last movement values for cadavers, normalized to ZT0 for all experiments analyzed
            cadLastMvmt = [];              

            % initialize cell array to hold outcome of each ROI (i.e. alive, uninfected or infected)
            [lastMvmt,group,survival,data.Cadavers.bestTau] = deal(cell(1,numel(files)));  

            % Iterate over each expmt struct (from each .mat file), ID each
            % fly, pull time of death (in frames post ZT0)
            for a = 1:numel(files)      
                item = files(a);
                load(item);
                
                % Open survival file so that you have correct info for experiment of
                % interest in ROI loop below
                survival{a} = readtable(survivalList(a));    
                
                % Find # of ROIs, # of frames for current expmt
                roiMax(a) = size(expmt.Centroid.data,3);
                last(a) = size(expmt.Centroid.data,1); 
                lastMvmt{a} = NaN(1,roiMax(a));
                group{a} = cell(1,roiMax(a));
                data.Cadavers.bestTau{a} = zeros(1,roiMax(a));

                if data.params.doSexDiff == true
                    if strcmp(data.sexes{i},'Female')
                        sex = {'F'};
                    else
                        sex = {'M'};
                    end
                else
                    sex = {'M','F'};
                end

                for roi =(1:roiMax(a))       
                    if strcmp(survival{a}{roi,'Geno'},genoList(b)) && ismember(survival{a}{roi,'Sex'},sex)
                        
                        % Cadaver ROIs
                        if survival{a}{roi,'Outcome'} == 1 && survival{a}{roi,'Last_mvmt'} >0

                            % NOTE 2019-08-06
                            % I used to count time of death as last frame (by
                            % leaving time of death column 0 in document) if
                            % the fly was still moving when track stopped. I
                            % stopped doing this and will not use cadavers who
                            % didn't stop moving before tracking ended. This is
                            % why last mvmt time == 0 leads to dropped cadaver

                            group{a}{roi} = 'Cadavers';  

                            % overwrite lastMoves(roi) with value in "Last_mvmt" column
                            lastMvmt{a}(roi) = round(single(survival{a}{roi,'Last_mvmt'})); 

                            % Check that lastMvmt value doesn't exceed max
                            % (last frame in dataset). If so, set to last
                            % frame in dataset
                            if lastMvmt{a}(roi) > last(a)
                                lastMvmt{a}(roi) = last(a);
                            end                         
                            
                            % Normalize last mvmt to frames since ZT0
                            lastMvmt{a}(roi) = round(lastMvmt{a}(roi)- ...
                                    ((data.params.zt0(a)-startList(a))*(3600*data.params.fr)));                              

                            % Add last mvmt to cadaver time of death list
                             cadLastMvmt = [cadLastMvmt,lastMvmt{a}(roi)]; %#ok<AGROW>  

                        elseif survival{a}{roi,'Status'} == 1
                            if strcmp(survival{a}{roi,'Rx'},'Uninfected')
                                group{a}{roi} = 'Uninfected';
                            else
                                group{a}{roi} = 'Alive';
                            end
                        else
                            group{a}{roi} = 'none';
                        end                   
                    end
                end
            end
            
            % If there were no cadavers, add a bogus time to the lastMvmt
            % list so you are still able to assign time of death to
            % uninfected and alive flies in order to generate plots
%             if isempty(cadLastMvmt)
%                 cadLastMvmt = size(expmt.Centroid.data,1);
%                 %cadLastMvmt = round([(data.params.zt0(a)-startList(a)+12)*(3600*data.params.fr)]);
%             end
            
            %% Assign each living fly a "time of last movement" from pool of actual last times for cadavers
            % (to compare movement gated on time of last movement)
            % Flies already dead, dead from other reasons or escaped from rig are excluded in 
            % being assigned mock time of last movement 
            % We repeat a loop through all experiment files in order to use
            % pool of all observed times of last movement for all control
            % animals (rather than only using times of last mvmt from day 3
            % for day 3 traces, day 4 for day 4 etc)
            for a=1:numel(files)
    
                % Likely point of inefficiency
                % need to reload data :/
                item = files(a);
                load(item);

                % Fill in NaN gaps with last observed value (option set
                % earlier)
                if data.params.fillNan
                    expmt.Centroid.data = fillmissing(expmt.Centroid.data,'previous');
                end                         

                for roi =(1:roiMax(a))
                    dropROI = 0;

                    % Randomly assign time of death to living (Alive and Uninfected) samples
                    % (normalized to frames since ZT0)
                    if strcmp(survival{a}{roi,'Geno'},genoList(b)) && ismember(survival{a}{roi,'Sex'},sex)                            
                        if ~strcmp(group{a}(roi),'none')
                            flyInd = currCount.(group{a}{roi});

                            % Grab y position data and normalize
                            if useKnownBounds
                                %Find ROIs in same row
                                currRow = survival{a}{roi,'Row'};
                                neighborInd = survival{a}{:,'Row'}==currRow;
                                
                                %Determine min and max y values for flies in row (assumes
                                %that at least one fly/row has sampled upper y bound and one
                                %has sampled lower y bound
                                minY = min(min(squeeze(expmt.Centroid.data(:,2,neighborInd))));
                                maxY = max(max(squeeze(expmt.Centroid.data(:,2,neighborInd))));
                                ypos = scaleKnownBoundary(expmt.Centroid.data(:,2,roi),minY,maxY);
                            else
                                ypos = scaleHt(expmt.Centroid.data(:,2,roi));
                            end

                            if max(ypos) > 1.1 % should rarely occur, ideally should never occur
                                disp(max(ypos));
                                disp(roi);
                                disp(files(a));
                            end
                            
                            % If not a cadaver, assign random time of last
                            % movement
                            if ~strcmp(group{a}{roi},'Cadavers')
                                todAssigned = false;
                                tryCount = 1;
                                while ~todAssigned
                                    % Try is used because not all
                                    % experiments have same length, so some
                                    % tods might be out of range, will keep
                                    % trying to assign until one fits
                                    % instead of breaking and using default
                                    % value (NaN). Set limit of tries to
                                    % avoid getting stuck in infinite loop
                                    % for bad ROIs.
                                    if isempty(cadLastMvmt)
                                        cadLastMvmt = size(expmt.Centroid.data,1);
                                    end
                                    try                               
                                        lastMvmt{a}(roi) = datasample(cadLastMvmt,1); 
                                        if ~isnan(ypos(lastMvmt{a}(roi)))
                                            todAssigned = true;
                                        else
                                            tryCount = tryCount + 1;
                                        end
                                    catch
                                        tryCount = tryCount + 1;
                                    end
                                    % Give up after 10 tries and drop ROI
                                    % from data matrix
                                    if tryCount == 10
                                        dropROI = 1;
                                        todAssigned = true;
                                    end
                                end
                            end

                            if ~dropROI
                                alignedHt = vertcat(nan(data.params.frameBegShift(a),1), ypos,nan(data.params.frameEndShift(a),1));
                                alignedSpeed = vertcat(nan(data.params.frameBegShift(a),1), expmt.Speed.data(:,roi),nan(data.params.frameEndShift(a),1));

                                %% Save all y position and speed info aligned to actual time under field "allMatrix"
                                data.(group{a}{roi}).ypos.allMatrix(:,flyInd) = alignedHt;
                                data.(group{a}{roi}).speed.allMatrix(:,flyInd)= alignedSpeed;

                                %% Save y position and speed info aligned to time of death under "toDmatrix"
                                if ~isempty(cadLastMvmt)          

                                    % Convert last mvmt back to frame in OG experiment
                                    timeOfDeath = round(lastMvmt{a}(roi) + ((data.params.zt0(a)-startList(a))*(3600*data.params.fr)));

                                    % for the extremely rare case that
                                    % timeOfDeath is exactly at the length
                                    % of data.params.lastFrames... 
                                    if timeOfDeath == data.params.lastFrames 
                                        timeOfDeath = timeOfDeath - 1;
                                    end
                                    
                                    % First, check if there are not sufficient frames in experiment to collect
                                    % desired number of last frames "data.params.lastFrames"
                                    if timeOfDeath < data.params.lastFrames 
                                        % ...If so, figure out how many frames you're shy by and
                                        % append on to front of data to fill out - all times of
                                        % death will occur at same frame with remaining data
                                        % kept aftewards
                                        missingFrames = data.params.lastFrames - timeOfDeath;
                                        ypos = vertcat (nan (missingFrames,1),...
                                                        ypos(1:end - missingFrames+1),...
                                                        nan(data.params.frameEndShift(a) + data.params.frameBegShift(a),1)); 
                                        speed = vertcat (nan (missingFrames,1),...
                                                         expmt.Speed.data (1:end - missingFrames+1,roi),...
                                                         nan(data.params.frameEndShift(a) + data.params.frameBegShift(a),1));
                                    else
                                        ypos = vertcat (ypos(timeOfDeath - data.params.lastFrames:end),...
                                                       nan(timeOfDeath - data.params.lastFrames,1),...
                                                       nan(data.params.frameEndShift(a) + data.params.frameBegShift(a),1));
                                        speed = vertcat (expmt.Speed.data (timeOfDeath - data.params.lastFrames:end,roi),...
                                                        nan(timeOfDeath - data.params.lastFrames,1),...
                                                        nan(data.params.frameEndShift(a) + data.params.frameBegShift(a),1));
                                    end

                                    % Save data aligned by time of death
                                    try
                                        data.(group{a}{roi}).ypos.toDmatrix(:,flyInd) = ypos;
                                        data.(group{a}{roi}).speed.toDmatrix(:,flyInd) = speed;
                                    catch
                                        disp("failed to generate data aligned to tod");
                                    end
                                    
                                    % Save day of death
                                    if strcmp(group{a}{roi},'Cadavers')
                                        dayOfDeath = ceil((lastMvmt{a}(roi)/(3600*data.params.fr))/24)+ data.params.dayLoaded;
                                        data.(group{a}{roi}).dayOfDeath(flyInd) = dayOfDeath;
                                    end                                   

                                    % Look for manually-annotated best tau and
                                    % save, if available
                                    if single(survival{a}{roi,'Best_tau'})~=0
                                        data.Cadavers.bestTau{a}(roi) = survival{a}{roi,'Best_tau'} ...
                                            - ((data.params.zt0(a)-startList(a))*(3600*data.params.fr));
                                    else
                                        data.Cadavers.bestTau{a}(roi) = NaN;
                                    end
                                else
                                    disp('No cadavers found in dataset! Cannot align flies around time of death');
                                end
                                
                                currCount.(group{a}{roi}) = currCount.(group{a}{roi}) +1; 
                            end
                        end
                    end                
                end
            end

            disp(['All data read! (', num2str(round(toc)),' sec elapsed)']);

            data.ZTlastMvmnts = cadLastMvmt/(3600*data.params.fr);
            data.ZTlastMvmnts(data.ZTlastMvmnts<0) = data.ZTlastMvmnts(data.ZTlastMvmnts<0) + 24;

            %% Remove empty cells from data matrices
            for m = 1:length(data.rXes)
                for j = 1:length(data.feat)
                    for k = 1:length(data.matrices)
                        data.(data.rXes{m}).(data.feat{j}).(data.matrices{k}) = ...
                            data.(data.rXes{m}).(data.feat{j}).(data.matrices{k})(:,any(data.(data.rXes{m}).(data.feat{j}).(data.matrices{k})));
                    end
                end
            end
            data.Cadavers.dayOfDeath = data.Cadavers.dayOfDeath(~isnan(data.Cadavers.dayOfDeath));

            %% Output time of death histogram

            if data.params.doToDHist   
                plotTodHistogram(data,phaseShift)
            end
            
            if data.params.splitTodByDay  
                figure;
                hold on;
                key = cell(1,7);
                areaDay = 0+phaseShift:12+phaseShift;
                areaNight = 12+phaseShift:24+phaseShift;
                if max(areaNight) > 24
                    areaNight1 = 0:phaseShift;
                    areaNight2 = 12+phaseShift:24;
                    area(areaNight1,ones(1,length(areaNight1)),'FaceColor','k','FaceAlpha',0.3,'HandleVisibility','off');
                    area(areaNight2,ones(1,length(areaNight2)),'FaceColor','k','FaceAlpha',0.3,'HandleVisibility','off');
                else
                    area(areaNight,ones(1,length(areaNight)),'FaceColor','k','FaceAlpha',0.3,'HandleVisibility','off');   
                end
                area(areaDay,ones(1,length(areaDay)),'FaceColor','y','FaceAlpha',0.3,'HandleVisibility','off');
                for p=1:7
                    set1 = find(data.ZTlastMvmnts > 24*(p-1));
                    set2 = find(data.ZTlastMvmnts < 24*(p));
                    deaths = data.ZTlastMvmnts(intersect(set1,set2));
                    numCad = length(deaths);
                    if numCad >1
                        plotTimes = mod(deaths,24);
                        h = histogram(plotTimes,48,'Normalization','pdf','BinLimits',[0 24]);                    
                        key{p} = strcat("Day ",num2str(p+data.params.dayLoaded),"= ",num2str(numCad)); 
                    end
                end
                title(['Times of last movements',data.graphTitle],'FontSize',data.graph.titleFont);
                key = key(~cellfun('isempty',key)); % remove any empty entries otherwise Matlab will be pissed
                legend(key);
                xlabel('Time (ZT hours)','FontSize',data.graph.labelFont);
                ylabel('Probability','FontSize',data.graph.labelFont);
                set(gca,'FontSize',data.graph.labelFont);
                xlim([0 24]);
                ylim([0 0.5]);
                set(gcf,'PaperUnits','inches','PaperPosition',[0 0 10 8]);
                print(strcat(data.outDir,data.filePre,'_tod_histogram_byday.png'),'-dpng');
                close();
            end
        end
    end
end