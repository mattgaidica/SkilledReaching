% script_calculateKinematics_20181128

% parameter for function trajectory_wrt_pellet:
maxReprojError = 10;

% parameters for function interpolateTrajectories
num_pd_TrajectoryPoints = 100;
num_digit_TrajectoryPoints = 100;
start_z_pawdorsum = 46;
smoothWindow = 3;

% parameters for function findFirstPawDorsumFrames:
min_consec_frames = 5;
pThresh = 0.98; 
max_consecutive_misses = 50;
maxReprojError_pawDorsum = 10;    % if paw dorsum found in both views, only count it if they are more or less on the same epipolar line
% slot_z = 200;   % only count it if the paw dorsum was found on the far side of the reaching slot

% parameters for findReachEndpoint
smoothSize = 3;
slot_z_wrt_pellet = 25;

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

% parameter for initPelletLocation
time_to_average_prior_to_reach = 0.1;   % in seconds, the time prior to the reach over which to average pellet location

% calculate the following kinematic parameters:
% 1. max velocity
% 2. average trajectory for a session
% 3. deviation from that trajectory for a session
% 4. distance between trajectories
% 5. closest distance paw to pellet
% 6. minimum z

% hard-coded in info about each rat including handedness
% script_ratInfo_for_deepcut;
% ratInfo_IDs = [ratInfo.ratID];

% use the pellet as the origin for all trajectories. That way it should be
% easy to make left vs right-pawed trajectories overlap - just reflect
% across x = 0. I think this will be OK. -DL 20181015

labeledBodypartsFolder = '/Volumes/Tbolt_01/Skilled Reaching/DLC output';
% shouldn't need this - calibration should be included in the pawTrajectory
% files
% calImageDir = '/Volumes/Tbolt_01/Skilled Reaching/calibration_images';

xlDir = '/Users/dan/Box Sync/Leventhal Lab/Skilled Reaching Project/Scoring Sheets';
xlfname = fullfile(xlDir,'rat_info_pawtracking_DL.xlsx');
csvfname = fullfile(xlDir,'rat_info_pawtracking_DL.csv');
ratInfo = readRatInfoTable(csvfname);
% ratInfo = cleanUpRatTable(ratInfo);

ratInfo_IDs = [ratInfo.ratID];

cd(labeledBodypartsFolder)
ratFolders = dir('R*');
numRatFolders = length(ratFolders);

for i_rat = 4 : 5%numRatFolders

    ratID = ratFolders(i_rat).name
    ratIDnum = str2double(ratID(2:end));
    
    ratInfo_idx = find(ratInfo_IDs == ratIDnum);
    if isempty(ratInfo_idx)
        error('no entry in ratInfo structure for rat %d\n',C{1});
    end
    thisRatInfo = ratInfo(ratInfo_idx,:);
    pawPref = thisRatInfo.pawPref;
    if iscategorical(pawPref)
        pawPref = char(pawPref);
    end
    if iscell(pawPref)
        pawPref = pawPref{1};
    end
    
    ratRootFolder = fullfile(labeledBodypartsFolder,ratID);
    reachScoresFile = [ratID '_scores.csv'];
    reachScoresFile = fullfile(ratRootFolder,reachScoresFile);
    reachScores = readReachScores(reachScoresFile);
    allSessionDates = [reachScores.date]';
    
    
    numTableSessions = length(reachScores);
    dateNums_from_scores_table = zeros(numTableSessions,1);
    for iSession = 1 : numTableSessions
        dateNums_from_scores_table(iSession) = datenum(reachScores(iSession).date);
