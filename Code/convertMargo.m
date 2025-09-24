function convertedFiles = convertMargo(listToConvert)
    convertedFiles = cell(1,length(listToConvert));

    for i = 1:length(listToConvert)
        % Check if file has already been converted
        if contains(listToConvert{i},'convert','IgnoreCase',true)
            convertedFiles{i} = listToConvert{i};
        else
            % Load in .mat file with expmt struct
            load(listToConvert{i}); 

            % Create mini struct that contains all info used by my scripts (temporarily
            % called margoData)
            margoData = struct;
            [margoData.Centroid, margoData.Speed, margoData.parameters, margoData.meta] = deal(struct);

            % Store tracking data in same format as OG autotracker
            margoData.Centroid.data = expmt.data.centroid.raw();

            % Calculate and store speed data
            speed = squeeze(diff(margoData.Centroid.data(:,1,:)).^2) + squeeze(diff(margoData.Centroid.data(:,2,:)).^2);
            speed = sqrt(speed);
            speed(isnan(speed)) = 0;

            margoData.Speed.data = vertcat(zeros(1,size(margoData.Centroid.data,3)),speed);

            % Store meta data and experiment parameters
            margoData.meta = expmt.meta;
            margoData.parameters = expmt.parameters;
            margoData.parameters.light = expmt.hardware.light;

            % Store a few parameters in particular fashion compatible with script
            margoData.fLabel = expmt.meta.date;
            margoData.ROI.bounds = expmt.meta.roi.bounds;
            margoData.nTracks = expmt.meta.num_traces;
            try
                margoData.Time.data = expmt.data.time.raw();
            catch
            end
            %margoData.Speed.data = margoData.Speed.data./expmt.data.time.raw();

            %%
            % Rename margoData expmt
            expmt = margoData;

            if expmt.parameters.target_rate > 3
                expmt = downsampleExp(expmt,3);
            end

            % Save expmt in file with suffix _margoConvert for analysis
            filePre = split(listToConvert{i},'.mat');
            filePre = filePre{1};
            outfile = strcat(filePre,'_margoConvert.mat');
            try
                save(outfile,'expmt','-mat','-v7.3');
            catch
                expFile = split(filePre,'\');
                expFile = expFile(length(expFile));
                expDir = getParentDir(filePre);
                fileSplit = split(expFile,'__');
                outfile = strcat(expDir,fileSplit{1},'_margoConvert.mat');
                save(outfile,'expmt','-mat','-v7.3');
            end
            convertedFiles{i} = outfile;
        end
    end
end
