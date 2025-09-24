function adjustROIPlot(ax, timeOfDeath, autoTau, todYVal, xInc, localT)

    % Plot automatically determined tod in black and label auto tod with frame number on graph
    try
        scatter(ax, timeOfDeath,todYVal,'k*');
        text(ax, double(timeOfDeath),todYVal,num2str(timeOfDeath));
    catch   
    end

    try
        scatter(ax, autoTau,todYVal,'k*');
        text(ax, double(autoTau),todYVal,num2str(autoTau));
    catch   
    end

    xlabel(ax,'Local time');
    xtickangle(ax,90);
    set(ax,'xtick',1:3*3600*xInc:length(localT)); % Set ticks every hour starting from first frame
    set(ax,'xticklabel',round(localT(1),1):xInc:round(localT(length(localT)),1)); % Label ticks with "local time" hours
    xlim(ax,[1 length(localT)]);
 
end