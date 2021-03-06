function reachData = identifyReaches(reachData,interp_trajectory,bodyparts,slot_z_wrt_pellet,pawPref,varargin)
%
% INPUTS
%   reachData
%   interp_trajectory
%   bodyparts
%   slot_z_wrt_pellet
%   pawPref - 'left' or 'right'
%
% OUTPUTS
%   reachData

maxReach_Grasp_separation = 25;
minGraspSeparation = 25;
minGraspProminence = 2;
maxPreGraspProminence = 10;
minReachProminence = 10;
max_digit_paw_sep = 30;   % max distance allowed between tip of second digit and paw

for iarg = 1 : 2 : nargin - 5
    switch lower(varargin{iarg})
        case 'mingraspprominence'
            minGrasprominence = varargin{iarg + 1};
        case 'minreachprominence'
            minReachProminence = varargin{iarg + 1};
        case 'maxpregraspprominence'
            maxPreGraspProminence = varargin{iarg + 1};
        case 'mingraspseparation'
            minGraspSeparation = varargin{iarg + 1};
            
    end
end

numFrames = size(interp_trajectory,1);
[~,~,digIdx,pawDorsumIdx] = findReachingPawParts(bodyparts,pawPref);

dig1_traj = squeeze(interp_trajectory(:,:,digIdx(1)));
dig2_traj = squeeze(interp_trajectory(:,:,digIdx(2)));
dig4_traj = squeeze(interp_trajectory(:,:,digIdx(4)));
pd_traj = squeeze(interp_trajectory(:,:,pawDorsumIdx));

dig1_z = dig1_traj(:,3);
dig2_z = dig2_traj(:,3);
dig4_z = dig4_traj(:,3);
pd_z = pd_traj(:,3);

% find reaches that travel a long distance on the way out.
% currently, based on finding maximum extent of digit 2
[reachMins,~] = islocalmin(dig2_z,1,...
            'flatselection','first',...
            'minprominence',minReachProminence,...
            'prominencewindow',[100,0],...
            'minseparation',minGraspSeparation);

% exclude reaches where the paw immediately starts going forward
% again. Again, based on digit 2
reaches_to_keep = islocalmin(dig2_z,1,...
            'minprominence',1,...
            'prominencewindow',[0,1000],...
            'minseparation',minGraspSeparation);
reachMins = reachMins & reaches_to_keep;
        
[graspMins,~] = islocalmin(dig2_z,1,...
            'flatselection','first',...
            'minprominence',minGraspProminence,...
            'prominencewindow',[30,0],...
            'minseparation',minGraspSeparation); 
% exclude grasps where the paw immediately starts going forward
% again
grasps_to_keep = islocalmin(dig2_z,1,...
            'minprominence',1,...
            'prominencewindow',[0,1000],...
            'minseparation',minGraspSeparation);
graspMins = graspMins & grasps_to_keep;

% exclude reaches  and grasps where the paw dorsum is too far from digit 2 tip - this
% sometimes happens if the rat reaches with the wrong paw and it is
% misidentified as the "preferred" paw
% find the digit tip farthest from the box
dig1_pd_diff = dig1_traj - pd_traj;
dig2_pd_diff = dig2_traj - pd_traj;
dig4_pd_diff = dig4_traj - pd_traj;
dig1_pd_dist = sqrt(sum(dig1_pd_diff.^2,2));
dig2_pd_dist = sqrt(sum(dig2_pd_diff.^2,2));
dig4_pd_dist = sqrt(sum(dig4_pd_diff.^2,2));

dig_pd_dist = max([dig1_pd_dist,dig2_pd_dist,dig4_pd_dist],[],2);
excludeFrames = dig_pd_dist > max_digit_paw_sep;
reachMins = reachMins & ~excludeFrames;
graspMins = graspMins & ~excludeFrames;
% find grasps associated with reaches
% num_reaches = sum(reachMins);
% reachFrames = find(reachMins);
% isReachRegion = false(size(reachMins));
% for i_reach = 1 : num_reaches
%     startFrame = max(reachFrames(i_reach)-maxReach_Grasp_separation,1);
%     endFrame = min(reachFrames(i_reach)+maxReach_Grasp_separation,length(reachMins));
%     isReachRegion(startFrame:endFrame) = true;
% end
% reach_to_grasp_end = isReachRegion & graspMins;
% exclude grasps where the paw moves forward a lot prior to the grasp, but
% isn't associated with a reach
% grasps_to_exclude = islocalmin(dig2_z,1,...
%             'flatselection','first',...
%             'minprominence',maxPreGraspProminence,...
%             'prominencewindow',[100,0]);
% grasps_to_exclude = grasps_to_exclude & ~reach_to_grasp_end;
% graspMins = graspMins & ~grasps_to_exclude;

