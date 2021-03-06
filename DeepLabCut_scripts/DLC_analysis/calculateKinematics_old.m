% by Dan Leventhal, updated 3/8/2019

% script to take 3D reconstructions from DLC output and extract some
% relatively simple kinematics

% template name for viable trajectory files (for searching)
trajectory_file_name = 'R*3dtrajectory.mat';

% pointer to get info from a spreadsheet about each rat
xlDir = '/Users/dan/Box Sync/Leventhal Lab/Skilled Reaching Project/Scoring Sheets';
csvfname = fullfile(xlDir,'rat_info_pawtracking_DL.csv');
ratInfo = readRatInfoTable(csvfname);

% master directory containing the deeplabcut output
labeledBodypartsFolder = '/Volumes/Tbolt_01/Skilled Reaching/DLC output';
% ANTICIPATED DIRECTORY STRUCTURE:
%  For each rat, a folder called ratID (i.e., 'R0100'). Each of these
%  direcories should start with 'R' - that's what the code looks for.
%  Under that, a directory for each session (i.e., 'R0100_yyyymmdd')
%  Under that, a directory for each view (i.e., 'R0100_yyyymmdd_direct', 
%     'R0100_yyyymmdd_left', or 'R0100_yyyymmdd_right' )
%  In each of those folders, the appropriate deeplabcut output files. There
%  should be matching files in each folder for each video

% parameter for function trajectory_wrt_pellet:
maxReprojError = 15;

% parameters for function interpolateTrajectories
num_pd_TrajectoryPoints = 100;   % number of points to divide the paw dorsum trajectory into
num_digit_TrajectoryPoints = 100;  % number of points to divide the digit trajectories into
start_z_pawdorsum = 46;    % needs to be adjusted depending on specific mirror geometry.
                           % first z-point (in mm from the camera lens) at
                           % which to start calculating the paw dorsum
                           % trajectory
smoothWindow = 3;          % smoothing window for trajectory interpolation
    
% parameters for find_invalid_DLC_points
maxDistPerFrame = 30;
min_valid_p = 0.85;
min_certain_p = 0.97;
maxDistFromNeighbor_invalid = 70;

% parameters for function findFirstPawDorsumFrame:
min_consec_frames = 5;
pThresh = 0.98; 
max_consecutive_misses = 50;
maxReprojError_pawDorsum = 10;    % if paw dorsum found in both views, only count it if they are more or less on the same epipolar line

% parameters for findReachEndpoint
smoothSize = 3;

% paramaeters for readReachScores
csvDateFormat = 'MM/dd/yyyy';

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

ratInfo_IDs = [ratInfo.ratID];

cd(labeledBodypartsFolder)
ratFolders = dir('R*');
numRatFolders = length(ratFolders);