%         dateNums_from_scores_table(iSession) = datenum(reachScores(iSession).date,'mm/dd/yy');
    end
        
    cd(ratRootFolder);
    sessionDirectories = dir([ratID '_2*']);
    numSessions = length(sessionDirectories);
    
    sessionType = determineSessionType(thisRatInfo, allSessionDates);
    for iSession = 1 : numSessions
        
        fullSessionDir = fullfile(ratRootFolder,sessionDirectories(iSession).name)
        
        if ~isfolder(fullSessionDir)
            continue;
        end
        cd(fullSessionDir);
        C = textscan(sessionDirectories(iSession).name,[ratID '_%8c']);
        sessionDateString = C{1}; % this will be in format yyyymmdd
                            % note date formats from the scores spreadsheet
                            % are in m/d/yy

        sessionDate = datetime(sessionDateString,'inputformat','yyyyMMdd');
        allSessionIdx = find(sessionDate == allSessionDates);
        sessionDateNum = datenum(sessionDateString,'yyyymmdd');
        % figure out index of reachScores array for this session

        sessionReachScores = reachScores(dateNums_from_scores_table == sessionDateNum).scores;
        
        % find the pawTrajectory files
        pawTrajectoryList = dir('R*3dtrajectory.mat');
        if isempty(pawTrajectoryList)
            continue
        end
        
        numTrials = length(pawTrajectoryList);
        
        load(pawTrajectoryList(1).name);
        
%         all_v = zeros(size(pawTrajectory,1)-1,3,size(pawTrajectory,3),numTrials);
%         all_a = zeros(size(pawTrajectory,1)-2,3,size(pawTrajectory,3),numTrials);
%         all_dist_from_pellet = zeros(size(pawTrajectory,1),size(pawTrajectory,3),numTrials);
        all_mcpAngle = zeros(size(pawTrajectory,1),numTrials);
        all_pipAngle = zeros(size(pawTrajectory,1),numTrials);
        all_digitAngle = zeros(size(pawTrajectory,1),numTrials);
        allTrajectories = NaN(size(pawTrajectory,1),size(pawTrajectory,2),size(pawTrajectory,3),numTrials);
        
        [mcpIdx,pipIdx,digIdx,pawDorsumIdx] = findReachingPawParts(bodyparts,pawPref);
        numReachingPawParts = length(mcpIdx) + length(pipIdx) + length(digIdx) + length(pawDorsumIdx);
        all_endPts = zeros(numReachingPawParts, 3, numTrials);
        all_partEndPtFrame = zeros(numReachingPawParts, numTrials);
        all_paw_through_slot_frame = zeros(numTrials,1);
        all_firstPawDorsumFrame = zeros(numTrials,1);
        all_initPellet3D = NaN(numTrials, 3);
        all_endPtFrame = NaN(numTrials,1);
        all_trialOutcomes = NaN(numTrials,1);
        all_isEstimate = false(size(isEstimate,1),size(isEstimate,2),size(isEstimate,3),numTrials);
        vidNum = zeros(numTrials,1);
        
        pelletMissingFlag = false(numTrials,1);
        trialNumbers = zeros(numTrials,1);
        
        invalid3Dpoints = false(size(pawTrajectory,3),size(pawTrajectory,1),numTrials);
        
        slot_z = find_slot_z(fullSessionDir);
        if slot_z < 160 || slot_z > 210
            keyboard
        end
        
        for iTrial = 1 : numTrials
            
            load(pawTrajectoryList(iTrial).name);
            % occasionally there's a video that's too short - truncated
            % during recording? maybe VI turned off in mid-recording?
            % if that's the case, pad with false values
            if size(isEstimate,2) < size(all_isEstimate,2)
                isEstimate(:,end+1:size(all_isEstimate,2),:) = false;
            end 
            all_isEstimate(:,:,:,iTrial) = isEstimate;
            C = textscan(pawTrajectoryList(iTrial).name, [ratID '_' sessionDateString '_%d-%d-%d_%d_3dtrajectory.mat']); 
            trialNumbers(iTrial) = C{4};
            
            trialOutcome = sessionReachScores(trialNumbers(iTrial));
            all_trialOutcomes(iTrial) = trialOutcome;
            
            invalid_direct = find_invalid_DLC_points(direct_pts, direct_p);
            invalid_mirror = find_invalid_DLC_points(mirror_pts, mirror_p);
            if size(invalid_direct,2) < size(invalid3Dpoints,2)
                % make any points that aren't in a truncated video invalid
                invalid_direct(:,end+1:size(invalid3Dpoints,2)) = true;
                invalid_mirror(:,end+1:size(invalid3Dpoints,2)) = true;
            end
            invalid3Dpoints(:,:,iTrial) = invalid_direct & invalid_mirror;   % if both direct and indirect points are invalid, 3D point can't be valid
            
            if ~isempty(initPellet3D)
                % most likely, pellet wasn't brought up by the delivery arm
                % on this trial
                all_initPellet3D(iTrial,:) = initPellet3D;
            end
            
            [mcpAngle,pipAngle,digitAngle] = determineDirectPawOrientation(direct_pts,direct_bp,invalid_direct,pawPref);
            if length(mcpAngle) < size(all_mcpAngle,1)
                mcpAngle(end+1:size(all_mcpAngle,1)) = 0;
                pipAngle(end+1:size(all_pipAngle,1)) = 0;
                digitAngle(end+1:size(all_digitAngle,1)) = 0;
            end
            all_mcpAngle(:,iTrial) = mcpAngle;
            all_pipAngle(:,iTrial) = pipAngle;
            all_digitAngle(:,iTrial) = digitAngle;
            
            [~,~,~,mirror_pawdorsum_idx,~,~,~] = group_DLC_bodyparts(mirror_bp,pawPref);
