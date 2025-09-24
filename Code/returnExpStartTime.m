function startHour = returnExpStartTime(fileName)
    b = strsplit(fileName,'_');
    c = strsplit(b(1),'-');
    startClock = [str2double(c(4)),str2double(c(5)),str2double(c(6))];
    startHour = startClock(1) + (startClock(2)/60) + (startClock(3)/3600);
    %disp(['Experiment start time (local time): ', num2str(startHour)]);
end