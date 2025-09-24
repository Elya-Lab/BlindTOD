function [convFiles, fileChoice] = askForNewFiles(convFiles)
    if ~isempty(convFiles)
        infoDlg = ["The following ", num2str(length(convFiles))," file(s) is (are) already loaded (first 10 shown): ",newline];  
        if length(convFiles)>10
            lastFile = 10;
        else
            lastFile = length(convFiles);
        end
        for n=(1:lastFile)
            splitfile = split(convFiles(n),'\');
            infoDlg = [infoDlg,string(splitfile(length(splitfile))),newline];
        end
        infoDlg = [infoDlg,"Would you like to select new files?'"];

        fileChoice = questdlg(infoDlg,...
                'Choose new files?',...
                'Yes','No','No');
    else
        fileChoice = 'Yes';
    end
end