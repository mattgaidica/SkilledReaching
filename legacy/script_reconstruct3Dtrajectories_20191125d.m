% script to perform 3D reconstruction on videos

% slot_z = 200;    % distance from camera of slot in mm. hard coded for now
% time_to_average_prior_to_reach = 0.1;   % in seconds, the time prior to the reach over which to average pellet location

camParamFile = '/Users/dan/Documents/Leventhal lab github/SkilledReaching/Manual Tracking Analysis/ConvertMarkedPointsToReal/cameraParameters.mat';
% camParamFile = '/Users/dleventh/Box Sync/Leventhal Lab/Skilled Reaching Project/multiview geometry/cameraParameters.mat';
load(camParamFile);

% parameter for calc3D_DLC_trajectory_20181204
maxDistFromNeighbor = 40;   % maximum distance an estimated point can be from its neighbor
maxReprojError = 10;

% parameters for find_invalid_DLC_points
maxDistPerFrame = 30;
min_valid_p = 0.85;
min_certain_p = 0.97;
maxDistFromNeighbor_invalid = 70;

xlDir = '/Users/dan/Box Sync/Leventhal Lab/Skilled Reaching Project/Scoring Sheets';
% xlfname = fullfile(xlDir,'rat_info_pawtracking_DL.xlsx');
csvfname = fullfile(xlDir,'rat_info_pawtracking_DL.csv');

ratInfo = readtable(csvfname);
ratInfo_IDs = [ratInfo.ratID];

labeledBodypartsFolder = '/Volumes/Tbolt_01/Skilled Reaching/DLC output';
calImageDir = '/Volumes/Tbolt_01/Skilled Reaching/calibration_images';

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CHANGE THESE LINES DEPENDING ON PARAMETERS USED TO EXTRACT VIDEOS
% change this if the videos were cropped at different coordinates
vidROI = [750,450,550,550;
          1,450,450,400;
          1650,435,390,400];
triggerTime = 1;    % seconds
frameTimeLimits = [-1,3.3];    % time around trigger to extract frames
frameRate = 300;

frameSize = [1024,2040];
% would be nice to have these parameters stored with DLC output so they can
% be read in directly. Might they be in the .h files?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      
cd(labeledBodypartsFolder)
ratFolders = dir('R*');
numRatFolders = length(ratFolders);

vidView = {'direct','right','left'};
numViews = length(vidView);

% find the list of calibration files
cd(calImageDir);
calFileList = dir('SR_boxCalibration_*.mat');
calDateList = cell(1,length(calFileList));
calDateNums = zeros(length(calFileList),1);
for iFile = 1 : length(calFileList)
    C = textscan(calFileList(iFile).name,'SR_boxCalibration_%8c.mat');
    calDateList{iFile} = C{1};
    calDateNums(iFile) = str2double(calDateList{iFile});
end

for i_rat = 4 : numRatFolders
% for i_rat = 8 : numRatFolders

    ratID = ratFolders(i_rat).name;
    ratIDnum = str2double(ratID(2:end));
    
    ratInfo_idx = find(ratInfo_IDs == ratIDnum);
    if isempty(ratInfo_idx)
        error('no entry in ratInfo structure for rat %d\n',C{1});
    end
    if istable(ratInfo)
        thisRatInfo = ratInfo(ratInfo_idx,:);
    else
        thisRatInfo = ratInfo(ratInfo_idx);
    end
    if iscell(thisRatInfo.pawPref)
        pawPref = thisRatInfo.pawPref{1};
    else
        pawPref = thisRatInfo.pawPref;
    end
    
    ratRootFolder = fullfile(labeledBodypartsFolder,ratID);
    
    cd(ratRootFolder);
    
%     sessionDirectories = dir([ratID '_*']);
    sessionDirectories = listFolders([ratID '_2*']);
    numSessions = length(sessionDirectories);
    
    if i_rat == 6
        startSession = 4;
    else
        startSession = 4;
    end
    for iSession = startSession : 4 : numSessions
        
        C = textscan(sessionDirectories{iSession},[ratID '_%8c']);
        sessionDate = C{1};
        
        fprintf('working on session %s_%s\n',ratID,sessionDate);
        
        % find the calibration file for this date
        % find the calibration file
        cd(calImageDir);
        curDateNum = str2double(sessionDate);
        dateDiff = curDateNum - calDateNums;

        % find the most recent date compared to the current file for which a
        % calibration file exists. Later, write code so files are stored by
        % date so that this file can be found before entering the loop through
        % DLC csv files

        lastValidCalDate = min(dateDiff(dateDiff >= 0));
            
        calFileIdx = find(dateDiff == lastValidCalDate);

    %     calibrationFileName = ['SR_boxCalibration_' directVidDate{i_directcsv} '.mat'];
        calibrationFileName = ['SR_boxCalibration_' calDateList{calFileIdx} '.mat'];
        if exist(calibrationFileName,'file')
            boxCal = load(calibrationFileName);
        else
            error('no calibration file found on or prior to %s\n',directVidDate{i_directcsv});
        end
        
        switch pawPref
            case 'right'
                ROIs = vidROI(1:2,:);
                Pn = squeeze(boxCal.Pn(:,:,2));
                sf = mean(boxCal.scaleFactor(2,:));
                F = squeeze(boxCal.F(:,:,2));
            case 'left'
                ROIs = vidROI([1,3],:);
                Pn = squeeze(boxCal.Pn(:,:,3));
                sf = mean(boxCal.scaleFactor(3,:));
                F = squeeze(boxCal.F(:,:,3));
        end
    