% exclude reaches not associated with a grasp
% isReachToGraspRegion = false(size(reach_to_grasp_end));
% reach_to_grasp_end_frames = find(reach_to_grasp_end);
% num_reach_to_grasp = sum(reach_to_grasp_end);
% for i_reach_to_grasp = 1 : num_reach_to_grasp
%     startFrame = max(reach_to_grasp_end_frames(i_reach_to_grasp)-maxReach_Grasp_separation,1);
%     endFrame = min(reach_to_grasp_end_frames(i_reach_to_grasp)+maxReach_Grasp_separation,length(reachMins));
%     isReachToGraspRegion(startFrame:endFrame) = true;
% end
% reachMins = reachMins & isReachToGraspRegion;

% make sure that both digits 1 and 4 locations are known/estimated at the
% end of each grasp. They may be missing if the digits aren't all the
% way through the slot at reach termination. Essentially, make sure all
% digits are through the slot
areDigitsThroughSlot = (dig1_z < slot_z_wrt_pellet) & (dig2_z < slot_z_wrt_pellet) & (dig4_z < slot_z_wrt_pellet);
reachData.reachEnds = find(reachMins & areDigitsThroughSlot);
reachData.graspEnds = find(graspMins & areDigitsThroughSlot);
% the first grasp must occur with or after the first reach
% if ~isempty(reachData.reachEnds)
%     reachData.graspEnds = reachData.graspEnds(reachData.graspEnds > reachData.reachEnds(1) - maxReach_Grasp_separation);
% end

% find the paw dorsum maxima in between each reach termination
reachStarts = false(numFrames,1);
num_reaches = length(reachData.reachEnds);
removeReachEndFlag = false(num_reaches,1);
for i_reach = 1 : num_reaches
    % look in the interval from the previous reach (or trial start) to the
    % current reach
    if i_reach == 1
        startFrame = 1;
    else
        startFrame = reachData.reachEnds(i_reach-1);
    end
    lastFrame = reachData.reachEnds(i_reach);

    interval_dig2_z_max = max(dig2_z(startFrame:lastFrame));
    interval_pd_z_max = max(pd_z(startFrame:lastFrame));
    if isnan(interval_pd_z_max)   % paw dorsum wasn't found before this reach end point; can happen if rat reaches with wrong paw first
        % invalidate this reach
        removeReachEndFlag(i_reach) = true;
    end
%     reachStarts(dig2_z == interval_dig2_z_max) = true;
    reachStarts(pd_z == interval_pd_z_max) = true;

end
reachData.reachEnds = reachData.reachEnds(~removeReachEndFlag);    
reachData.reachStarts = find(reachStarts);
% find the digit 2 maxima in between each grasp termination
num_grasps = length(reachData.graspEnds);

% reach_and_grasp_ends = unique(sort([reachData.reachEnds;reachData.graspEnds]));
graspStarts = false(numFrames,1);
for i_grasp = 1 : num_grasps
    
%     current_grasp_idx = reachData.graspEnds(i_grasp);
%     current_grasp_idx = find(reach_and_grasp_ends == reachData.graspEnds(i_grasp));
    if i_grasp == 1   % this shouldn't happen - there should be a reach before the first grasp, but just in case...
        previous_grasp_frame = 1;
    else
        previous_grasp_frame = reachData.graspEnds(i_grasp-1);
    end
    interval_dig2_z_max = max(dig2_z(previous_grasp_frame:reachData.graspEnds(i_grasp)));
    graspStarts(dig2_z == interval_dig2_z_max) = true;
end
reachData.graspStarts = find(graspStarts);
% reach_to_grasp_end = reach_to_grasp_end & areDigitsThroughSlot;

% make sure each reach_to_grasp is associated with a reach. Generally, this
% shouldn't be an issue, but might occasionally happen if the digits aren't
% all the way through the slot when the reach is complete based on the paw
% dorsum trajectory, but not based on the digit trajectories (or vice
% versa)

