function [ratSummary_h_fig, ratSummary_h_axes,ratSummary_h_figAxis] = plotRatSummaryFigs(ratID,sessionDates,allSessionDates,sessionType,bodyparts,bodypart_to_plot,...
    mean_pd_trajectories,mean_xyz_from_pd_trajectories,reachEndPoints,mean_euc_dist_from_pd_trajectories,distFromPellet,digit_endAngle,meanOrientations,mean_MRL,...
    endApertures,meanApertures,varApertures,numReachingFrames,PL_summary,numTrialsPerSession,thisRatInfo)
%
%
% INPUTS
%   ratID - rat ID string, format 'RXXXX' where XXXX is the rat #
%   sessionDates - cell array of datetimes containing the date for each
%       session included in these plots
%   allSessionDates - cell array of datetimes containing the date for all
%       sessions, not just the ones included in these plots
%   sessionType - structure with 1 element for each session (not just those
%       included in these plots). Fields:
%           .date
%           .type

traj_x_lim = [-30 10];
traj_y_lim = [-20 15];
traj_z_lim = [-5 50];

dev_x_lim = [0 10];
dev_y_lim = [0 10];
dev_z_lim = [0 10];

mean_aperture_lim = [5 25];
var_aperture_lim = [0 10];

mean_x_lim = [-10 10];
mean_y_lim = [-15 0];
mean_z_lim = [-20 10];
mean_dist_from_pellet_limits = [0 20];

var_x_lim = [0 10];
var_y_lim = [0 10];
var_z_lim = [0 20];

mean_frame_ap_limits = [0 25];
var_frame_ap_limits = [0 10];
trial_num_limits = [0 100];

traj_frame_limits = [0 50];   % number of frames after breaching the slot to look at for aperture and paw oreintation

virus = thisRatInfo.Virus;
if iscell(virus)
    virus = virus{1};
end
laserTiming = thisRatInfo.laserTiming;
if iscell(laserTiming)
    laserTiming = laserTiming{1};
end

bodypart_idx_toPlot = find(findStringMatchinCellArray(bodyparts, bodypart_to_plot));

ratSummary_figProps.m = 5;
ratSummary_figProps.n = 5;

ratSummary_figProps.panelWidth = ones(ratSummary_figProps.n,1) * 10;
ratSummary_figProps.panelHeight = ones(ratSummary_figProps.m,1) * 4;

ratSummary_figProps.colSpacing = ones(ratSummary_figProps.n-1,1) * 0.75;
ratSummary_figProps.rowSpacing = ones(ratSummary_figProps.m-1,1) * 1;

ratSummary_figProps.topMargin = 5;
ratSummary_figProps.leftMargin = 2;

ratSummary_figProps.width = sum(ratSummary_figProps.panelWidth) + ...
    sum(ratSummary_figProps.colSpacing) + ...
    ratSummary_figProps.leftMargin + 2.54;
ratSummary_figProps.height = sum(ratSummary_figProps.panelHeight) + ...
    sum(ratSummary_figProps.rowSpacing) + ...
    ratSummary_figProps.topMargin + 2.54;

[ratSummary_h_fig,ratSummary_h_axes] = createFigPanels5(ratSummary_figProps);
ratSummary_h_figAxis = createFigAxes(ratSummary_h_fig);

numSessions = length(sessionDates);

