% 2025-09-02
% Takes in cell array of file paths pointing to scrambled .mat files
% (randCadFiles) comprised entirrely of cadaver ROIs
function manuallyCallTod(randCadFiles, localTime, totalCads, callEveryROI)

    [plotcolor, lightcolor] = colorROIs('Cadaver',0.5); % establish plot color for all ROIs
    cadCt = 1;

    for i = 1:numel(randCadFiles)
        % Load randData struct
        load(randCadFiles{i});

        % Plotting options, pulled from summitParams
        % xInc choice depends on length of experiment in hours
        [noMvmtXMax, xInc, smoothWin] = summitParams(length(randData.ypos)/(3600*3));

        % Determine number of ROIs in file
        numROIs = length(randData.survival);

        % Pull out all survival data so we can add column header for column N, Blind_TOD
        timeArrays = localTime(1,:);
        sFiles     = localTime(2,:);

        % Write header once per survival file (OS-agnostic)
        for j = 1:length(sFiles)
            writecell({'Blind_TOD'}, sFiles{j}, 'Sheet', 1, 'Range', 'N1');
        end

        % Plot individual ROI data
        for roi = 1:numROIs
            if mod(cadCt, ceil(totalCads/10)) == 0
                disp(strcat("ROI ", num2str(cadCt), " of ", num2str(totalCads), ": ", num2str(round((100*cadCt)/totalCads)), "% done."));
            end

            smoothedSpeed = smoothdata(randData.speed(:,roi),'movmean',smoothWin);
            scaledHt      = scaleHt(randData.ypos(:,roi));

            % Pull out local time array (localT) and original survival file path for given ROI
            fileNum    = strcmp(randData.survival{roi}, string(localTime(2,:)));
            ogSurvival = sFiles{fileNum};

            surTable = readtable(ogSurvival);
            ogROI    = randData.ogROI(roi);

            % if isnan or forcing all ROIs
            if isnan(surTable{ogROI,'Blind_TOD'}) || callEveryROI

                localT   = cell2mat(timeArrays(fileNum));
                todYVals = [1, max(smoothedSpeed), noMvmtXMax];

                fig = figure();
                set(fig,'defaultAxesColorOrder',[0 0 0;0 0 0]);
                set(gcf, 'Position',  [0, 50, 1900, 950])

                p1 = subplot(3,1,1); hold on;
                title(strcat('Select time of death for ROI: File ',num2str(i),'/',num2str(numel(randCadFiles)),' , ROI #',num2str(roi),'/',num2str(numROIs)));
                plot(p1, scaledHt, 'Color', lightcolor);
                ylabel(p1,'Y position'); ylim(p1,[0 1]);
                adjustROIPlot(p1, 0, 0, todYVals(1), xInc, localT);

                p2 = subplot(3,1,2); hold on;
                plot(randData.speed(:,roi), 'Color', lightcolor);
                plot(smoothedSpeed, 'Color', plotcolor)
                ylabel('Speed'); ylim([0 50]);
                yyaxis right
                plot(cumsum(randData.speed(:,roi)));
                ylabel('Cumulative frames moved');
                try
                    ylim([0 nansum(randData.speed(:,roi))])
                catch
                    % REPLACED: mark bad trace in column Q
                    writecell({'Bad trace'}, ogSurvival, 'Sheet', 1, ...
                              'Range', sprintf('Q%d', ogROI+1));
                    disp('Speed is 0');
                end
                yyaxis left;
                adjustROIPlot(p2, 0, 0, todYVals(2), xInc, localT);

                p3 = subplot(3,1,3); hold on;
                framesNoMvmt = zeros(size(scaledHt));
                count = 0;
                for idx = 1:numel(scaledHt)
                    if isnan(scaledHt(idx)), count = count + 1; else, count = 0; end
                    framesNoMvmt(idx) = count;
                end
                plot(p3, framesNoMvmt);
                ylabel(p3,'Last mvmt (minutes ago)');
                ylim(p3,[0 3*3600+1]);
                set(gca,'ytick',1:10*3*60:length(scaledHt));
                set(gca,'yticklabel',0:10:length(scaledHt)/(60*3));
                adjustROIPlot(p3, 0, 0, todYVals(3), xInc, localT);

                subplots = [p1,p2,p3];
                linkaxes(subplots,'x')

                todAnswer = 0;
                timeOfDeath = 0;
                while ~todAnswer
                    if timeOfDeath == 0
                        todAnswer = 'No';
                    else
                        if length(scaledHt)/(3*3600) > 24
                            for sp = 1:3
                                xlim(subplots(sp), [timeOfDeath-(3600*3*20) timeOfDeath+(3600*3*4)]);
                            end
                        end
                        todAnswer = questdlg(['Accept ',num2str(timeOfDeath),' as time of last mvmt (proxy for time of death)?'], ...
                                             'Determine time of death', ...
                                             'Yes','No','Bad Trace','Yes');
                    end
                    switch todAnswer
                        case 'Yes'
                            % REPLACED: write numeric TOD into column N
                            ogROI = randData.ogROI(roi);
                            writematrix(timeOfDeath, ogSurvival, 'Sheet', 1, ...
                                        'Range', sprintf('N%d', ogROI+1));
                        case 'No'
                            todAnswer = 0;
                            pause;
                            timeOfDeath = ginput(1);
                            timeOfDeath = round(timeOfDeath(1));
                            for sp = 1:3
                                scatter(subplots(sp), timeOfDeath, todYVals(sp), 'g*');
                            end
                        case 'Bad Trace'
                            % REPLACED: mark bad trace in column Q
                            writecell({'Bad trace'}, ogSurvival, 'Sheet', 1, ...
                                      'Range', sprintf('Q%d', ogROI+1));
                        case 'Cancel'
                            break;
                    end
                end

                if timeOfDeath > 0
                    for sp = 1:3
                        scatter(subplots(sp), timeOfDeath, todYVals(sp), 'c*');
                    end
                    text(p1, double(timeOfDeath), 1, num2str(timeOfDeath));
                end
                close;
            end
            cadCt = cadCt + 1;
        end
    end
end