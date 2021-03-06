function h_fig = plotRatReachSummaries(ratSummary, thisRatInfo, varargin)

% REACHING SCORES:
%
% 0 - No pellet, mechanical failure
% 1 -  First trial success (obtained pellet on initial limb advance)
% 2 -  Success (obtain pellet, but not on first attempt)
% 3 -  Forelimb advance -pellet dropped in box
% 4 -  Forelimb advance -pellet knocked off shelf
% 5 -  Obtain pellet with tongue
% 6 -  Walk away without forelimb advance, no forelimb advance
% 7 -  Reached, pellet remains on shelf
% 8 - Used only contralateral paw
% 9 - Laser fired at the wrong time
% 10 ?Used preferred paw after obtaining or moving pellet with tongue
% 11 - paw started out through the slot

full_traj_z_lim = [-5 50];
reachEnd_zlim = [-15 10];

pawPref = char(thisRatInfo.pawPref);
figProps.m = 5;
figProps.n = 5;

figProps.panelWidth = ones(figProps.n,1) * 10;
figProps.panelHeight = ones(figProps.m,1) * 4;

figProps.colSpacing = ones(figProps.n-1,1) * 1;
figProps.rowSpacing = ones(figProps.m-1,1) * 1.5;

figProps.leftMargin = 2.54;
figProps.topMargin = 5;

figProps.width = sum(figProps.colSpacing) + sum(figProps.panelWidth) + figProps.leftMargin + 2.54;
figProps.height = sum(figProps.rowSpacing) + sum(figProps.panelHeight) + figProps.topMargin + 2.54;

[h_fig,h_axes] = createFigPanels5(figProps);

% first row of plots: 
%   column 1: number of trials
%   column 2: breakdown of trial outcomes across sessions
%   column 2: number of reaches in each trial
%   column 3: "event frames" - frames at which paw dorsum is first seen, 
%       paw breaches slot, 1st reach end framez-endpoints vs trial #
%   column 4: z-end points of each reach (paw and digit 2)
%   column 5: 3-D of reach endpoints, color coded by trial type

% ROW 2
% column 1: paw orientation at end of each reach
% column 2: paw orientation for 1st reach in each trial
% column 3: aperture at end of 1st reach in each trial

% number of trials
plotNumTrials_acrossSessions_singleRat(ratSummary,thisRatInfo,'h_axes',h_axes(1,1));

% first and any reach success rates
plotReachSuccess_acrossSessions_singleRat(ratSummary,'both','h_axes',h_axes(1,2))

% mean trajectories
plotMeanPDTrajectory_acrossSessions(ratSummary,thisRatInfo,'h_axes',h_axes(1,3))

plot3Dendpoints_acrossSessions_singleRat(ratSummary,thisRatInfo,'h_axes',h_axes(1,4))

plot_z_endpoints_acrossSessions_singleRat(ratSummary,thisRatInfo,'h_axes',h_axes(1,5))
% second row of plots
%   overlay 3D trajectories for each trial type across each column

% reach velocity profiles

% max reach velocity
plot_max_v_acrossSessions_singleRat(ratSummary,thisRatInfo,'h_axes',h_axes(2,1))

% mean dist from mean trajectory
plot_mean_dist_from_traj_acrossSessions_singleRat(ratSummary,'h_axes',h_axes(2,3))

plot_generalized_variance_acrossSessions_singleRat(ratSummary,thisRatInfo,'h_axes',h_axes(2,4))
% repeat for subsequent plots so first and any success aren't plotted over
% each other

plot_endAperture_acrossSessions_singleRat(ratSummary,thisRatInfo,'h_axes',h_axes(3,1));

plot_meanAperture_acrossSessions_singleRat(ratSummary,'h_axes',h_axes(3,2))

plot_endOrientation_acrossSessions_singleRat(ratSummary,thisRatInfo,'h_axes',h_axes(4,1));

plot_meanOrientation_acrossSessions_singleRat(ratSummary,'h_axes',h_axes(4,2))

h_figAxis = createFigAxes(h_fig);

textString{1} = sprintf('%s rat summary; %s, %s, Virus: %s', ...
    ratSummary.ratID, ratSummary.exptType, char(thisRatInfo.Virus));