plottedSessionTypes = cell(1,numSessions);
for iSession = 1 : numSessions


    if ~isdatetime(sessionDates{iSession})
        continue   % no date loaded for this session, perhaps because it wasn't calculated (not scored?)
    end
    allSessionIdx = find(sessionDates{iSession} == allSessionDates);

    if isempty(allSessionIdx)
        % session wasn't computed - maybe because it wasn't scored
        continue;
    end
    curSessionType = sessionType(allSessionIdx).type;
    plottedSessionTypes{iSession} = curSessionType;
    sessionsLeftInBlock = sessionType(allSessionIdx).sessionsLeftInBlock;
    
    sessionTypeUnknown = false;
    switch curSessionType
        case 'training'
            plotRow = 1;
            plot_colmap = colormap(gray);
        case 'laser_during'
            plotRow = 2;
            plot_colmap = colormap(winter);
        case 'laser_between'
            plotRow = 2;
            plot_colmap = colormap(winter);
        case 'occlusion'
            plotRow = 3;
            plot_colmap = colormap(autumn);
        otherwise
            plotRow = 1;
            plot_colmap = colormap(gray);
            sessionTypeUnknown = true;
    end

    if sessionTypeUnknown
        plotColor = plot_colmap(iSession,:);
    else
        plotColor = plot_colmap(sessionsLeftInBlock*3+1,:);
    end
    for iDim = 1 : 3
        axes(ratSummary_h_axes(1,iDim))
        % plot mean for all trajectories
        toPlot = squeeze(mean_pd_trajectories(:,iDim,1,iSession));
        plot(toPlot,'color',plotColor);
        hold on
        
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
    
    axes(ratSummary_h_axes(3,1))
    % paw orientation once through slot
    toPlot = meanOrientations{iSession};
    plot(toPlot,'color',plotColor);
    hold on
    title('mean paw orientation')
    set(gca,'xlim',traj_frame_limits);
    
    axes(ratSummary_h_axes(3,2))
    toPlot = mean_MRL{iSession};
    plot(toPlot,'color',plotColor);
    hold on
    title('mean paw orientation MRL')
    set(gca,'xlim',traj_frame_limits);
end
axes(ratSummary_h_axes(1,4))
title('mean trajectory in 3D');
xlabel('x');ylabel('z');zlabel('y');
scatter3(0,0,0,25,'k','o','markerfacecolor','k')
set(gca,'zdir','reverse','xlim',traj_x_lim,'ylim',traj_z_lim,'zlim',traj_y_lim,...
    'view',[-70,30])

axes(ratSummary_h_axes(2,4))
title('mean euc distance from mean trajectory')


for iDim = 1 : 3
    axes(ratSummary_h_axes(1,iDim))
    switch iDim
        case 1
            title('mean trajectory, x')
            set(gca,'ylim',traj_x_lim)
        case 2
            title('mean trajectory, y')
            set(gca,'ylim',traj_y_lim,'ydir','reverse')
        case 3
            title('mean trajectory, z')
            set(gca,'ylim',traj_z_lim)
    end
    axes(ratSummary_h_axes(2,iDim))
    switch iDim
        case 1
            title('mean deviation from trajectory, x')
            set(gca,'ylim',dev_x_lim)
        case 2
            title('mean deviation from trajectory, y')
            set(gca,'ylim',dev_y_lim)
        case 3
            title('mean deviation from trajectory, z')
            set(gca,'ylim',dev_z_lim)
    end
end

