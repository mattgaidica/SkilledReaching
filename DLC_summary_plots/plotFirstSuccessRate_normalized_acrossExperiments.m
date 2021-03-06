function plotFirstSuccessRate_normalized_acrossExperiments(exptSummary)
%
% exptSummary - types
%   1 - chr2 during
%   2 - chr2 between
%   3 - arch
%   4 - eyfp

saveDir = '/Users/dleventh/Box/Leventhal Lab/Meetings, Presentations/SfN/SFN 2019/Bova/figures';
saveName = 'first_success_summary.pdf';
saveName = fullfile(saveDir,saveName);

figProps.m = 1;
figProps.n = 4;

figProps.topMargin = 0.5;
figProps.leftMargin = 2.5;

figProps.width = 39.01;
figProps.height = 12;

figProps.colSpacing = ones(figProps.n-1,1) * 0.5;
figProps.rowSpacing = 0.5;%ones(figProps.m-1,1) * 1;

figProps.panelWidth = ones(1,figProps.n)*((figProps.width - sum(figProps.colSpacing) - figProps.leftMargin - 0.5) / figProps.n);
figProps.panelHeight = 9;%ones(figProps.m,1) * 4;

[h_fig,h_axes] = createFigPanels5(figProps);

minSuccess = 0;
maxSuccess = 1.5;

patchAlpha = 0.01;

retrainSessions = 1 : 2;
laserOnSessions = 3 : 12;
occludeSessions = 13 : 22;

summaries_to_plot = [1,2,3,4];
retrainColor = 'k';

patchX = [2.5 2.5 12.5 12.5];

n = zeros(length(exptSummary),1);

for i_exptType = 1 : length(summaries_to_plot)
    
    curSummary = exptSummary(summaries_to_plot(i_exptType));
    n(i_exptType) = size(curSummary.firstReachSuccess,2);
    numSessions = size(curSummary.firstReachSuccess,1);
    
    axes(h_axes(i_exptType));
    
    baseline_success = nanmean(curSummary.firstReachSuccess(retrainSessions,:),1);
    norm_success = curSummary.firstReachSuccess ./ repmat(baseline_success,numSessions,1);
    toPlot = nanmean(norm_success,2);
    
    switch i_exptType
        case 1
            laserOnColor = 'b';
        case 2
            laserOnColor = 'c';
        case 3
            laserOnColor = 'g';
        case 4
            laserOnColor = 'r';
    end
    
    numValidPts = sum(~isnan(curSummary.num_trials),2);
    e_bars = nanstd(norm_success,0,2) ./ sqrt(numValidPts);
    
    set(gca,'ylim',[minSuccess maxSuccess],...
        'xtick',[1,2,3,12,13,22],...
        'xticklabel',[1,2,1,10,1,10],...
        'fontsize',16,...
        'fontname','arial');
    
    ylimits = get(gca,'ylim');
    patchY = [ylimits(1) ylimits(2) ylimits(2) ylimits(1)];
    patch(patchX,patchY,laserOnColor,'facealpha',patchAlpha);
    
    hold on
    h_retrain = scatter(retrainSessions,toPlot(retrainSessions),'markeredgecolor',retrainColor);
    h_on = scatter(laserOnSessions,toPlot(laserOnSessions),'markeredgecolor',laserOnColor);
    h_occlude = scatter(occludeSessions,toPlot(occludeSessions),'markeredgecolor',laserOnColor,'markerfacecolor',laserOnColor);
    
%     for ii = 1 : n(i_exptType)
%         plot(retrainSessions,curSummary.num_trials(retrainSessions,ii),'color',retrainColor);
%     end
    errorbar(retrainSessions,toPlot(retrainSessions),e_bars(retrainSessions),retrainColor,'linestyle','none');
    errorbar(laserOnSessions,toPlot(laserOnSessions),e_bars(laserOnSessions),laserOnColor,'linestyle','none');
    errorbar(occludeSessions,toPlot(occludeSessions),e_bars(occludeSessions),laserOnColor,'linestyle','none');
    
    line([0,22],[1,1],'color','k')
    
%     h_leg = legend([h_retrain,h_on,h_occlude],'baseline','laser on','occlude');
%     h_leg.Location = 'southeast';
    
    if i_exptType == 1
        ylabel('normalized 1st success rate','fontname','arial','fontsize',18)
        set(gca,'ytick',[0,1,maxSuccess],'yticklabel',[0,1,maxSuccess]);
    else
        set(gca,'yticklabel',[]);
    end
    xlabel('session number','fontname','arial','fontsize',18)
end

n

print(h_fig,saveName,'-dpdf');