%         fullSessionDir = fullfile(ratRootFolder,sessionDirectories(iSession).name);
        fullSessionDir = fullfile(ratRootFolder,sessionDirectories{iSession});
        cd(fullSessionDir);
        
%         directViewDir = fullfile(fullSessionDir, [sessionDirectories(iSession).name '_direct']);
        directViewDir = fullfile(fullSessionDir, [sessionDirectories{iSession} '_direct']);
        
        cd(directViewDir);
        direct_csvList = dir('R*.csv');
        if isempty(direct_csvList)
            continue;
        end
        
        numMarkedVids = length(direct_csvList);
        % ratID, date, etc. for each individual video
        directVidTime = cell(1, numMarkedVids);
        directVidNum = zeros(numMarkedVids,1);

        % find all the direct view videos that are available
        uniqueDateList = {};
        for ii = 1 : numMarkedVids   
            C = textscan(direct_csvList(ii).name,'R%04d_%8c_%8c_%03d');

            directVid_ratID(ii) = C{1};
            directVidDate{ii} = C{2};
            directVidTime{ii} = C{3};
            directVidNum(ii) = C{4};

            if isempty(uniqueDateList)
                uniqueDateList{1} = directVidDate{ii};
            elseif ~any(strcmp(uniqueDateList,directVidDate{ii}))
                uniqueDateList{end+1} = directVidDate{ii};
            end
        end
    
%         sessionViewDirs = dir([sessionDirectories(iSession).name '_*']);
%         sessionViewDirs = listFolders([sessionDirectories{iSession} '_*']);
        cd(fullSessionDir);
        for iView = 1 : numViews
%             possibleMirrorDir = [sessionDirectories(iSession).name '_' vidView{iView}];
            possibleMirrorDir = [sessionDirectories{iSession} '_' vidView{iView}];
            if ~exist(possibleMirrorDir,'dir') || contains(lower(possibleMirrorDir),'direct')
                % if this view doesn't exist or if it's the direct view, skip
                % forward (already found the direct view files)
                continue;
            end
            mirViewFolder = fullfile(fullSessionDir, possibleMirrorDir);
            break
        end

        cd(mirViewFolder)
        mirror_csvList = dir('R*.csv');

        for i_mirrorcsv = 1 : length(mirror_csvList)

            % make sure we have matching mirror and direct view files
            C = textscan(mirror_csvList(i_mirrorcsv).name,'R%04d_%8c_%8c_%03d');
            foundMatch = false;
            for i_directcsv = 1 : numMarkedVids
                if C{1} == ratIDnum && ...      % match ratID
                   strcmp(C{2}, sessionDate) && ...  % match date
                   strcmp(C{3}, directVidTime{i_directcsv}) && ...  % match time
                   C{4} == directVidNum(i_directcsv)                % match vid number
                    foundMatch = true;
                    break;
                end
            end
            if ~foundMatch
                continue;
            end

%             trajName = sprintf('R%04d_%s_%s_%03d_3dtrajectory.mat', directVid_ratID(i_directcsv),...
%                 directVidDate{i_directcsv},directVidTime{i_directcsv},directVidNum(i_directcsv));
            trajName = sprintf('R%04d_%s_%s_%03d_3dtrajectory_new.mat', directVid_ratID(i_directcsv),...
                directVidDate{i_directcsv},directVidTime{i_directcsv},directVidNum(i_directcsv));
            fullTrajName = fullfile(fullSessionDir, trajName);
            
