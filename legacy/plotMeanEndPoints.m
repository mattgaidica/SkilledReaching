function h_figs = plotMeanEndPoints(mean_endPoints)

labelfontsize = 24;
ticklabelfontsize = 18;

patchAlpha = 0.1;

ylimits = [-13,7];
meanPts_acrossExps = zeros(22,3,3);
stdPts_acrossExps = zeros(22,3,3);
markerSize = 50;

xtickValues = [1,3,12,13,22];
markerType = {'o','s','*'};
patchX = [2.5 2.5 12.5 12.5];
patchY = [ylimits(1) ylimits(2) ylimits(2) ylimits(1)];
hold off
for ii = 1 : 3
    h_figs(ii) = figure(ii);
%     hold off

    cur_meanEndPt = nanmean(mean_endPoints{ii},3);
    cur_stdEndPt = nanstd(mean_endPoints{ii},1,3);
    meanPts_acrossExps(:,:,ii) = cur_meanEndPt;
    stdPts_acrossExps(:,:,ii) = cur_stdEndPt;

    scatter(1:2,squeeze(meanPts_acrossExps(1:2,3,ii)),markerSize,markerType{ii},'markeredgecolor','k','markerfacecolor','k')
    hold on
    scatter(3:12,squeeze(meanPts_acrossExps(3:12,3,ii)),markerSize,markerType{ii},'markeredgecolor','b','markerfacecolor','b')
    scatter(13:22,squeeze(meanPts_acrossExps(13:22,3,ii)),markerSize,markerType{ii},'markeredgecolor','r','markerfacecolor','r')
    
    errorbar(1:2,squeeze(meanPts_acrossExps(1:2,3,ii)),squeeze(stdPts_acrossExps(1:2,3,ii)),'color','k','linestyle','none')
    errorbar(3:12,squeeze(meanPts_acrossExps(3:12,3,ii)),squeeze(stdPts_acrossExps(3:12,3,ii)),'color','k','linestyle','none')
    errorbar(13:22,squeeze(meanPts_acrossExps(13:22,3,ii)),squeeze(stdPts_acrossExps(13:22,3,ii)),'color','k','linestyle','none')
    xticks(xtickValues);
    xticklabels([1,1,10,1,10])

    set(gca,'ylim',ylimits,'fontsize',ticklabelfontsize);
    ylabel('reach extent (mm)','fontsize',labelfontsize)
    xlabel('session number','fontsize',labelfontsize)
    
    line([0,22],[0,0],'color','k')
    
    patch(patchX,patchY,'b','facealpha',patchAlpha);
end

end


