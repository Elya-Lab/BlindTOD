% Normalize yposition to min and max values
% Input = a, vector of heights
% takes in info about neighboring ROIs (not just individual ROI) to see
% max bound for fly (use for tall wells experiments when flies don't
% necessarily sample the entire space available).

function a = scaleKnownBoundary(a,minY,maxY)
    if abs(min(a)-minY) > 10
       minVal = minY;
    else
       minVal = min(a);
    end
    if abs(max(a)-maxY) > 10
       maxVal = maxY;
    else
       maxVal = max(a);
    end
       
    a = 1+(-1*(a-minVal)./(maxVal-minVal));
end