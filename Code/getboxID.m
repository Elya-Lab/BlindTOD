function boxID = getboxID(expDir)
    
    expDir = char(expDir);
    % Get ID of box in which experiment was run
    boxID = strfind(expDir,'SUM');
    
    if strcmp(expDir(boxID+5),'.1')
        sumNameLen = 5;
    else
        sumNameLen = 3;
    end
    boxID = expDir(boxID:boxID+sumNameLen);

end
