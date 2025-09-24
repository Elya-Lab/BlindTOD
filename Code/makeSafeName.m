%% Takes in list/array of strings, checks for illegal characters for Windows filenames and replaces with underscore

function inList = makeSafeName(inList)
    
    badChar = {'<','>',':','"','/','\','|','?','*','.','[',']',' ',};
    for i=1:length(inList)
        if contains(inList(i),badChar)
            for j=1:length(badChar)
                if contains(inList(i),badChar{j})
                    inList(i) = strrep(inList(i),badChar{j},'_');
                end
            end
        end
    end

end