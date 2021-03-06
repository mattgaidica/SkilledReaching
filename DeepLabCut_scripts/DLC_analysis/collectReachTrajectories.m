function [reachTrajectories, validTrials, reachEndFrames] = collectReachTrajectories(trialOutcomes,trajectories,all_reachFrameIdx,bodyparts,validOutcomes,pawPref,slot_z,all_initPellet3D)
%
% INPUTS
%
% OUTPUTS
%   reachTrajectories

windowLength = 10;
smoothMethod = 'gaussian';

% numTrials = length(trialOutcomes);
% extract the indices of valid trials for which to calculate reach
% trajectories
validTrials = ismember(trialOutcomes,validOutcomes);
validTrials = find(validTrials);
numValidTrials = length(validTrials);
num_bodyparts = size(trajectories,3);
frameRange = zeros(num_bodyparts,2,numValidTrials);
numFrames = size(trajectories,1);
num_bodyparts = size(trajectories,3);
interp_trajectories = NaN(numFrames,3,num_bodyparts,numValidTrials);
dorsum_through_slot_frame = zeros(numValidTrials,1);
first_paw_dorsum_frame = zeros(numValidTrials,1);
slot_z_wrt_pellet = zeros(numValidTrials,1);

% [mcpIdx,pipIdx,digIdx,pawDorsumIdx] = findReachingPawParts(bodyparts,pawPref);

for iTrial = 1 : numValidTrials
    
    reachEndFrames{iTrial} = determineTrialReachEndFrames(all_reachFrameIdx{validTrials(iTrial)},bodyparts,pawPref);
    cur_trajectory = squeeze(trajectories(:,:,:,iTrial));
    [interp_trajectories(:,:,:,iTrial),frameRange(:,:,iTrial)] = ...
        extractSingleTrialKinematics(cur_trajectory,'windowlength',windowLength,'smoothmethod',smoothMethod);
    
    initPellet_z = all_initPellet3D(validTrials(iTrial),3);
    slot_z_wrt_pellet(iTrial) = slot_z - initPellet_z;

    interp_z_pd = squeeze(interp_trajectories(:,3,pawDorsumIdx,iTrial));
    dorsum_through_slot_frame(iTrial) = find(interp_z_pd < slot_z_wrt_pellet(iTrial),1,'first');
    paw_dorsum_max = max(interp_z_pd(1:dorsum_through_slot_frame(iTrial)-1));
    first_paw_dorsum_frame(iTrial) = find((interp_z_pd(1:dorsum_through_slot_frame(iTrial)-1) == paw_dorsum_max),1,'last');
    
end

end