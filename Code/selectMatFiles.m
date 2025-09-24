% 2025-09-02
% OS-agnostic file picker for .mat experiment files
function files = selectMatFiles(lastDir)
    if nargin < 1 || isempty(lastDir), lastDir = pwd; end

    pickFiles = true;
    files = {};
    j = 1;

    while pickFiles
        % Start in lastDir, show only .mat files
        [expFile, expDir] = uigetfile(fullfile(lastDir, '*.mat'), ...
            'Select an expmt .mat file containing centroid traces');

        if isequal(expFile, 0)  % user cancelled
            break;
        end

        % Absolute, OS-correct path
        expPath = fullfile(expDir, expFile);
        % Canonicalize (resolves separators, .., etc.)
        expPath = char(java.io.File(expPath).getPath());

        files{j,1} = expPath; %#ok<AGROW>
        disp(expFile);

        choice = questdlg('Would you like to add another file?', ...
            'Add another file?', 'Yes','No','Yes');

        if strcmp(choice, 'Yes')
            pickFiles = true;
            % Stay in the same directory for the next pick
            lastDir = expDir;
            j = j + 1;
        else
            pickFiles = false;
        end
    end
end