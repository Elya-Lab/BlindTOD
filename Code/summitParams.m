% 2021-02-10
% Spot to hold summit parameters so that it is more consistent between
% files (can call this function instead of hard-coding every time).

function [noMvmtXMax, xInc, smoothWin] = summitParams(expDurinHours)
    noMvmtXMax = 3*3600 +1;     % set max value for X axis, third subplot (time since no movement)
    xInc = 0.5* round(expDurinHours/24); % amount to increment between x values for x axis, in hours            
    smoothWin = 10000; 
end