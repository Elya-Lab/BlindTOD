% 2025-09-02
% Plot ROIs to check for tracking bias across board

% INPUT: 
% expDir = path to experiment file (used to title plot and direct where to save output)
% survival = spreadsheet with surival information for given experiment
% expmt = struct with experiment data (generated from convertMargoDataFun
% from input Margo file)

% OUTPUT:
% ~ no variables ~
% saves plot of all xy positions of all flies for a given experiment,
% colored by survival outcome

function plotAllROIs(expPath,survival,expmt)
    figure;
    hold on;
    
    for roi=1:expmt.nTracks
        if survival{roi,'Status'} == 0
            if survival{roi,'Outcome'} == 1
                % % ROI is zombie % %
                plotcolor = 'r';
            else
                % % ROI is NI % %
                plotcolor = 'k';
            end     
        elseif strcmp(survival{roi,'Rx'},'Uninfected')
            plotcolor = 'g';
        else
            % % ROI is survivor % %
            plotcolor = 'b';
        end
        plot(expmt.Centroid.data(:,1,roi),-1*expmt.Centroid.data(:,2,roi),'Color',plotcolor);
        text(expmt.meta.roi.bounds(roi,1),-1*expmt.meta.roi.bounds(roi,2),num2str(roi),'FontSize',8,'Color',plotcolor)
    end
    % --- Replace everything from pullFileInfo down ---
    [startList, dateList, survivalList, boxList] = pullFileInfo({expPath}); %#ok<ASGLU>

    % title wants strings; pull first element
    title(strcat(boxList(1), " - ", dateList(1)));

    set(gcf,'PaperUnits','inches','PaperPosition',[0 0 10 8]);

    % OS-agnostic directory and output path
    [expDir, ~, ~] = fileparts(expPath);           % parent folder
    outPng = fullfile(expDir, 'All tracking.png'); % explicit filename

    % ensure directory exists (defensive)
    if ~exist(expDir, 'dir'); mkdir(expDir); end

    print(outPng, '-dpng');
    close;
end