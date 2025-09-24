function strArray = cell2str(files)
    strArray = repmat("",1,length(files));
    for i=1:length(files)
        strArray(i) = string(files{i});
    end
end