function plot_aperture_trajectory_acrossExperiments(exptSummary)
%
% exptSummary - types
%   1 - chr2 during
%   2 - chr2 between
%   3 - arch
%   4 - eyfp

exptTypeIdx = [1,2,3,4];
aperture_lim = [5 20];
zlimit = [-10 15];

occludeRatio = 0.25;

saveDir = '/Users/dleventh/Box/Leventhal Lab/Meetings, Presentations/SfN/SFN 2019/Bova/figures';
saveName = 'aperture_trajectories_across_expt.pdf';
saveName = fullfile(saveDir,saveName);

figProps.m = 1;
figProps.n = 4;

figProps.topMargin = 0.5;
figProps.leftMargin = 2.5;

figProps.width = 39.01;
figProps.height = 10;

figProps.colSpacing = ones(figProps.n-1,1) * 0.5;
figProps.rowSpacing = 0.5;%ones(figProps.m-1,1) * 1;

figProps.panelWidth = ones(1,figProps.n)*((figProps.width - sum(figProps.colSpacing) - figProps.leftMargin - 0.5) / figProps.n);
figProps.panelHeight = 7;%ones(figProps.m,1) * 4;

[h_fig,h_axes] = createFigPanels5(figProps);

retrainSessions = 1 : 2;
laserOnSessions = 3 : 12;
occludeSessions = 13 : 22;

retrainColor = 'k';

n = zeros(length(exptSummary),1);

for i_exptType = 1 : length(exptTypeIdx)
    
    curSummary = exptSummary(exptTypeIdx(i_exptType));
    
    axes(h_axes(i_exptType));
    switch i_exptType
        case 1
            laserOnColor = 'b';
            occludeColor = [0 0 1] * occludeRatio;
        case 2
            laserOnColor = 'c';
            occludeColor = [0 0 1] * occludeRatio;
        case 3
            laserOnColor = 'g';
            occludeColor = [0 1 0.0] * occludeRatio;
        case 4
            laserOnColor = 'r';
            occludeColor = [1 0.0 0.0] * occludeRatio;
    end
    
    % mean aperture trajectory
    aperture_data = squeeze(nanmean(curSummary.mean_aperture_traj,1));
    z = curSummary.z_interp_digits;
    for i_retrainSession = 1 : length(retrainSessions)
        plot(z,aperture_data(retrainSessions(i_retrainSession),:),'color',retrainColor);
        hold on
    end
    for i_laserOnSession = 1 : length(laserOnSessions)
        plot(z,aperture_data(laserOnSessions(i_laserOnSession),:),'color',laserOnColor);
        hold on
    end
    for i_occludeSession = 1 : length(occludeSessions)
        plot(z,aperture_data(occludeSessions(i_occludeSession),:),'color',occludeColor);
        hold on
    end
    set(gca,'ylim',aperture_lim,'ytick',[10 20],'xdir','reverse',...
        'xlim',zlimit,'fontname','arial','fontsize',16,...
        'xtick',[-10 0 10],'xticklabel',[-10 0 10]);
    line([0,0],[aperture_lim(1) aperture_lim(2)],'color','k');
    
%     h_leg = legend([h_retrain,h_on,h_occlude],'baseline','laser on','occlude');
%     h_leg.Location = 'southeast';
    
    if i_exptType == 1
        ylabel('aperture (mm)','fontname','arial','fontsize',18)
%         set(gca,'yticklabel',[10 20]);
    else
        set(gca,'yticklabel',[]);
    end
    xlabel('z (mm)','fontname','arial','fontsize',18)
end

n

print(h_fig,saveName,'-dpdf');