%             COMMENT THIS BACK IN TO AVOID REPEAT CALCULATIONS
%             if exist(fullTrajName,'file')
%                 % already did this calculation
%                 continue;
%             end
            
            cd(mirViewFolder)
            [mirror_bp,mirror_pts,mirror_p] = read_DLC_csv(mirror_csvList(i_mirrorcsv).name);
            cd(directViewDir)
            [direct_bp,direct_pts,direct_p] = read_DLC_csv(direct_csvList(i_directcsv).name);
    
            numDirectFrames = size(direct_p,1);
            numMirrorFrames = size(mirror_p,1);
    
            if numDirectFrames ~= numMirrorFrames
                fprintf('number of frames in the direct and mirror views do not match for %s\n', direct_csvList(i_directcsv).name);
            end
    
            [invalid_mirror, mirror_dist_perFrame] = find_invalid_DLC_points(mirror_pts, mirror_p,mirror_bp,pawPref,...
                'maxdistperframe',maxDistPerFrame,'min_valid_p',min_valid_p,'min_certain_p',min_certain_p,'maxneighbordist',maxDistFromNeighbor_invalid);
            [invalid_direct, direct_dist_perFrame] = find_invalid_DLC_points(direct_pts, direct_p,direct_bp,pawPref,...
                'maxdistperframe',maxDistPerFrame,'min_valid_p',min_valid_p,'min_certain_p',min_certain_p,'maxneighbordist',maxDistFromNeighbor_invalid);
                                  
            direct_pts_ud = reconstructUndistortedPoints(direct_pts,ROIs(1,:),boxCal.cameraParams,~invalid_direct);
            mirror_pts_ud = reconstructUndistortedPoints(mirror_pts,ROIs(2,:),boxCal.cameraParams,~invalid_mirror);

            boxCal_fromVid = calibrateBoxFromDLCoutput(direct_pts_ud,mirror_pts_ud,direct_p,mirror_p,invalid_direct,invalid_mirror,direct_bp,mirror_bp,cameraParams,boxCal,pawPref);
            
            [pawTrajectory, bodyparts, final_direct_pts, final_mirror_pts, isEstimate] = ...
                calc3D_DLC_trajectory_20181204(direct_pts_ud, ...
                                      mirror_pts_ud, invalid_direct, invalid_mirror,...
                                      direct_bp, mirror_bp, ...
                                      vidROI, boxCal_fromVid, pawPref, frameSize,...
                                      'maxdistfromneighbor',maxDistFromNeighbor);
                                  
            [reproj_error,high_p_invalid,low_p_valid] = assessReconstructionQuality(pawTrajectory, final_direct_pts, final_mirror_pts, direct_p, mirror_p, invalid_direct, invalid_mirror, direct_bp, mirror_bp, bodyparts, boxCal_fromVid, pawPref);
            
%             [paw_through_slot_frame,firstSlotBreak] = findPawThroughSlotFrame(pawTrajectory, bodyparts, pawPref, invalid_direct, invalid_mirror, reproj_error, 'slot_z',slot_z,'maxReprojError',maxReprojError);
%             initPellet3D = initPelletLocation(pawTrajectory,bodyparts,frameRate,paw_through_slot_frame,...
%                 'time_to_average_prior_to_reach',time_to_average_prior_to_reach);
            cd(fullSessionDir)
            
%             if exist(trajName,'file')
%                 save(trajName, 'pawTrajectory', 'bodyparts','thisRatInfo','frameRate','triggerTime','frameTimeLimits','ROIs','boxCal','direct_pts','mirror_pts','mirror_bp','direct_bp','mirror_p','direct_p','dist_from_epipole','lastValidCalDate','-append');
%             else
%                 save(fullTrajName, 'pawTrajectory', 'bodyparts','thisRatInfo','frameRate','frameSize','triggerTime','frameTimeLimits','ROIs','boxCal','direct_pts','mirror_pts','mirror_bp','direct_bp','mirror_p','direct_p','lastValidCalDate','final_direct_pts','final_mirror_pts','isEstimate','firstSlotBreak','initPellet3D','reproj_error','high_p_invalid','low_p_valid','paw_through_slot_frame');
                save(fullTrajName, 'pawTrajectory', 'bodyparts','thisRatInfo','frameRate','frameSize','triggerTime','frameTimeLimits','ROIs','boxCal','boxCal_fromVid','direct_pts','mirror_pts','mirror_bp','direct_bp','mirror_p','direct_p','lastValidCalDate','final_direct_pts','final_mirror_pts','isEstimate','reproj_error','high_p_invalid','low_p_valid');
%             end
            
        end
        
    end
    
end
% USE REPROJECTION ERROR TO INVALIDATE POINTS BEFORE ESTIMATING HIDDEN
% LOCATION

% WORK ON PAW DORSUM RECONSTRUCTION IN DIRECT VIEW - SOMETIMES WOBBLES...
% SEE RAT 187, SESSION 1, VID 1 AROUND FRAME 265 (I THINK)


% RUN script_calculateKinematics 
% then run script_summaryDLCstatistics


% MODIFY ESTIMATEHIDDENPOINTS SO THAT ESTIMATED POINTS CAN'T BE TOO FAR
% FROM THE REST OF THE PAW

