function [ratSummary_h_fig, ratSummary_h_axes,ratSummary_h_figAxis] = plotRatSummaryFigs(ratID,sessionDates,allSessionDates,sessionType,bodyparts,bodypart_to_plot,...
    mean_pd_trajectories,mean_xyz_from_pd_trajectories,reachEndPoints,mean_euc_dist_from_pd_trajectories,distFromPellet,digit_endAngle)

x_lim = [-30 10];
y_lim = [-15 10];
z_lim = [-5 50];

bodypart_idx_toPlot = find(findStringMatchinCellArray(bodyparts, bodypart_to_plot));

ratSummary_figProps.m = 5;
ratSummary_figProps.n = 5;

ratSummary_figProps.panelWidth = ones(ratSummary_figProps.n,1) * 10;
ratSummary_figProps.panelHeight = ones(ratSummary_figProps.m,1) * 4;

ratSummary_figProps.colSpacing = ones(ratSummary_figProps.n-1,1) * 0.5;
ratSummary_figProps.rowSpacing = ones(ratSummary_figProps.m-1,1) * 1;

ratSummary_figProps.topMargin = 5;
ratSummary_figProps.leftMargin = 2.54;

ratSummary_figProps.width = sum(ratSummary_figProps.panelWidth) + ...
    sum(ratSummary_figProps.colSpacing) + ...
    ratSummary_figProps.leftMargin + 2.54;
ratSummary_figProps.height = sum(ratSummary_figProps.panelHeight) + ...
    sum(ratSummary_figProps.rowSpacing) + ...
    ratSummary_figProps.topMargin + 2.54;

[ratSummary_h_fig,ratSummary_h_axes] = createFigPanels5(ratSummary_figProps);
ratSummary_h_figAxis = createFigAxes(ratSummary_h_fig);

numSessions = length(sessionDates);

for iSession = 1 : numSessions

    allSessionIdx = find(sessionDates{iSession} == allSessionDates);
    curSessionType = sessionType(allSessionIdx).type;
    sessionsLeftInBlock = sessionType(allSessionIdx).sessionsLeftInBlock;
    
    switch curSessionType
        case 'training'
            plotRow = 1;
            plot_colmap = colormap(gray);
%                 plotColor = [0,0,0];
        case 'laser_during'
            plotRow = 2;
            plot_colmap = colormap(winter);
%                 plotColor = [0,0,1];
        case 'laser_between'
            plotRow = 2;
            plot_colmap = colormap(winter);
%                 plotColor = [0,0,1];
        case 'occlusion'
            plotRow = 3;
            plot_colmap = colormap(autumn);
%                 plotColor = [1,0,0];
    end

    plotColor = plot_colmap(sessionsLeftInBlock*3+1,:);
    for iDim = 1 : 3
        axes(ratSummary_h_axes(1,iDim))
        % plot mean for all trajectories
        toPlot = squeeze(mean_pd_trajectories(:,iDim,1,iSession));
        plot(toPlot,'color',plotColor);
        hold on

        switch iDim
            case 1
                title('mean trajectory, x')
                set(gca,'ylim',x_lim)
            case 2
                title('mean trajectory, y')
                set(gca,'ylim',y_lim,'ydir','reverse')
            case 3
                title('mean trajectory, z')
                set(gca,'ylim',z_lim)
        end
        
        axes(ratSummary_h_axes(2,iDim))
        toPlot = squeeze(mean_xyz_from_pd_trajectories(:,iDim,1,iSession));
        plot(toPlot,'color',plotColor);
        hold on
    end
    axes(ratSummary_h_axes(1,4))
    toPlot = squeeze(mean_pd_trajectories(:,:,1,iSession));
    plot3(toPlot(:,1),toPlot(:,3),toPlot(:,2),'color',plotColor);
    hold on

    axes(ratSummary_h_axes(2,4))
    toPlot = squeeze(mean_euc_dist_from_pd_trajectories(:,1,iSession));
    plot(toPlot(:,1),'color',plotColor);
    hold on
end
% axes(ratSummary_h_axes(4,4))
% scatter3(0,0,0,25,'k','o','markerfacecolor','k')
% set(gca,'zdir','reverse','xlim',x_lim,'ylim',z_lim,'zlim',y_lim,...
%     'view',[-70,30])
% xlabel('x');ylabel('z');zlabel('y');

for iSession = 1 : numSessions

    allSessionIdx = find(sessionDates{iSession} == allSessionDates);
    curSessionType = sessionType(allSessionIdx).type;
    sessionsLeftInBlock = sessionType(allSessionIdx).sessionsLeftInBlock;
    switch curSessionType
        case 'training'
            plotRow = 1;
            plot_colmap = colormap(gray);
    %                 plotColor = [0,0,0];
        case 'laser_during'
            plotRow = 2;
            plot_colmap = colormap(winter);
    %                 plotColor = [0,0,1];
        case 'laser_between'
            plotRow = 2;
            plot_colmap = colormap(winter);
    %                 plotColor = [0,0,1];
        case 'occlusion'
            plotRow = 3;
            plot_colmap = colormap(autumn);
    %                 plotColor = [1,0,0];
    end
    plotColor = plot_colmap(sessionsLeftInBlock*3+1,:);
    for iDim = 1 : 3
        axes(ratSummary_h_axes(4,iDim))
        % find reach end points for the bodypart of interest for all
        % trials
        dim_endPoints = squeeze(reachEndPoints{iSession}{1}(bodypart_idx_toPlot,iDim,:));
        toPlot = nanmean(dim_endPoints);
        scatter(iSession,toPlot,'markeredgecolor',plotColor,'markerfacecolor',plotColor);
        hold on
        
        % plot variability in reach endpoint along each dimension
        axes(ratSummary_h_axes(5,iDim))
        toPlot = nanvar(dim_endPoints);
        scatter(iSession,toPlot,'markeredgecolor',plotColor,'markerfacecolor',plotColor);
        hold on
        
    end
    axes(ratSummary_h_axes(4,4))
    session_distFromPellet = squeeze(distFromPellet{iSession}{1}(bodypart_idx_toPlot,:));
    toPlot = nanmean(session_distFromPellet);
    scatter(iSession,toPlot,'markeredgecolor',plotColor,'markerfacecolor',plotColor);
    hold on

    axes(ratSummary_h_axes(4,5))
    MRL = circ_r(digit_endAngle{iSession});
    mean_endAngle = circ_mean(digit_endAngle{iSession});
    try
    toPlot = MRL * exp(1i*mean_endAngle);
    catch
        keyboard
    end
    h_line = compass(toPlot);
    h_line.Color = plotColor;
    hold on
end
            
axes(ratSummary_h_axes(4,1))
title('final mean x')

axes(ratSummary_h_axes(4,2))
title('final mean y')

axes(ratSummary_h_axes(4,3))
title('final mean z')

axes(ratSummary_h_axes(4,4))
title('final mean dist from pellet')

axes(ratSummary_h_axes(4,5))
title('final mean paw orientation')

axes(ratSummary_h_axes(5,1))
title('final var x')

axes(ratSummary_h_axes(5,2))
title('final var y')

axes(ratSummary_h_axes(5,3))
title('final var z')


    
textString{1} = sprintf('%s trajectory summary', ratID);
textString{2} = 'black - baseline; blue - laser stim; red - occlusion';
textString{3} = 'row 1 - mean trajectories, row 2 - mean deviation from mean trajectories, row 4 - mean reach endpoints';
axes(ratSummary_h_figAxis);
text(ratSummary_figProps.leftMargin,ratSummary_figProps.height-0.75,textString,'units','centimeters','interpreter','none');