% make sure there is one and only one "reach_to_grasp" point associated
% with each reach
% num_reaches = length(reachData.reachEnds);
% grasps_to_keep = false(size(reach_to_grasp_end));
% for i_reach = 1 : num_reaches
%     isReachRegion = false(size(reach_to_grasp_end));
%     try
%     reachRegionStartFrame = max(1,reachData.reachEnds(i_reach)-maxReach_Grasp_separation);
%     reachRegionEndFrame = min(numFrames,reachData.reachEnds(i_reach)+maxReach_Grasp_separation);
%     isReachRegion(reachRegionStartFrame:reachRegionEndFrame) = true;
%     catch
%         keyboard
%     end
%     poss_reach_to_grasp_end = reach_to_grasp_end & isReachRegion;
%     if sum(poss_reach_to_grasp_end) > 1   % more than one candidate grasp
%         % pick the grasp closest to the paw dorsum reach endpoint
%         poss_reach_to_grasp_end_frames = find(poss_reach_to_grasp_end);
%         time_to_grasp = abs(poss_reach_to_grasp_end_frames - reachData.reachEnds(i_reach));
%         grasp_to_keep_idx = find(time_to_grasp == min(time_to_grasp),1);
%         grasps_to_keep(poss_reach_to_grasp_end_frames(grasp_to_keep_idx)) = true;
%     elseif ~any(poss_reach_to_grasp_end)   % no candidate grasps for this reach - can happen if digits 1 and 4 aren't identified
%                                    % remove this reach from the list
%         reachData.reachEnds(i_reach) = NaN;
%         reachData.reachStarts(i_reach) = NaN;
%     else   % there is exactly one reach_to_grasp associated with this reach
%         grasps_to_keep = grasps_to_keep | poss_reach_to_grasp_end;
%     end 
% end
% reach_to_grasp_end = reach_to_grasp_end & grasps_to_keep;
% reachData.reachEnds = reachData.reachEnds(~isnan(reachData.reachEnds));
% reachData.reachStarts = reachData.reachStarts(~isnan(reachData.reachStarts));
% 
% 
% % make sure there is one and only one reach for each reach_to_grasp frame
% reachBoolean = false(size(reach_to_grasp_end));
% reachBoolean(reachData.reachEnds) = true;
% reach_to_grasp_end_frames = find(reach_to_grasp_end);
% reaches_to_keep = false(size(reach_to_grasp_end));
% for i_reach_to_grasp = 1 : length(reach_to_grasp_end_frames)
%     isReachToGraspRegion = false(size(reach_to_grasp_end));
%     reach_to_grasp_end_regionStartFrame = max(1,reach_to_grasp_end_frames(i_reach_to_grasp)-maxReach_Grasp_separation);
%     reach_to_grasp_end_regionEndFrame = min(numFrames,reach_to_grasp_end_frames(i_reach_to_grasp)+maxReach_Grasp_separation);
%     isReachToGraspRegion(reach_to_grasp_end_regionStartFrame:reach_to_grasp_end_regionEndFrame) = true;
%     
%     poss_reach = reachBoolean & isReachToGraspRegion;
%     if sum(poss_reach) > 1   % more than one candidate reach
%         % pick the reach closest to the grasp endpoint; throw out the other
%         poss_reach_frames = find(poss_reach);
%         time_to_grasp = abs(poss_reach_frames - reach_to_grasp_end_frames(i_reach_to_grasp));
%         reach_to_keep_idx = find(time_to_grasp == min(time_to_grasp),1);
%         reaches_to_keep(poss_reach_frames(reach_to_keep_idx)) = true;  
%     elseif ~any(poss_reach)   % no reach close enough to be associated with this grasp
%         reach_to_grasp_end(reach_to_grasp_end_frames(i_reach_to_grasp)) = false;
%     else   % there is exactly one reach associated with this reach_to_grasp
%         reaches_to_keep = reaches_to_keep | poss_reach;
%     end
% end
% 
% reachBoolean = reachBoolean & reaches_to_keep;
% preservedReachIdx = ismember(reachData.reachEnds,find(reaches_to_keep));
% reachData.reachEnds = find(reachBoolean);
% reachData.reachStarts = reachData.reachStarts(preservedReachIdx);
% 
% reachData.reach_to_grasp_end = find(reach_to_grasp_end & areDigitsThroughSlot);
% grasp_idx = ismember(reachData.graspEnds,reachData.reach_to_grasp_end);
% reachData.reach_to_grasp_start = reachData.graspStarts(grasp_idx);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%