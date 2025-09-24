% Normalize yposition to min and max values
% Input = a, vector of heights
% modified 2019-07-22 to try and prevent erroneous min and max values (i.e.
% min/max values that only occur once in data set) from establishing
% normalization bounds

function a = scaleHt(a)
    [b,c] = histcounts(a,100);
    % will only look for histo bins that are 0 and ignore, should help get
    % rid of aberrantly low y positions (when ROIs are specified and go
    % into food, expect to see some blips below where fly can actually
    % access, but shouldn't expect blips above tunnel, where black acrylic
    % is)
    badInd= find(~b);
    
    % set default values to be overwritten
    maxVal = max(a);
    minVal = min(a);
    
    % check if there are any empty bins in histogram (any 1/100ths of
    % chamber not occupied indicates erroneous occupation)
    if ~isempty(badInd)
        % arbitrarily assume that if there are blips artificially elongating ROI, they won't take up more than first 10 bins
        lowestBad = badInd(find(badInd < 10,1,'last')); 
        % arbitrarily assume that if there are blips artificially elongating ROI, they won't take up more than last 10 bins
        highestBad = badInd(find(badInd > 90,1,'first'));        
        if ~isempty(lowestBad)
            minVal = c(lowestBad+1);
        end
        if ~isempty(highestBad)
            maxVal = c(highestBad-1);
        end
    end
    
    a = 1+(-1*(a-minVal)./(maxVal-minVal));
end