for iSession = 1 : numSessions

    if ~isdatetime(sessionDates{iSession})
        continue   % no date loaded for this session, perhaps because it wasn't calculated (not scored?)
    end
    allSessionIdx = find(sessionDates{iSession} == allSessionDates);
    if isempty(allSessionIdx)
        % session wasn't computed - maybe because it wasn't scored
        continue;
    end
    
    curSessionType = sessionType(allSessionIdx).type;
    sessionsLeftInBlock = sessionType(allSessionIdx).sessionsLeftInBlock;
    switch curSessionType
        case 'training'
            plotRow = 1;
            plot_colmap = colormap(gray);
        case 'laser_during'
            plotRow = 2;
            plot_colmap = colormap(winter);
        case 'laser_between'
            plotRow = 2;
            plot_colmap = colormap(winter);
        case 'occlusion'
            plotRow = 3;
            plot_colmap = colormap(autumn);
    end

    if sessionTypeUnknown
        plotColor = plot_colmap(iSession,:);
    else
        plotColor = plot_colmap(sessionsLeftInBlock*3+1,:);
    end

    for iDim = 1 : 3
        axes(ratSummary_h_axes(4,iDim))
        % find reach end points for the bodypart of interest for all
        % trials
        try
        dim_endPoints = squeeze(reachEndPoints{iSession}{1}(bodypart_idx_toPlot,iDim,:));
        catch
            keyboard
        end
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

    axes(ratSummary_h_axes(1,5))
    % mean number of frames per reach
    mean_reachDuration = nanmean(numReachingFrames(iSession).total) / 300;   % assume frame rate is 300 fps
    std_reachDuration = nanstd(numReachingFrames(iSession).total/300);   % assume frame rate is 300 fps
    scatter(iSession,mean_reachDuration,'markeredgecolor',plotColor,'markerfacecolor',plotColor);
    hold on
    errorbar(iSession,mean_reachDuration,std_reachDuration)

    % mean number of frames per reach, pre and post-slot
    mean_preSlotreachDuration = nanmean(numReachingFrames(iSession).preSlot) / 300;   % assume frame rate is 300 fps
    std_preSlotreachDuration = nanstd(numReachingFrames(iSession).preSlot/300);   % assume frame rate is 300 fps
    mean_postSlotreachDuration = nanmean(numReachingFrames(iSession).postSlot) / 300;   % assume frame rate is 300 fps
    std_postSlotreachDuration = nanstd(numReachingFrames(iSession).postSlot/300);   % assume frame rate is 300 fps    
    scatter(iSession,mean_preSlotreachDuration,'markeredgecolor','k','markerfacecolor',plotColor);
    hold on
    scatter(iSession,mean_postSlotreachDuration,'markeredgecolor','g','markerfacecolor',plotColor);
    errorbar(iSession,mean_preSlotreachDuration,std_preSlotreachDuration,'color','k')
    errorbar(iSession,mean_postSlotreachDuration,std_postSlotreachDuration,'color','g')
    title('mean total,pre/post-slot reach duration (s)')
    
    axes(ratSummary_h_axes(2,5))
    % mean trajectory length
    % WORKING HERE...
    mean_preSlotLength = nanmean(PL_summary(iSession).pd_pre_slot);
    std_preSlotLength  = nanstd(PL_summary(iSession).pd_pre_slot);
    scatter(iSession,mean_preSlotLength,'markeredgecolor',plotColor,'markerfacecolor',plotColor);
    hold on
    errorbar(iSession,mean_preSlotLength,std_preSlotLength)
    
    mean_postSlotLength = nanmean(PL_summary(iSession).digit_traj_length);
    std_postSlotLength  = nanstd(PL_summary(iSession).digit_traj_length);
    scatter(iSession,mean_postSlotLength,'markeredgecolor',plotColor,'markerfacecolor',plotColor);
    hold on
    errorbar(iSession,mean_postSlotLength,std_postSlotLength)
    title('pre- and post-slot path lengths')
    
    axes(ratSummary_h_axes(4,5))
    % final mean paw aperture
    curApertures = sqrt(sum(endApertures{iSession}.^2,2));
    session_meanAperture = nanmean(curApertures);
    scatter(iSession,session_meanAperture,'markeredgecolor',plotColor,'markerfacecolor',plotColor);
    hold on
    title('mean aperture at reach end')
    set(gca,'ylim',mean_aperture_lim);
    
    axes(ratSummary_h_axes(5,5))
    % variance in final aperture
    session_varAperture = nanvar(curApertures);
    scatter(iSession,session_varAperture,'markeredgecolor',plotColor,'markerfacecolor',plotColor);
    hold on
    title('aperture variance at reach end')
    set(gca,'ylim',var_aperture_lim);
    
    axes(ratSummary_h_axes(3,3))
    MRL = circ_r(digit_endAngle{iSession});
    mean_endAngle = nancirc_mean(digit_endAngle{iSession});
    try
    toPlot = MRL * exp(1i*mean_endAngle);
    catch
        keyboard
    end
    h_line = compass(toPlot);
    h_line.Color = plotColor;
    hold on
    title('final mean paw orientation')
    
    axes(ratSummary_h_axes(3,4))
    toPlot = meanApertures{iSession};
    plot(toPlot,'color',plotColor);
    hold on
    title('mean aperture vs frame')
    set(gca,'ylim',mean_frame_ap_limits,'xlim',traj_frame_limits);
    
    axes(ratSummary_h_axes(3,5))
    toPlot = varApertures{iSession};
    plot(toPlot,'color',plotColor);
    hold on
    title('aperture variance vs frame')
    set(gca,'ylim',var_frame_ap_limits,'xlim',traj_frame_limits);
    
    % number of reaches per session (and also perhaps accuracy)
    axes(ratSummary_h_axes(5,4))
    toPlot = varApertures{iSession};
    scatter(iSession,numTrialsPerSession(iSession),'markeredgecolor',plotColor,'markerfacecolor',plotColor);
    hold on
