function newOut = getParentDir(outPath)
    if ~strcmp(outPath(length(outPath)),'\')
        subIdx = 1;
    else
        subIdx = 2;
    end
    splitOut = split(outPath,'\');
    newOut = strjoin(splitOut(1:length(splitOut)-subIdx),'\');
    newOut = strcat(newOut,'\');
end