%             [~,~,~,pawdorsum_idx,~,~,~] = group_DLC_bodyparts(bodyparts,pawPref);
            [mcpIdx,pipIdx,digIdx,pawdorsum_idx] = findReachingPawParts(bodyparts,pawPref);
            
            [paw_through_slot_frame,firstSlotBreak] = findPawThroughSlotFrame(pawTrajectory, bodyparts, pawPref, invalid_direct, invalid_mirror, reproj_error, 'slot_z',slot_z,'maxReprojError',maxReprojError);
            initPellet3D = initPelletLocation(pawTrajectory,bodyparts,frameRate,paw_through_slot_frame,...
                'time_to_average_prior_to_reach',time_to_average_prior_to_reach);

            paw_through_slot_frame = min(firstSlotBreak(digIdx));
            if isnan(paw_through_slot_frame)
                paw_through_slot_frame = min(firstSlotBreak(pipIdx));
            end
            if isnan(paw_through_slot_frame)
                paw_through_slot_frame = min(firstSlotBreak(mcpIdx));
            end

            pawDorsum_p = squeeze(mirror_p(mirror_pawdorsum_idx,:));
            paw_z = squeeze(pawTrajectory(:,3,pawdorsum_idx));
            pawDorsum_reproj_error = squeeze(reproj_error(pawdorsum_idx,:,:));
            firstPawDorsumFrame = findFirstPawDorsumFrame(pawDorsum_p,paw_z,paw_through_slot_frame,pawDorsum_reproj_error,...
                'pthresh',pThresh,'min_consec_frames',min_consec_frames,'max_consecutive_misses',max_consecutive_misses,...
                'slot_z',slot_z,'maxreprojerror',maxReprojError_pawDorsum);
            all_paw_through_slot_frame(iTrial) = paw_through_slot_frame;
            
%             if isempty(firstPawDorsumFrame)
%                 all_firstPawDorsumFrame(iTrial) = NaN;
%             else
                all_firstPawDorsumFrame(iTrial) = firstPawDorsumFrame;
