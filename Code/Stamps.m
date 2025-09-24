function [timeStamp, dateStamp] = Stamps

    time = clock;
    timeStamp = [num2str(time(4)),'_',num2str(time(5)),'_',num2str(round(time(6)))];
    dateStamp = [num2str(time(1)),'-',num2str(time(2)),'-',num2str(time(3))];

end