% textString{2} = 'rows 2-4: mean absolute difference from mean trajectory in x, y, z for each trial type';
% textString{3} = 'row 5: mean euclidean distance from mean trajectory for each trial type';
axes(h_figAxis);
text(figProps.leftMargin,figProps.height-0.75,textString,'units','centimeters','interpreter','none');
% plot_firstReachDuration(reachData,trialNumbers,ind_trial_type,trialTypeColors,h_axes(3,1));

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function h_scoreBreakdown = plotTrialOutcomeBreakdown(score_breakdown,trialTypeColors,h_axes)

axes(h_axes);
h_scoreBreakdown = zeros(length(score_breakdown),1);
for ii = 1 : length(score_breakdown)
    h_scoreBreakdown(ii) = bar(ii,score_breakdown(ii),'facecolor',trialTypeColors{ii});
    hold on
end
title('trial outcomes')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plotNumReaches(reachData,ind_trial_type,trialTypeColors,h_axes)

axes(h_axes);
numTrials = length(reachData);
num_reaches_per_trial = zeros(numTrials,1);
trialNumbers = zeros(numTrials,1);
for iTrial = 1 : numTrials
    num_reaches_per_trial(iTrial) = length(reachData(iTrial).reachEnds);
    trialNumbers(iTrial) = reachData(iTrial).trialNumbers(2);
end

for ii = 1 : max(ind_trial_type)
    if any(ind_trial_type == ii)
        scatter(trialNumbers(ind_trial_type==ii),num_reaches_per_trial(ind_trial_type==ii),...
            'markerfacecolor',trialTypeColors{ii},'markeredgecolor',trialTypeColors{ii});
        hold on
    end
end
title('num reaches per trial')

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function plotEventFrames(reachData,h_axes)

axes(h_axes);
numTrials = length(reachData);
trialNumbers = zeros(numTrials,1);
all_frames = zeros(3,numTrials);
for iTrial = 1 : numTrials
    trialNumbers(iTrial) = reachData(iTrial).trialNumbers(2);
    if ~isempty(reachData(iTrial).reachStarts)
        all_frames(1,iTrial) = reachData(iTrial).reachStarts(1);
    end
    if ~isempty(reachData(iTrial).slotBreachFrame)
        all_frames(2,iTrial) = reachData(iTrial).slotBreachFrame(1);
    end
    if ~isempty(reachData(iTrial).reachEnds)
        all_frames(3,iTrial) = reachData(iTrial).reachEnds(1);
    end
end

plot(trialNumbers,all_frames(1,:),'b')
hold on
plot(trialNumbers,all_frames(2,:),'r')
plot(trialNumbers,all_frames(3,:),'g')

title('reach start,slot breach,reach end frames')

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plot_z_endpoints(reachData,ind_trial_type,trialTypeColors,all_slot_z_wrt_pellet,h_axes)

axes(h_axes)

numTrials = length(reachData);
trialNumbers = zeros(numTrials,1);
pd_z_endpt = NaN(numTrials,1);
dig2_z_endpt = NaN(numTrials,1);
for iTrial = 1 : numTrials
    if isempty(reachData(iTrial).pdEndPoints)
        continue;
    end
    pd_z_endpt(iTrial) = reachData(iTrial).pdEndPoints(1,3);
    dig2_z_endpt(iTrial) = reachData(iTrial).dig_endPoints(1,2,3);
    trialNumbers(iTrial) = reachData(iTrial).trialNumbers(2);
end

for ii = 1 : max(ind_trial_type)
    if any(ind_trial_type == ii)
        scatter(trialNumbers(ind_trial_type==ii),pd_z_endpt(ind_trial_type==ii),...
            'markerfacecolor',trialTypeColors{ii},'markeredgecolor',trialTypeColors{ii},...
            'markerfacealpha',0.5,'markeredgealpha',0.5);
        hold on
        scatter(trialNumbers(ind_trial_type==ii),dig2_z_endpt(ind_trial_type==ii),...
            'markerfacecolor',trialTypeColors{ii},'markeredgecolor',trialTypeColors{ii},...
            'markerfacealpha',1,'markeredgealpha',1);
    end
end

slot_z_wrt_pellet = nanmean(all_slot_z_wrt_pellet);
line([0 max(trialNumbers)],[slot_z_wrt_pellet,slot_z_wrt_pellet])

title('reach end z')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plot_3D_endpoints(reachData,ind_trial_type,trialTypeColors,pawPref,h_axes,reachEnd_zlim)

