function expFiles = autoDenoise(expFiles, speedCutoff, maxNoisyFrames)
    colors = defaultMatlabColors;

    for i = 1:numel(expFiles)
        load(expFiles{i});  % loads 'expmt'

        % Normalize noisy-frame threshold to experiment duration
        maxNoisyFramesNorm = ceil(expmt.parameters.duration/24) * maxNoisyFrames;

        % --- OS-agnostic path handling ---
        [expDir, expBase, ~] = fileparts(expFiles{i});   % expBase: filename without extension

        % Date string from filename (your existing util)
        expDate = returnExpDate(string(expBase));

        % Info
        disp(expBase);

        % --- survival Excel path (OS-agnostic) ---
        survivalFile = fullfile(expDir, sprintf('%s-survival_data.xlsx', expDate));

        % Load Excel
        survival = readtable(survivalFile);
        roiStats = strings(1, expmt.nTracks);

        % Header row in T/U (cross-platform writer)
        writecell({'AutoX_lower_bound','AutoX_upper_bound'}, survivalFile, ...
                  'Sheet', 1, 'Range', 'T1:U1');

        denoiseReq = 0;

        for roi = 1:expmt.nTracks
            roiStats(roi) = classifyROI(survival, roi);
            maxXWidth = 20;  % default limit based on movement

            % Initial bounds from current data
            lowBound = min(expmt.Centroid.data(:,2,roi));
            upBound  = max(expmt.Centroid.data(:,2,roi));

            if ~strcmp(roiStats(roi),'NI')
                % Too-fast detection
                tooFast    = expmt.Speed.data(:,roi) > speedCutoff;
                checkSpeed = cumsum(tooFast);

                if checkSpeed(end) > maxNoisyFramesNorm
                    denoiseReq = 1;

                    % Work copies
                    x = expmt.Centroid.data(:,1,roi);
                    y = expmt.Centroid.data(:,2,roi);

                    figure;

                    % Y trace
                    subplot(3,1,1);
                    hold on;
                    plot(scaleHt(y),'Color',colors(2,:));
                    title(sprintf('ROI: %d', roi));
                    xlabel('Frame'); ylabel('Y position');
                    xlim([0 length(y)]);

                    % X trace
                    subplot(3,1,2);
                    plot(x,'Color',colors(3,:));
                    xlabel('Frame'); ylabel('X position');
                    xlim([0 length(y)]);

                    % ROI geometry
                    leftEdge  = expmt.ROI.bounds(roi,1);
                    rightEdge = expmt.ROI.bounds(roi,1) + expmt.ROI.bounds(roi,3);
                    roiCenter = mean([leftEdge, rightEdge]); %#ok<NASGU>

                    % Center from motion; robust to a single noisy edge
                    xCenter = nanmean([max(x), min(x)]);
                    xWidth  = max(x) - min(x);
                    if xWidth < maxXWidth
                        maxXWidth = xWidth - 2;
                    end

                    while checkSpeed(end) > maxNoisyFramesNorm && maxXWidth > 9
                        lowBound = xCenter - 0.5*maxXWidth;
                        upBound  = xCenter + 0.5*maxXWidth;

                        inWin = (x > lowBound) & (x < upBound);
                        x(~inWin) = NaN;
                        y(~inWin) = NaN;

                        newSpeed = sqrt( squeeze(diff(x)).^2 + squeeze(diff(y)).^2 );
                        newSpeed(isnan(newSpeed)) = 0;

                        tooFast    = newSpeed > speedCutoff;
                        checkSpeed = cumsum(tooFast);
                        maxXWidth  = maxXWidth - 2;
                    end

                    % Overwrite corrected centroids
                    expmt.Centroid.data(:,1,roi) = x;
                    expmt.Centroid.data(:,2,roi) = y;

                    % Save de-noising bounds (xlsx; no Excel needed)
                    disp(sprintf('ROI #: %d  Low Bound: %g  Upper Bound: %g', roi, lowBound, upBound));
                    writematrix(lowBound, survivalFile, 'Sheet', 1, ...
                                'Range', sprintf('T%d', roi+1));
                    writematrix(upBound,  survivalFile, 'Sheet', 1, ...
                                'Range', sprintf('U%d', roi+1));

                    % Plot de-noised Y for comparison
                    subplot(3,1,3);
                    plot(scaleHt(expmt.Centroid.data(:,2,roi)),'Color',colors(1,:));
                    xlim([0 length(expmt.Centroid.data)]);
                    ylabel('Denoised: Y-position'); xlabel('Frame');

                    % Visualize window used
                    subplot(3,1,2);
                    rectangle('Position',[0, lowBound, length(expmt.Centroid.data), upBound-lowBound]);
                    ylim([lowBound-2, upBound+2]);
                    xlim([0 length(expmt.Centroid.data)]);
                    set(gcf,'PaperUnits','inches','PaperPosition',[0 0 10 8]);

                    % Portable output path for plot
                    outPng = fullfile(expDir, sprintf('ROI-%d-denoised', roi));
                    print(outPng, '-dpng');
                    close();
                end
            end
        end

        % Recompute speed for ALL corrected data
        speed = sqrt( squeeze(diff(expmt.Centroid.data(:,1,:))).^2 + ...
                      squeeze(diff(expmt.Centroid.data(:,2,:))).^2 );
        speed(isnan(speed)) = 0;
        expmt.Speed.data = vertcat(zeros(1, size(expmt.Centroid.data,3)), speed);

        % Save corrected expmt struct
        if denoiseReq
            % If already a denoise file, overwrite; else create *_autodenoise.mat
            if contains(expFiles{i}, 'denoise')
                save(expFiles{i}, 'expmt', '-mat', '-v7.3');
            else
                [fDir, fBase, ~] = fileparts(expFiles{i});
                outfile = fullfile(fDir, [fBase '_autodenoise.mat']);
                expFiles{i} = outfile;
                save(outfile, 'expmt', '-mat', '-v7.3');
            end
        end
    end
end