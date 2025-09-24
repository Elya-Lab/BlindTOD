% 2020-05-06
% Function: determine status of an ROI (cadaver, alive, uninfected or NI)
%
% INPUT:
% survival = table containing survival information
% roi = roi #
%
% OUTPUT:
% roiStatus = ROI class (cadaver, alive, uninfected or NI)

function roiStatus = classifyROI(survival, roi)
    if survival{roi,'Status'} == 0
        if survival{roi,'Outcome'} == 1
            roiStatus='Cadaver'; % ROI is zombie %
        else
            roiStatus='NI'; % ROI is NI
        end     
    elseif strcmp(survival{roi,'Rx'},'Uninfected')
        roiStatus= 'Uninfected'; % Fly wasn't infected
    else
        roiStatus='Alive'; % ROI is survivor
    end
end