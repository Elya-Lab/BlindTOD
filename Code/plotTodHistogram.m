function plotTodHistogram(data,phaseShift)

    numCad = length(data.ZTlastMvmnts);
    if numCad >1
        hFig = figure;
        hold on;
        
        plotTimes = mod(data.ZTlastMvmnts,24);
        
        areaDay = 0+phaseShift:12+phaseShift;
        areaNight = 12+phaseShift:24+phaseShift;
        if max(areaNight) > 24
            areaNight1 = 0:phaseShift;
            areaNight2 = 12+phaseShift:24;
            area(areaNight1,ones(1,length(areaNight1)),'FaceColor','k','FaceAlpha',0.3,'HandleVisibility','off');
            area(areaNight2,ones(1,length(areaNight2)),'FaceColor','k','FaceAlpha',0.3,'HandleVisibility','off');
        else
            area(areaNight,ones(1,length(areaNight)),'FaceColor','k','FaceAlpha',0.3,'HandleVisibility','off');   
        end
        area(areaDay,ones(1,length(areaDay)),'FaceColor','y','FaceAlpha',0.3,'HandleVisibility','off');
        
        
        h = histogram(plotTimes,48,'Normalization','pdf','BinLimits',[0 24]);
        
        title(['Times of last movements',data.graphTitle],'FontSize',data.graph.titleFont,'Interpreter', 'none');
        xlabel('Time (ZT hours)','FontSize',data.graph.labelFont);
        ylabel('Probability','FontSize',data.graph.labelFont);
        set(gca,'FontSize',data.graph.labelFont,'TickLength',[0 0]);
        
        xlim([0 24]);
        ylim([0 0.5]);
        
        set(gcf,'PaperUnits','inches','PaperPosition',[0 0 10 8]);
        legend(strcat("N = ", num2str(numCad)),'Interpreter', 'none');

    end
end