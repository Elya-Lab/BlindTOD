% 2020-05-06
% Function: pick a plot color based on ROI status
%
% INPUT:
% roiStatus = character array, either Cadaver, Alive, Uninfected or NI
%
% OUTPUT:
% plotColor = color to use for individual ROI plot

function [plotColor, lightColor] = colorROIs(roiStatus, z)
    switch roiStatus
        case 'Cadaver'
            plotColor = 'r';
            lightColor = [1 z z];
        case 'NI'
            plotColor = 'k';
            lightColor = [z z z];
        case 'Uninfected'
            plotColor = 'g';
            lightColor = [z 1 z];
        case 'Alive'
            plotColor = 'b';
            lightColor = [z z 1];
    end
end