end
            
axes(ratSummary_h_axes(4,1))
title('final mean x')
set(gca,'ylim',mean_x_lim);

axes(ratSummary_h_axes(4,2))
title('final mean y')
set(gca,'ylim',mean_y_lim);

axes(ratSummary_h_axes(4,3))
title('final mean z')
set(gca,'ylim',mean_z_lim);

axes(ratSummary_h_axes(4,4))
title('final mean dist from pellet')
set(gca,'ylim',mean_dist_from_pellet_limits);


axes(ratSummary_h_axes(5,1))
title('final var x')
set(gca,'ylim',var_x_lim);

axes(ratSummary_h_axes(5,2))
title('final var y')
set(gca,'ylim',var_y_lim);

axes(ratSummary_h_axes(5,3))
title('final var z')
set(gca,'ylim',var_z_lim);

axes(ratSummary_h_axes(5,4))
title('number of trials per session')
set(gca,'ylim',trial_num_limits);

    
textString{1} = sprintf('%s trajectory summary, Stim type: %s, Virus: %s', ratID,laserTiming,virus);
textString{2} = 'black - baseline; blue - laser stim; red - occlusion';
textString{3} = 'row 1 - mean trajectories, row 2 - mean deviation from mean trajectories, row 4 - mean reach endpoints';
% WORKING HERE...ADD SESSION TYPE DATES TO BE WRITTEN INTO HEADER

trainingDates = cell(1);
numTrainingDates = 0;
laserDates = cell(1);
numLaserDates = 0;
occlusionDates = cell(1);
numOcclusionDates = 0;
for iSession = 1 : numSessions
    if ~ischar(plottedSessionTypes{iSession})
        continue;
    end
    switch plottedSessionTypes{iSession}
        case 'training'
            numTrainingDates = numTrainingDates + 1;
            trainingDates{numTrainingDates} = datestr(sessionDates{iSession},'yyyymmdd');
        case 'laser_during'
            numLaserDates = numLaserDates + 1;
            laserDates{numLaserDates} = datestr(sessionDates{iSession},'yyyymmdd');
        case 'laser_between'
            numLaserDates = numLaserDates + 1;
            laserDates{numLaserDates} = datestr(sessionDates{iSession},'yyyymmdd');
        case 'occlusion'
            numOcclusionDates = numOcclusionDates + 1;
            occlusionDates{numOcclusionDates} = datestr(sessionDates{iSession},'yyyymmdd');
    end
end
trainingDatesString = 'training dates: ';
for ii = 1 : numTrainingDates
    trainingDatesString = sprintf('%s, %s', trainingDatesString, trainingDates{ii});
end
laserDatesString = 'laser dates: ';
for ii = 1 : numLaserDates
    laserDatesString = sprintf('%s, %s', laserDatesString, laserDates{ii});
end
occlusionDatesString = 'occlusion/post-laser dates: ';
for ii = 1 : numOcclusionDates
    occlusionDatesString = sprintf('%s, %s', occlusionDatesString, occlusionDates{ii});
end
textString{4} = trainingDatesString;
textString{5} = laserDatesString;
textString{6} = occlusionDatesString;

axes(ratSummary_h_figAxis);
text(ratSummary_figProps.leftMargin,ratSummary_figProps.height-1.5,textString,'units','centimeters','interpreter','none');