%% Converts time into Zeitgeiber time
function localTime = convertToLocalTime(expmt,startHour)

    localTime = zeros(1,size(expmt.Centroid.data,1));

    for frame =(1:size(expmt.Centroid.data,1))
    
        time = startHour + ((frame-1)/expmt.parameters.target_rate)/3600;
        %time = time-24;
        localTime(frame) = time;
    end

    disp(['Experiment end time (local time): ', num2str(localTime(size(expmt.Centroid.data,1)))]);
end
