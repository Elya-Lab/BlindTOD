function expmt = downsampleExp(expmt,desiredFr)

%     defaultDir = "D:\Harvard\Summit behavior - rig and tracking\Behavior data\";
%     [expFile,expDir] = uigetfile(strcat(defaultDir,'*.mat'),'Select a expmt .mat file containing centroid traces');
%     dataFile = [expDir,expFile];
%     load(dataFile);
    
    multiplier = 1000;

    % % Figure out how much to resample by
    
    % Determine desired number of frames
    corrFrames = expmt.parameters.duration*desiredFr*3600;
    
    % Determine number of frames on hadn
    actFrames = length(expmt.Centroid.data);
    
    resampP = double(round(corrFrames/actFrames*multiplier));
    
    % Initialize arrays to hold downsampled centroid and speed
    centroid = nan(ceil((resampP/multiplier)*actFrames),2,expmt.nTracks);

    % Then resample each ROI
    for c=(1:expmt.nTracks)
        for i=1:2
            centroid(:,i,c) = resample(double(expmt.Centroid.data(:,i,c)),resampP,multiplier);
        end
    end
   
    expmt.Centroid.data = single(centroid);
    
    % Calculate speed from new centroid data (otherwise speed will be too
    % low since it's in units of pixels/frame and frame rate was previously
    % higher
    speed = squeeze(diff(expmt.Centroid.data(:,1,:)).^2) + squeeze(diff(expmt.Centroid.data(:,2,:)).^2);
    speed = sqrt(speed);
    speed(isnan(speed)) = 0;
    expmt.Speed.data = vertcat(zeros(1,size(expmt.Centroid.data,3)),speed);

    % Update relevant parameters
    expmt.parameters.target_rate = desiredFr;
    expmt.meta.num_frames = length(centroid);
    
end