%             end
            
            trajectory = trajectory_wrt_pellet(pawTrajectory, initPellet3D, reproj_error, pawPref,'maxreprojectionerror',maxReprojError);
            
            if isempty(trajectory)
                pelletMissingFlag(iTrial) = true;
                fprintf('%s, trial %d\n',sessionDirectories(iSession).name, trialNumbers(iTrial));
            else
                for i_bp = 1 : size(invalid3Dpoints,1)
                    for iFrame = 1 : size(invalid3Dpoints,2)
                        if invalid3Dpoints(i_bp,iFrame,iTrial)
                            trajectory(iFrame,:,i_bp) = NaN;
                        end
                    end
                end
                allTrajectories(:,:,:,iTrial) = trajectory;
            end
        end
        
        mean_initPellet3D = nanmean(all_initPellet3D);
            
        for iTrial = 1 : numTrials
            if pelletMissingFlag(iTrial)
                load(pawTrajectoryList(iTrial).name);
                trajectory = trajectory_wrt_pellet(pawTrajectory, mean_initPellet3D, reproj_error, pawPref,'maxreprojectionerror',maxReprojError);
                for i_bp = 1 : size(invalid3Dpoints,1)
                    for iFrame = 1 : size(invalid3Dpoints,2)
                        if invalid3Dpoints(i_bp,iFrame,iTrial)
                            trajectory(iFrame,:,i_bp) = NaN;
                        end
                    end
                end

                allTrajectories(:,:,:,iTrial) = trajectory;
            else
                trajectory = squeeze(allTrajectories(:,:,:,iTrial));
            end
            
            % should velocity be calculated based on smoothed position?
%             v = pawVelocity(trajectory,frameRate);
%             all_v(:,:,:,iTrial) = v;
            
            % should acceleration be calculated based on smoothed velocity?
%             a = pawVelocity(v,frameRate);
%             all_a(:,:,:,iTrial) = a;
            
            % DEBUGGING HERE
            [partEndPts,partEndPtFrame,endPts,endPtFrame,pawPartsList,] = ...
                findReachEndpoint(trajectory, bodyparts,frameRate,frameTimeLimits,pawPref,all_paw_through_slot_frame(iTrial),squeeze(all_isEstimate(:,:,:,iTrial)),...
                'smoothsize',smoothSize,'slot_z',slot_z_wrt_pellet);
            all_endPts(:,:,iTrial) = partEndPts;
            all_partEndPtFrame (:,iTrial) = partEndPtFrame;
            all_endPtFrame(iTrial) = endPtFrame;
            
            save(pawTrajectoryList(iTrial).name,'trajectory',...
                'mcpAngle','pipAngle','digitAngle','partEndPts',...
                'partEndPtFrame','endPts','endPtFrame','pawPartsList',...
                'firstPawDorsumFrame','trialOutcome','paw_through_slot_frame',...
                'initPellet3D','-append');
        end

        allTrajectories(allTrajectories == 0) = NaN;
        try
        [normalized_pd_trajectories,smoothed_pd_trajectories,interp_pd_trajectories,normalized_digit_trajectories,smoothed_digit_trajectories,interp_digit_trajectories] = ...
            interpolateTrajectories(allTrajectories,pawPartsList,all_firstPawDorsumFrame,all_paw_through_slot_frame,all_endPtFrame,pawPref,...
            'num_pd_TrajectoryPoints',num_pd_TrajectoryPoints,'num_digit_TrajectoryPoints',num_digit_TrajectoryPoints,'start_z_pawdorsum',start_z_pawdorsum,'smoothwindow',smoothWindow);
        catch
            keyboard
        end
        
        [all_paw_xyz_v,all_paw_tangential_v] = calculatePawVelocity(smoothed_pd_trajectories,frameRate);
        sessionSummaryName = [ratID '_' sessionDateString '_kinematicsSummary.mat'];
        thisSessionType = sessionType(allSessionIdx);
        
        save(sessionSummaryName,'bodyparts','allTrajectories','all_paw_xyz_v','all_paw_tangential_v',...
            'normalized_pd_trajectories','normalized_digit_trajectories',...
            'smoothed_pd_trajectories','smoothed_digit_trajectories',...
            'interp_pd_trajectories','interp_digit_trajectories',...
            'all_mcpAngle','all_pipAngle','all_digitAngle',...
            'all_endPts','all_partEndPtFrame','pawPartsList','all_initPellet3D','trialNumbers','all_trialOutcomes',...
            'frameRate','frameTimeLimits','all_paw_through_slot_frame','all_isEstimate','all_endPtFrame','all_firstPawDorsumFrame','thisRatInfo','thisSessionType','slot_z');
        
    end
    
end