x_lim = [-30 10];
y_lim = [-20 5];

axes(h_axes)

numTrials = length(reachData);
pd_z_endpt = NaN(numTrials,3);
dig2_z_endpt = NaN(numTrials,3);
for iTrial = 1 : numTrials
    if isempty(reachData(iTrial).pdEndPoints)
        continue;
    end
    pd_endpt(iTrial,:) = reachData(iTrial).pdEndPoints(1,:);
    dig2_endpt(iTrial,:) = reachData(iTrial).dig_endPoints(1,2,:);
end

for ii = 1 : max(ind_trial_type)
    if any(ind_trial_type == ii)
        validTrialIdx = (ind_trial_type == ii);
        switch pawPref
            case 'left'
                scatter3(-pd_endpt(validTrialIdx,1),pd_endpt(validTrialIdx,3),pd_endpt(validTrialIdx,2),...
                    'markerfacecolor',trialTypeColors{ii},'markeredgecolor',trialTypeColors{ii},...
                    'markerfacealpha',0.5,'markeredgealpha',0.5);
                hold on
                scatter3(-dig2_endpt(validTrialIdx,1),dig2_endpt(validTrialIdx,3),dig2_endpt(validTrialIdx,2),...
                    'markerfacecolor',trialTypeColors{ii},'markeredgecolor',trialTypeColors{ii},...
                    'markerfacealpha',1,'markeredgealpha',1);
            case 'right'
                scatter3(pd_endpt(validTrialIdx,1),pd_endpt(validTrialIdx,3),pd_endpt(validTrialIdx,2),...
                    'markerfacecolor',trialTypeColors{ii},'markeredgecolor',trialTypeColors{ii},...
                    'markerfacealpha',0.5,'markeredgealpha',0.5);
                hold on
                scatter3(dig2_endpt(validTrialIdx,1),dig2_endpt(validTrialIdx,3),dig2_endpt(validTrialIdx,2),...
                    'markerfacecolor',trialTypeColors{ii},'markeredgecolor',trialTypeColors{ii},...
                    'markerfacealpha',1,'markeredgealpha',1);
        end
    end
end

scatter3(0,0,0,25,'marker','*','markerfacecolor','k','markeredgecolor','k');
set(gca,'zdir','reverse','xlim',x_lim,'ylim',reachEnd_zlim,'zlim',y_lim,...
    'view',[-70,30])
xlabel('x');ylabel('z');zlabel('y');

title('3D reach endpoints')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function plot_endReachOrientation(reachData,ind_trial_type,trialTypeColors,h_axes)

axes(h_axes)

numTrials = length(reachData);
trialNumbers = NaN(numTrials,1);
end_orientation = NaN(numTrials,1);
for iTrial = 1 : numTrials
    if isempty(reachData(iTrial).orientation)
        continue;
    end
    if isempty(reachData(iTrial).orientation{1})
        continue;
    end
    end_orientation(iTrial) = reachData(iTrial).orientation{1}(end);
    trialNumbers(iTrial) = reachData(iTrial).trialNumbers(2);
end

for ii = 1 : max(ind_trial_type)
    if any(ind_trial_type == ii)
        validTrialIdx = (ind_trial_type == ii);
        scatter(trialNumbers(validTrialIdx),end_orientation(validTrialIdx),...
            'markerfacecolor',trialTypeColors{ii},'markeredgecolor',trialTypeColors{ii});
        hold on
    end
end
set(gca,'ylim',[0,pi])
title('paw orientation at reach end')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function plot_reachOrientation(reachData,ind_trial_type,trialTypeColors,h_axes)

axes(h_axes)

traj_limits = align_trajectory_to_reach(reachData);

numTrials = length(reachData);
reach_orientation = cell(numTrials,1);
for iTrial = 1 : numTrials
    
    if isempty(reachData(iTrial).orientation)
        continue;
    end
    if isempty(reachData(iTrial).orientation{1})
        continue;
    end
    
    reach_orientation{iTrial} = reachData(iTrial).orientation{1};
    
    % extract digit 2 z-coordinates that correspond to reach orientation
    % points
    % frame limits for the first reach_to_grasp movement
    graspFrames = traj_limits(iTrial).reach_aperture_lims(1,1) : traj_limits(iTrial).reach_aperture_lims(1,2);
    dig2_z = reachData(iTrial).dig2_trajectory{1}(graspFrames,3);
    plot(dig2_z,reach_orientation{iTrial},trialTypeColors{ind_trial_type(iTrial)});
    hold on
