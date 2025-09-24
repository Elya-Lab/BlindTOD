%% Plot data struct data according to local time, not time aligned on death
function plotLocalFun(data,phaseShift)   
    figure;
    
    % Dictate x range using first treatment that has data (alive, cadaver
    % or uninfected)
    if ~isempty(data.(data.rXes{1}).(data.feat{1}).allMatrix)
        expLen = length(data.(data.rXes{1}).(data.feat{1}).allMatrix);
    elseif ~isempty(data.(data.rXes{2}).(data.feat{1}).allMatrix)
        expLen = length(data.(data.rXes{2}).(data.feat{1}).allMatrix);
    else
        expLen = length(data.(data.rXes{3}).(data.feat{1}).allMatrix);
    end
    
    xspace = downsample(1:expLen,data.params.downSamp);

    % increment for x axis labels, in hours
    xInc = floor(data.params.alignLength/24);  
    
    % If xInc comes out to 0, set to 1
    if ~xInc
        xInc = 1;
    end
    colors = cneColors(0.8);
    key = cell(1,3);

    for g=(1:2) % features
        subplot(2,1,g);
        ylabel(data.feat{g});
        hold on;
        
        % Add in light for the day that tracking started, if needed  
        if data.startTime <= data.params.zt0-24+phaseShift +12
            areaSpan = 1 : 1*3600*3 : (data.params.zt0 - 24 + phaseShift +12 - data.startTime)*3600*3;
            areaDay = repmat(5,1,length(areaSpan));
            area(areaSpan,areaDay,'FaceColor','y','FaceAlpha',0.3,'EdgeColor','none','HandleVisibility','off');            
        end
        
        for j = 1:ceil(data.params.alignLength/24)
            areaSpan =(((j-1)*24) -data.startTime +data.params.zt0+phaseShift)*3600*3: 1*3600*3 :((j-1)*24 -data.startTime +data.params.zt0 + 12+phaseShift)*3600*3;               
            %areaSpan = areaSpan/data.params.downSamp;
            areaDay = repmat(5,1,length(areaSpan));
            area(areaSpan,areaDay,'FaceColor','y','FaceAlpha',0.3,'EdgeColor','none','HandleVisibility','off');
        end              
        for h=(1:3)
            if ~isempty(data.(data.rXes{h}).(data.feat{g}).allMatrix)
                yData = downsample(smoothdata(nanmean(transpose(data.(data.rXes{h}).(data.feat{g}).allMatrix)),'movmean',10000),data.params.downSamp);
                ySE = downsample(smoothdata(nanstd(transpose(data.(data.rXes{h}).(data.feat{g}).allMatrix))/sqrt(size(data.(data.rXes{h}).(data.feat{g}).allMatrix,2)),'movmean',10000),data.params.downSamp);
                yData = yData(~isnan(yData));
                ySE = ySE(~isnan(yData));
                % Hacky fix to cover case where ySE value is NaN but yData
                % is not, sets ySE to 0. Need to dig more into this if it
                % winds up setting substantial # of frames to 0.
                ySE(isnan(ySE))=0;
                areaBar(xspace(1:length(yData)),yData,ySE,colors{2*h},colors{2*h},'-',0.1);  
                if g == 1
                    key{h} = strcat((data.rXes{h}), ' (N=',string(size(data.(data.rXes{h}).ypos.toDmatrix,2)),')');
                end
            end
        end
        key = key(~cellfun('isempty',key)); % remove empty entries
        legend(key,'Location','best');
        set(gca,'xtick',1:3600*3*xInc:expLen);
        set(gca,'xticklabel',round(data.startTime,1):xInc:round(data.startTime,1)+expLen/(3600*3))
        xlim([1 expLen]);
        xlabel('Local time')
        xtickangle(90);
    end

    subplot(2,1,1)
    ylim([0 1]);

    subplot(2,1,2);
    ylim([0 4]);

    sgtitle(strcat(data.filePre));

    set(gcf,'PaperUnits','inches','PaperPosition',[0 0 10 8]);
    try
        disp(data.outDir)
        print(strcat(data.outDir,data.filePre,'_local time.png'),'-dpng'); 
    catch
        newOut = getParentDir(data.outDir);
        disp(newOut)
        print(strcat(newOut,data.filePre,'_local time.png'),'-dpng');
    end
    close;
end