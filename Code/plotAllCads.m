%% Plot each cadaver from a given data struct overlaid on single plot with mean
% Purpose is to see all individuals at a glance
function plotAllCads(data)
    figure;
    hues = distinguishable_colors(10);
    try 
        data.graph;
    catch
        % graphing options
        data.graph = {};
        data.graph.xInt = 1;                        % interval between x ticks in hours
        data.graph.legFont = 14;                    % size of legend font, delta AUC shown on graph
        data.graph.tickFont = 14;
        data.graph.labelFont = 18;
    end
    
    for d=1:2
        subplot(2,1,d);
        hold on;
        currHue = 1;

        %allCads = plot(data.xspace,downsample(smoothdata(data.Cadavers.(data.feat{d}).toDmatrix(1:data.params.lastFrames,:),'movmean',data.params.avgWin),data.params.downSamp),'w-');
%         for c = 1:length(allCads)
       for c=1:size(data.Cadavers.(data.feat{d}).toDmatrix,2)
            % change plot colors so each trace is distinguishable
            cads = plot(data.xspace,...
                downsample(smoothdata(data.Cadavers.(data.feat{d}).toDmatrix(1:data.params.lastFrames,c),'movmean',data.params.avgWin),data.params.downSamp),'k-');
%             allCads(c).Color(1:3) = hues(currHue,:);
%             allCads(c).Color(4) = 0.5;
            cads.Color(1:3) = hues(currHue,:);
            % Set alpha to non 0 value to get overlapping plots
            cads.Color(4) = 0.5;
            currHue = currHue + 1;
            if currHue > length(hues)
                currHue = 1;
            end
        end

        plot(data.xspace,data.Cadavers.(data.feat{d}).avg,'r-','LineWidth',2);
        xlabel('Hour prior to death','fontsize',data.graph.labelFont);
        set(gca,'xtick',1:3600*data.params.fr * data.graph.xInt : data.params.lastFrames)
        set(gca,'xticklabel',data.params.hoursBeforeDeath:-1 * data.graph.xInt : 1,'fontsize',data.graph.tickFont)
        xlim([1 data.params.lastFrames]);  
    end

    subplot(2,1,1)
    title('All individuals with mean in bold');
    ylabel('Y position','fontsize',data.graph.labelFont);
    ylim([0 1]);
    lgd = legend(strcat('Cadavers (N=',string(size(data.Cadavers.ypos.toDmatrix,2)),')'),'Location','best');
    legend boxoff
    lgd.FontSize = data.graph.legFont;

    subplot(2,1,2)
    ylabel('Speed','fontsize',data.graph.labelFont);
    ylim([0 1.5]);

    s = suptitle(data.graphTitle);
    s.HorizontalAlignment='center';

    set(gcf,'PaperUnits','inches','PaperPosition',[0 0 10 8]);
    try
        print(strcat(data.outDir,data.filePre,'_allCadavers.png'),'-dpng');
        disp(data.outDir);
    catch
        newOut = getParentDir(data.outDir);
        disp(newOut);
        print(strcat(newOut,data.filePre,'_allCadavers.png'),'-dpng');
    end
    
    close;
end