end

set(gca,'ylim',[0,pi])
set(gca,'xdir','reverse')
title('paw orientation')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function plot_endReachAperture(reachData,ind_trial_type,trialTypeColors,h_axes)

axes(h_axes)

numTrials = length(reachData);
trialNumbers = NaN(numTrials,1);
end_aperture = NaN(numTrials,1);
for iTrial = 1 : numTrials
    if isempty(reachData(iTrial).aperture)
        continue;
    end
    if isempty(reachData(iTrial).aperture{1})
        continue;
    end
    end_aperture(iTrial) = reachData(iTrial).aperture{1}(end);
    trialNumbers(iTrial) = reachData(iTrial).trialNumbers(2);
end

for ii = 1 : max(ind_trial_type)
    if any(ind_trial_type == ii)
        validTrialIdx = (ind_trial_type == ii);
        scatter(trialNumbers(validTrialIdx),end_aperture(validTrialIdx),...
            'markerfacecolor',trialTypeColors{ii},'markeredgecolor',trialTypeColors{ii});
        hold on
    end
end
set(gca,'ylim',[10,25])
title('digit aperture at reach end')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function plot_digitApertures(reachData,ind_trial_type,trialTypeColors,h_axes)

axes(h_axes)

traj_limits = align_trajectory_to_reach(reachData);

numTrials = length(reachData);
digit_aperture = cell(numTrials,1);
for iTrial = 1 : numTrials
    if isempty(reachData(iTrial).aperture)
        continue;
    end
    if isempty(reachData(iTrial).aperture{1})
        continue;
    end
    digit_aperture{iTrial} = reachData(iTrial).aperture{1};
    graspFrames = traj_limits(iTrial).reach_aperture_lims(1,1) : traj_limits(iTrial).reach_aperture_lims(1,2);
    dig2_z = reachData(iTrial).dig2_trajectory{1}(graspFrames,3);

    plot(dig2_z,digit_aperture{iTrial},trialTypeColors{ind_trial_type(iTrial)});
    hold on
end

set(gca,'ylim',[5,25])
set(gca,'xdir','reverse')
title('digit aperture')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function plot_firstReachDuration(reachData,ind_trial_type,trialTypeColors,h_axes)

axes(h_axes)

numTrials = length(reachData);
trialNumbers = zeros(numTrials,1);
firstReachDuration = zeros(numTrials,1);
for iTrial = 1 : numTrials
    firstReachDuration(iTrial) = length(reachData(iTrial).aperture{1});
    trialNumbers(iTrial) = reachData(iTrial).trialNumbers(2);
end

for ii = 1 : max(ind_trial_type)
    if any(ind_trial_type == ii)
        validTrialIdx = (ind_trial_type == ii);
        scatter(trialNumbers(validTrialIdx),firstReachDuration(validTrialIdx),...
            'markerfacecolor',trialTypeColors{ii},'markeredgecolor',trialTypeColors{ii});
        hold on
    end
end
set(gca,'ylim',[5,70])
title('frames in aperture calc')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function traj_limits = align_trajectory_to_reach(reachData)
% find the start and end index to align orientation and aperture time
% series with paw/grasp trajectories
%
% INPUTS
%   reachData - structure array containing reach info for each trial
%
% OUTPUTS
%   traj_limits
%
% reachData.pd_trajectory starts at "reachStart" and ends at "reachEnd"
% reachData.dig2_trajectory starts at "grastStart" and ends at "graspEnd"
% reachData.firstDigitKinematicsFrame is the first frame for which paw
%   orientation and aperture are defined after the paw breaches the
%   reaching slot
% reachData.orientation/aperture end at reachData.graspEnd

numTrials = length(reachData);
traj_limits.reach_aperture_lims = [];
% traj_limits.grasp_aperture_lims = [];
for iTrial = 1 : numTrials

    num_reaches = length(reachData(iTrial).reachEnds);
    traj_limits(iTrial).reach_aperture_lims = zeros(num_reaches,2);