% modify for loop to analyze specific rats
for i_rat = 1:numRatFolders

    ratID = ratFolders(i_rat).name;
    ratIDnum = str2double(ratID(2:end));
    
    % pull out rat info for the rat being analyzed
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
    
    % load scoring information (if available) for this rat. Would have to
    % comment this out and create a workaround for matching dates if scores
    % not available
    ratRootFolder = fullfile(labeledBodypartsFolder,ratID);
    reachScoresFile = [ratID '_scores.csv'];
    reachScoresFile = fullfile(ratRootFolder,reachScoresFile);
    reachScores = readReachScores(reachScoresFile,'csvdateformat',csvDateFormat);
    allSessionDates = [reachScores.date]';

    numTableSessions = length(reachScores);
    dateNums_from_scores_table = zeros(numTableSessions,1);
    for iSession = 1 : numTableSessions
        dateNums_from_scores_table(iSession) = datenum(reachScores(iSession).date);
    end
        
    cd(ratRootFolder);
    sessionDirectories = listFolders([ratID '_2*']);
    numSessions = length(sessionDirectories);
    
    % specific to Leventhal Lab experiments with optogenetics
    sessionType = determineSessionType(thisRatInfo, allSessionDates);
    
    for iSession = 1 : numSessions
        
        fullSessionDir = fullfile(ratRootFolder,sessionDirectories{iSession});
        
        if ~isfolder(fullSessionDir)
            continue;
        end
        cd(fullSessionDir);
        C = textscan(sessionDirectories{iSession},[ratID '_%8c']);
        sessionDateString = C{1}; % this will be in format yyyymmdd
                            % note date formats from the scores spreadsheet
                            % are in mm/dd/yy

        sessionDate = datetime(sessionDateString,'inputformat','yyyyMMdd');
        allSessionIdx = find(sessionDate == allSessionDates);
        sessionDateNum = datenum(sessionDateString,'yyyymmdd');
        % figure out index of reachScores array for this session

        sessionReachScores = reachScores(allSessionIdx).scores;
        
        % find the pawTrajectory files
        pawTrajectoryList = dir(trajectory_file_name);
        if isempty(pawTrajectoryList)
            continue
        end
        
        numTrials = length(pawTrajectoryList);
        
        load(pawTrajectoryList(1).name);
        
        all_mcpAngle = zeros(size(pawTrajectory,1),numTrials);
        all_pipAngle = zeros(size(pawTrajectory,1),numTrials);
        all_digitAngle = zeros(size(pawTrajectory,1),numTrials);
        all_pawAngle = zeros(size(pawTrajectory,1),numTrials);
        allTrajectories = NaN(size(pawTrajectory,1),size(pawTrajectory,2),size(pawTrajectory,3),numTrials);
        
        [mcpIdx,pipIdx,digIdx,pawDorsumIdx] = findReachingPawParts(bodyparts,pawPref);
        numReachingPawParts = length(mcpIdx) + length(pipIdx) + length(digIdx) + length(pawDorsumIdx);
        all_endPts = zeros(numReachingPawParts, 3, numTrials);   % farthest reach extension on the initial reach
        all_endPtFrame = NaN(numTrials,1);                       % frame at which maximum extension of digit 2 was achieved on the initial reach
        all_partEndPts = zeros(numReachingPawParts, 3, numTrials); % farthest reach extension for each individual body part (first reach only)
        all_partEndPtFrame = zeros(numReachingPawParts, numTrials);  % frame at which full extension occurred for each part
        all_paw_through_slot_frame = zeros(numTrials,1);    % frame where digit 2 is first identified in front of the slot AFTER it was identified behind the slot
        all_firstSlotBreak = zeros(numReachingPawParts, numTrials); % frame where each paw part is first identified in front of the slot AFTER it was identified behind the slot
        all_first_pawPart_outside_box = zeros(numReachingPawParts, numTrials);   % same as above, but includes if paw started outside box
        all_firstPawDorsumFrame = zeros(numTrials,1);       % first frame in which the paw dorsum was reliably identified in both views
        all_aperture = NaN(size(pawTrajectory,1),3,numTrials);   % distance between tips of first and fourth digits
        all_maxDigitReachFrame = zeros(numTrials,1);             % frame for maximum extension in the entire video (not just initial reach)
        all_initPellet3D = NaN(numTrials, 3);                    % 3D location of the pellet
        all_trialOutcomes = NaN(numTrials,1);                    % based on reach scores
        all_isEstimate = false(size(isEstimate,1),size(isEstimate,2),size(isEstimate,3),numTrials);  % concatenation of isEstimate arrays for each trial
        vidNum = zeros(numTrials,1);
        
        pelletMissingFlag = false(numTrials,1);
        % sometimes the session restarted and we get duplicate trial
        % numbers. The first column of trialNumbers will contain the trial
        % numbers from the file names. The second column will contain trial
        % numbers as recorded in the csv scoring tables.
        trialNumbers = zeros(numTrials,2);
        for iTrial = 1 : numTrials
            C = textscan(pawTrajectoryList(iTrial).name, [ratID '_' sessionDateString '_%d-%d-%d_%d_3dtrajectory.mat']); 
            trialNumbers(iTrial,1) = C{4};
        end
        % necessary because if the skilled reaching VI restarted, need to
        % account for renumbering the videos
        trialNumbers(:,2) = resolveDuplicateTrialNumbers(trialNumbers(:,1));
        invalid3Dpoints = false(size(pawTrajectory,3),size(pawTrajectory,1),numTrials);
        
        % look for the break in z-coordinates, which is where the paw is
        % obscured in the mirror view by the front panel
        slot_z = find_slot_z(fullSessionDir,'trajectory_file_name',trajectory_file_name);
        
        for iTrial = 1 : numTrials
            
            if exist('manually_invalidated_points','var')
                clear manually_invalidated_points
            end
            load(pawTrajectoryList(iTrial).name);

            % occasionally there's a video that's too short - truncated
            % during recording? maybe VI turned off in mid-recording?
            % if that's the case, pad with false values
            if size(isEstimate,2) < size(all_isEstimate,2)
                isEstimate(:,end+1:size(all_isEstimate,2),:) = false;
            end 
            all_isEstimate(:,:,:,iTrial) = isEstimate;

            trialOutcome = sessionReachScores(trialNumbers(iTrial,2));
            all_trialOutcomes(iTrial) = trialOutcome;
            
            [invalid_mirror, mirror_dist_perFrame] = find_invalid_DLC_points(mirror_pts, mirror_p,mirror_bp,pawPref,...
                'maxdistperframe',maxDistPerFrame,'min_valid_p',min_valid_p,'min_certain_p',min_certain_p,'maxneighbordist',maxDistFromNeighbor_invalid);
            [invalid_direct, direct_dist_perFrame] = find_invalid_DLC_points(direct_pts, direct_p,direct_bp,pawPref,...
                'maxdistperframe',maxDistPerFrame,'min_valid_p',min_valid_p,'min_certain_p',min_certain_p,'maxneighbordist',maxDistFromNeighbor_invalid);
            
            if size(invalid_direct,2) < size(invalid3Dpoints,2)
                % make any points that aren't in a truncated video invalid
                invalid_direct(:,end+1:size(invalid3Dpoints,2)) = true;
                invalid_mirror(:,end+1:size(invalid3Dpoints,2)) = true;
            end
            invalid3Dpoints(:,:,iTrial) = invalid_direct & invalid_mirror;   % if both direct and indirect points are invalid, 3D point can't be valid
            
            if exist('manually_invalidated_points','var')
                num_frames = min(size(invalid3Dpoints,2),size(manually_invalidated_points,1));
                temp_manually_invalidated = squeeze(manually_invalidated_points(1:num_frames,:,1))' | squeeze(manually_invalidated_points(1:num_frames,:,2))';
                invalid3Dpoints(:,:,iTrial) = invalid3Dpoints(:,:,iTrial) | temp_manually_invalidated;
                invalid_direct = invalid_direct | squeeze(manually_invalidated_points(1:num_frames,:,1))';
                invalid_mirror = invalid_mirror | squeeze(manually_invalidated_points(1:num_frames,:,2))';
            end
            
            [mcpAngle,pipAngle,digitAngle,pawAngle] = determineDirectPawOrientation(final_direct_pts,direct_bp,invalid_direct,pawPref);
            if length(mcpAngle) < size(all_mcpAngle,1)
                mcpAngle(end+1:size(all_mcpAngle,1)) = 0;
                pipAngle(end+1:size(all_pipAngle,1)) = 0;
                digitAngle(end+1:size(all_digitAngle,1)) = 0;
                pawAngle(end+1:size(all_pawAngle,1)) = 0;
            end
            all_mcpAngle(:,iTrial) = mcpAngle;
            all_pipAngle(:,iTrial) = pipAngle;
            all_digitAngle(:,iTrial) = digitAngle;
            all_pawAngle(:,iTrial) = pawAngle;
            
            [~,~,~,mirror_pawdorsum_idx,~,pellet_idx,~] = group_DLC_bodyparts(mirror_bp,pawPref);
            [mcpIdx,pipIdx,digIdx,pawdorsum_idx] = findReachingPawParts(bodyparts,pawPref);
            pawParts = [mcpIdx;pipIdx;digIdx;pawdorsum_idx];
            
            [paw_through_slot_frame,firstSlotBreak,first_pawPart_outside_box,maxDigitReachFrame] = ...
                findPawThroughSlotFrame(pawTrajectory, bodyparts, pawPref, invalid_direct, invalid_mirror, reproj_error, 'slot_z',slot_z,'maxReprojError',maxReprojError);
            all_maxDigitReachFrame(iTrial) = maxDigitReachFrame;
            
            pellet_reproj_error = squeeze(reproj_error(pellet_idx,:,:));
            initPellet3D = initPelletLocation(pawTrajectory,bodyparts,frameRate,paw_through_slot_frame,pellet_reproj_error,...
                'time_to_average_prior_to_reach',time_to_average_prior_to_reach);

            if ~isempty(initPellet3D)
                % most likely, pellet wasn't brought up by the delivery arm
                % on this trial
                all_initPellet3D(iTrial,:) = initPellet3D;
            end

            pawDorsum_p = squeeze(mirror_p(mirror_pawdorsum_idx,:));
            paw_z = squeeze(pawTrajectory(:,3,pawdorsum_idx));
            pawDorsum_reproj_error = squeeze(reproj_error(pawdorsum_idx,:,:));
            firstPawDorsumFrame = findFirstPawDorsumFrame(pawDorsum_p,paw_z,paw_through_slot_frame,pawDorsum_reproj_error,...
                'pthresh',pThresh,'min_consec_frames',min_consec_frames,'max_consecutive_misses',max_consecutive_misses,...
                'slot_z',slot_z,'maxreprojerror',maxReprojError_pawDorsum);
            all_paw_through_slot_frame(iTrial) = paw_through_slot_frame;
            all_first_pawPart_outside_box(:,iTrial) = first_pawPart_outside_box;
            all_firstSlotBreak(:,iTrial) = firstSlotBreak;
            
            all_firstPawDorsumFrame(iTrial) = firstPawDorsumFrame;
            
            % 
            trajectory = trajectory_wrt_pellet(pawTrajectory, initPellet3D, reproj_error, pawPref,'maxreprojectionerror',maxReprojError);
            
            if isempty(trajectory)
                pelletMissingFlag(iTrial) = true;
                fprintf('%s, trial %d\n',sessionDirectories{iSession}, trialNumbers(iTrial,1));
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
            save(pawTrajectoryList(iTrial).name,'mcpAngle','pipAngle','digitAngle',...
                'firstPawDorsumFrame','trialOutcome','firstSlotBreak','paw_through_slot_frame','first_pawPart_outside_box',...
                'initPellet3D','-append');
        end
        
        mean_initPellet3D = nanmean(all_initPellet3D);
            
        % cycle back through the trials so that any trial where a pellet
        % wasn't grabbed, we can estimate the paw trajectory with respect
        % to where the pellet should be
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
            
            aperture = calcAperture(trajectory,bodyparts,pawPref);
            slot_z_wrt_pellet = slot_z - mean_initPellet3D(3);
            
            [partEndPts,partEndPtFrame,endPts,endPtFrame,pawPartsList] = ...
                findReachEndpoint(trajectory, bodyparts,pawPref,all_paw_through_slot_frame(iTrial),squeeze(all_isEstimate(:,:,:,iTrial)),...
                'smoothsize',smoothSize,'slot_z',slot_z_wrt_pellet);
            all_endPts(:,:,iTrial) = endPts;
            all_partEndPts(:,:,iTrial) = partEndPts;
            all_partEndPtFrame (:,iTrial) = partEndPtFrame;
            all_endPtFrame(iTrial) = endPtFrame;
            
            % in case this video is shorter than the others (happens every
            % now and then within a session)
            if size(aperture,1) < size(all_aperture,1)
                aperture(end+1:size(all_aperture,1),:) = NaN;
            end 
            all_aperture(:,:,iTrial) = aperture;
            
            num_bodyparts = length(bodyparts);
            nanTrajectory = trajectory;
            numFrames = size(nanTrajectory,1);
            
            nanTrajectory(nanTrajectory == 0) = NaN;
            distMoved = zeros(numFrames-1,num_bodyparts);

            for i_bp = 1 : num_bodyparts
                partTrajectory = squeeze(nanTrajectory(:,:,i_bp));
                distMoved(:,i_bp) = sqrt(sum(diff(partTrajectory).^2,2));
            end
            % are there frames where the paw is too big (presumably because
            % at least one of the identified points is a mistake)?
            partsTrajectory = nanTrajectory(:,:,pawParts);
            pawSpan = zeros(numFrames,1);
            maxSpanIdx = false(length(pawParts),numFrames);
            for iFrame = 1 : numFrames
                temp = squeeze(partsTrajectory(iFrame,:,:))';
                [pawSpan(iFrame),maxSpanIdx(:,iFrame)]= findFarthestPoints(temp);
            end
            
            save(pawTrajectoryList(iTrial).name,'trajectory',...
                'mcpAngle','pipAngle','digitAngle','partEndPts',...
                'partEndPtFrame','endPts','endPtFrame','pawPartsList',...
                'firstPawDorsumFrame','trialOutcome','firstSlotBreak','paw_through_slot_frame','first_pawPart_outside_box',...
                'initPellet3D','aperture','pawSpan','maxSpanIdx','distMoved','-append');
        end

        allTrajectories(allTrajectories == 0) = NaN;
        [normalized_pd_trajectories,smoothed_pd_trajectories,interp_pd_trajectories,normalized_digit_trajectories,smoothed_digit_trajectories,interp_digit_trajectories] = ...
            interpolateTrajectories(allTrajectories,pawPartsList,all_firstPawDorsumFrame,all_paw_through_slot_frame,all_endPtFrame,pawPref,...
            'num_pd_TrajectoryPoints',num_pd_TrajectoryPoints,'num_digit_TrajectoryPoints',num_digit_TrajectoryPoints,'start_z_pawdorsum',start_z_pawdorsum,'smoothwindow',smoothWindow,...
            'start_z_digits',slot_z-mean_initPellet3D(3));
        trajectoryLengths = calculateTrajectoryLengths(normalized_pd_trajectories,normalized_digit_trajectories,slot_z_wrt_pellet);
        
        sessionSummaryName = [ratID '_' sessionDateString '_kinematicsSummary.mat'];
        thisSessionType = sessionType(allSessionIdx);
        
        save(sessionSummaryName,'bodyparts','allTrajectories',...
            'normalized_pd_trajectories','normalized_digit_trajectories',...
            'smoothed_pd_trajectories','smoothed_digit_trajectories',...
            'interp_pd_trajectories','interp_digit_trajectories',...
            'all_mcpAngle','all_pipAngle','all_digitAngle','all_pawAngle','all_aperture',...
            'all_endPts','all_partEndPts','all_partEndPtFrame','pawPartsList','all_initPellet3D','trialNumbers','all_trialOutcomes',...
            'frameRate','frameTimeLimits','all_paw_through_slot_frame','all_firstSlotBreak','all_first_pawPart_outside_box',...
            'all_isEstimate','all_endPtFrame','all_firstPawDorsumFrame','all_maxDigitReachFrame',...
            'trajectoryLengths','thisRatInfo','thisSessionType','slot_z');
        
    end
    
end