%     traj_limits(iTrial).grasp_aperture_lims = zeros(num_reaches,2);
    
    for i_reach = 1 : num_reaches
        traj_limits(iTrial).reach_aperture_lims(i_reach,1) = ...
            reachData(iTrial).firstDigitKinematicsFrame(i_reach) - reachData(iTrial).reachStarts(i_reach) + 1;
        traj_limits(iTrial).reach_aperture_lims(i_reach,2) = ...
            traj_limits(iTrial).reach_aperture_lims(i_reach,1) + length(reachData(iTrial).orientation{i_reach}) - 1;

%         traj_limits(iTrial).grasp_aperture_lims(i_reach,1) = ...
%             reachData(iTrial).firstDigitKinematicsFrame(i_reach) - reachData(iTrial).reach_to_grasp_start(i_reach) + 1;
%         traj_limits(iTrial).grasp_aperture_lims(i_reach,2) = ...
%             traj_limits(iTrial).grasp_aperture_lims(i_reach,1) + length(reachData(iTrial).orientation{i_reach}) - 1;
    end

end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function hist_endReachOrientation(reachData,ind_trial_type,trialTypeColors,h_axes)

axes(h_axes)
binWidth = pi/12;

numTrials = length(reachData);
end_orientation = zeros(numTrials,1);
for iTrial = 1 : numTrials
    if isempty(reachData(iTrial).orientation)
        continue;
    end
    if isempty(reachData(iTrial).orientation{1})
        continue;
    end
    end_orientation(iTrial) = reachData(iTrial).orientation{1}(end);
end

for ii = 1 : max(ind_trial_type)
    if ii == 1
        cur_orientations = end_orientation;
    else
        cur_orientations = end_orientation(ind_trial_type == ii);
    end
    
    polarhistogram(cur_orientations,'binwidth',binWidth,'facecolor','none','edgecolor',trialTypeColors{ii});
    hold on
end

title('paw orientation at reach end')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function plot_meanDigitApertures(reachData,ind_trial_type,trialTypeColors,h_axes)
% 
% INPUTS
%
% OUTPUTS
% 

axes(h_axes)

traj_limits = align_trajectory_to_reach(reachData);

zq = 20:-0.1:-15;
numTrials = length(reachData);
num_trial_types = max(ind_trial_type);

interp_apertures = cell(num_trial_types,1);
for i_trialType = 1 : num_trial_types
    if i_trialType == 1   % this is ALL trials
        num_trials_of_this_type = length(ind_trial_type);
    else
        num_trials_of_this_type = sum(ind_trial_type == i_trialType);
    end
    interp_apertures{i_trialType} = NaN(num_trials_of_this_type,length(zq));
    trialCount = 0;
    for iTrial = 1 : numTrials
        
        if isempty(reachData(iTrial).aperture)
            continue;
        end
        if isempty(reachData(iTrial).aperture{1})
            continue;
        end
    
        if (i_trialType==1) || (ind_trial_type(iTrial) == i_trialType)
            
            trialCount = trialCount + 1;
            graspFrames = traj_limits(iTrial).reach_aperture_lims(1,1) : traj_limits(iTrial).reach_aperture_lims(1,2);
            dig2_z = reachData(iTrial).dig2_trajectory{1}(graspFrames,3);
           
            if length(reachData(iTrial).aperture{1}) > 1
                cur_apertures = pchip(dig2_z,reachData(iTrial).aperture{1},zq);
            else
                cur_apertures = NaN(size(zq));
            end
            cur_apertures(zq < min(dig2_z)) = NaN;
            cur_apertures(zq > max(dig2_z)) = NaN;
            interp_apertures{i_trialType}(trialCount,:) = cur_apertures;
            
        end
            
    end
    
    plot(zq,nanmean(interp_apertures{i_trialType}),trialTypeColors{i_trialType})
    hold on
end

set(gca,'ylim',[5,25])
set(gca,'xdir','reverse')
title('mean digit aperture vs z by reach outcome')

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function hist_endReachAperture(reachData,ind_trial_type,trialTypeColors,h_axes)

axes(h_axes)
aperture_limits = [10,25];
binEdges = aperture_limits(1) : 1 : aperture_limits(2);

numTrials = length(reachData);
end_aperture = zeros(numTrials,1);
for iTrial = 1 : numTrials
    if isempty(reachData(iTrial).aperture)
        continue;
    end
    if isempty(reachData(iTrial).aperture{1})
        continue;
    end
    end_aperture(iTrial) = reachData(iTrial).aperture{1}(end);
end

for ii = 1 : max(ind_trial_type)
    if ii == 1
        cur_apertures = end_aperture;
    else
        cur_apertures = end_aperture(ind_trial_type == ii);
    end
    
    histogram(cur_apertures,'binedges',binEdges,'facecolor','none','edgecolor',trialTypeColors{ii});
    hold on
end

set(gca,'xlim',[10,25])

title('digit aperture at reach end')

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plot_meanReachOrientation(reachData,ind_trial_type,trialTypeColors,h_axes)

axes(h_axes)

traj_limits = align_trajectory_to_reach(reachData);

zq = 20:-0.1:-15;
numTrials = length(reachData);
num_trial_types = max(ind_trial_type);

interp_orientations = cell(num_trial_types,1);
for i_trialType = 1 : num_trial_types
    if i_trialType == 1   % this is ALL trials
        num_trials_of_this_type = length(ind_trial_type);
    else
        num_trials_of_this_type = sum(ind_trial_type == i_trialType);
    end
    interp_orientations{i_trialType} = NaN(num_trials_of_this_type,length(zq));
    trialCount = 0;
    for iTrial = 1 : numTrials
        
        if isempty(reachData(iTrial).orientation)
            continue
        end
        if isempty(reachData(iTrial).orientation{1})
            continue
        end
        if (i_trialType==1) || (ind_trial_type(iTrial) == i_trialType)
            
            trialCount = trialCount + 1;
            graspFrames = traj_limits(iTrial).reach_aperture_lims(1,1) : traj_limits(iTrial).reach_aperture_lims(1,2);
            dig2_z = reachData(iTrial).dig2_trajectory{1}(graspFrames,3);
            
            
%             or_interp = NaN(length(zq),1);
            if length(reachData(iTrial).orientation{1}) > 1
                cur_orientations = pchip(dig2_z,unwrap(reachData(iTrial).orientation{1}),zq);
            else
                cur_orientations = NaN(size(zq));
            end
            cur_orientations(zq < min(dig2_z)) = NaN;
            cur_orientations(zq > max(dig2_z)) = NaN;
            interp_orientations{i_trialType}(trialCount,:) = cur_orientations;
            
        end
            
    end
    
    plot(zq,nanmean(interp_orientations{i_trialType}),trialTypeColors{i_trialType})
    hold on
end

set(gca,'ylim',[0,pi])
set(gca,'xdir','reverse')
title('mean paw orientation vs z by reach outcome')
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function hist_z_endPoints(reachData,ind_trial_type,trialTypeColors,h_axes)

axes(h_axes)
z_limits = [-20,20];
binEdges = z_limits(1) : 1 : z_limits(2);

numTrials = length(reachData);
pd_z_endpt = NaN(numTrials,1);
dig2_z_endpt = NaN(numTrials,1);
for iTrial = 1 : numTrials
    if isempty(reachData(iTrial).pdEndPoints) || isempty(reachData(iTrial).dig2_endPoints)
        continue
    end
    pd_z_endpt(iTrial) = reachData(iTrial).pdEndPoints(1,3);
    dig2_z_endpt(iTrial) = reachData(iTrial).dig2_endPoints(1,3);
end

for ii = 1 : max(ind_trial_type)
    if ii == 1
        cur_dig2_z = dig2_z_endpt;
        cur_pd_z = pd_z_endpt;
    else
        cur_dig2_z = dig2_z_endpt(ind_trial_type == ii);
        cur_pd_z = pd_z_endpt(ind_trial_type == ii);
    end
    
    histogram(cur_dig2_z,'binedges',binEdges,'facecolor','none','edgecolor',trialTypeColors{ii},'edgealpha',1);
    hold on
    histogram(cur_pd_z,'binedges',binEdges,'facecolor','none','edgecolor',trialTypeColors{ii},'edgealpha',0.5);
    
end

set(gca,'xlim',z_limits)
set(gca,'xdir','reverse')

title('endpoint z by trial type')

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plot_pawVelocityProfiles(reachData,ind_trial_type,trialTypeColors,h_axes,full_traj_z_lim)

axes(h_axes);
numTrials = length(reachData);

for iTrial = 1 : numTrials
    if isempty(reachData(iTrial).pd_v)
        continue;
    end
    if isempty(reachData(iTrial).pd_v{1})
        continue;
    end
    cur_v = reachData(iTrial).pd_v{1};
    cur_v = sqrt(sum(cur_v.^2,2));
    plot(reachData(iTrial).pd_trajectory{1}(1:end-1,3),cur_v,'color',trialTypeColors{ind_trial_type(iTrial)});
    hold on
end

title('tangential paw velocity vs z')
set(gca,'xdir','reverse','ylim',[0 1100],'xlim',full_traj_z_lim)
ylabel('mm/s');

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plot_dig2_velocityProfiles(reachData,ind_trial_type,trialTypeColors,h_axes)

axes(h_axes);
numTrials = length(reachData);

for iTrial = 1 : numTrials
    cur_v = reachData(iTrial).dig2_v{1};
    cur_v = sqrt(sum(cur_v.^2,2));
    plot(reachData(iTrial).dig2_trajectory{1}(1:end-1,3),cur_v,'color',trialTypeColors{ind_trial_type(iTrial)});
    hold on
end

title('tangential digit 2 velocity vs z')
set(gca,'xdir','reverse','ylim',[0 1100])
ylabel('mm/s');

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function plot_meanPawVelocityProfiles(reachData,ind_trial_type,trialTypeColors,h_axes,full_traj_z_lim)

zq = 50:-0.5:-15;

axes(h_axes);
numTrials = length(reachData);
num_trial_types = max(ind_trial_type);

interp_v = cell(num_trial_types,1);

for i_trialType = 1 : num_trial_types
    if i_trialType == 1   % this is ALL trials
        num_trials_of_this_type = length(ind_trial_type);
    else
        num_trials_of_this_type = sum(ind_trial_type == i_trialType);
    end
    interp_v{i_trialType} = NaN(num_trials_of_this_type,length(zq));
    
    trialCount = 0;
    for iTrial = 1 : numTrials
        
        if isempty(reachData(iTrial).pd_trajectory)
            continue;
        end
        if isempty(reachData(iTrial).pd_trajectory{1})
            continue;
        end
        if (i_trialType==1) || (ind_trial_type(iTrial) == i_trialType)
            trialCount = trialCount + 1;
            
            pd_z = reachData(iTrial).pd_trajectory{1}(1:end-1,3);
            cur_v = reachData(iTrial).pd_v{1};
            cur_v = sqrt(sum(cur_v.^2,2));
            try
            cur_v_interp = pchip(pd_z,cur_v,zq);
            catch
                keyboard
            end
            cur_v_interp(zq < min(pd_z)) = NaN;
            cur_v_interp(zq > max(pd_z)) = NaN;
            
            interp_v{i_trialType}(trialCount,:) = cur_v_interp;
        end
        
    end
    plot(zq,nanmean(interp_v{i_trialType}),trialTypeColors{i_trialType})
    hold on

title('mean tangential paw velocity vs z')
set(gca,'xdir','reverse','ylim',[0 1100],'xlim',full_traj_z_lim)
ylabel('mm/s');

end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function plot_3DreachTrajectories(reachData,ind_trial_type,trialTypeColors,pawPref,h_axes,full_traj_z_lim)

x_lim = [-30 10];
y_lim = [-20 10];


axes(h_axes)

numTrials = length(reachData);

for iTrial = 1 : numTrials
    
    if isempty(reachData(iTrial).pd_trajectory)
        continue;
    end
    if isempty(reachData(iTrial).pd_trajectory{1})
        continue;
    end
    switch pawPref
        case 'left'
            plot3(-reachData(iTrial).pd_trajectory{1}(:,1),...
                  reachData(iTrial).pd_trajectory{1}(:,3),...
                  reachData(iTrial).pd_trajectory{1}(:,2),...
                  trialTypeColors{ind_trial_type(iTrial)});
        case 'right'
            plot3(-reachData(iTrial).pd_trajectory{1}(:,1),...
                  reachData(iTrial).pd_trajectory{1}(:,3),...
                  reachData(iTrial).pd_trajectory{1}(:,2),...
                  trialTypeColors{ind_trial_type(iTrial)});
    end
      hold on
end

scatter3(0,0,0,25,'marker','*','markerfacecolor','k','markeredgecolor','k');
set(gca,'zdir','reverse','xlim',x_lim,'ylim',full_traj_z_lim,'zlim',y_lim,...
    'view',[-70,30])
xlabel('x');ylabel('z');zlabel('y');

title('3D paw trajectories')

end

