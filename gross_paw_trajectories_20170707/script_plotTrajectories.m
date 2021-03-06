% script_analyze_3Dtrajectories

sr_ratInfo = get_sr_RatList();

computeCamParams = false;
camParamFile = '/Users/dan/Documents/Leventhal lab github/SkilledReaching/Manual Tracking Analysis/ConvertMarkedPointsToReal/cameraParameters.mat';
cb_path = '/Users/dan/Documents/Leventhal_lab_github/SkilledReaching/tattoo_track_testing/intrinsics calibration images';

load(camParamFile);
K = cameraParams.IntrinsicMatrix; 

sr_ratInfo = get_sr_RatList();
kinematics_rootDir = '/Users/dan/Box Sync/Leventhal Lab/Skilled Reaching Project/Matlab Kinematics/PlotGrossTrajectory';

xl_directory = '/Users/dan/Box Sync/Leventhal Lab/Skilled Reaching Project/SR_box_matched_points';
xlName = 'rubiks_matched_points_DL.xlsx';

markerSize = 1;

h = 1086; w = 2040;

for i_rat = 1 : 4%length(sr_ratInfo)
    
    ratID = sr_ratInfo(i_rat).ID;
    rawData_parentDir = sr_ratInfo(i_rat).directory.rawdata;
    processed_parentDir = sr_ratInfo(i_rat).directory.processed;
    
    matchedPoints = read_xl_matchedPoints_rubik( ratID, ...
                                                 'xldir', xl_directory, ...
                                                 'xlname', xlName);
    
    pawPref = sr_ratInfo(i_rat).pawPref;
    
    sessionList = sr_ratInfo(i_rat).sessionList;
    numSessions = length(sessionList);
    for iSession = 1 : numSessions

        sessionName = sessionList{iSession};
        fullSessionName = [ratID '_' sessionName];
        
        sessionDate = sessionName(1:8);
        shortDate = sessionDate(5:end);
        
        cd(rawData_parentDir);
        rawDataDirList = [ratID '_' sessionDate '*'];
        rawDataDirList = dir(rawDataDirList);
        if isempty(rawDataDirList)
            fprintf('no data folder for %s, %s\n',ratID, sessionDate)
            continue 
        end
        if length(rawDataDirList) > 1
            fprintf('more than one data folder for %s, %s\n', ratID, sessionDate)
            continue;
        end
        
        if (strcmp(sessionName,'20140528a') && i_rat == 1) || ...
           (strcmp(sessionName,'20140427a') && i_rat == 2)
            session_mp = matchedPoints.([fullSessionName(1:end-1) 'a']);
        elseif isfield(matchedPoints,fullSessionName(1:end-1))
            session_mp = matchedPoints.(fullSessionName(1:end-1));
        else
            continue;
        end
        boxRegions = boxRegionsfromMatchedPoints(session_mp, [h,w]);
        session_srCal = sr_calibration_mp(session_mp,'intrinsicmatrix',K);
        
        rawDataDir = fullfile(rawData_parentDir, rawDataDirList.name);
        processedDir = fullfile(processed_parentDir, rawDataDirList.name);
        
        cd(rawDataDir);
        vidList = dir('*.avi');
        
        cd(processedDir);
        matList = dir('*3dpoints.mat');
        if isempty(matList);continue;end
        
        cd(rawDataDir);
        vidBaseName = [ratID '_' sessionDate '*.avi'];
        vidList = dir(vidBaseName);
        vidListNumbers = zeros(1,length(vidList));
        for ii = 1 : length(vidList)
            vidListNumbers(ii) = str2double(vidList(ii).name(25:27));
        end
        
        for iMat = 1 : length(matList)
            if strcmp(matList(iMat).name(1:2),'._');continue;end
            testMat = load(matName);
            
            trialNumStr = matList(iMat).name(16:18);
            trialNum = str2double(trialNumStr);
            
            numFrames = length(testMat.points3d);
            
            vidNameIdx = (vidListNumbers == trialNum);
            
            current_vidName = vidList(vidNameIdx).name;
            current_vidName = fullfile(rawDataDir,current_vidName);
            
            video = VideoReader(current_vidName);
            
            frameRate = video.FrameRate;
            break;
        end
        sessionTrajectories = zeros(length(matList), numFrames, 3);
        
        trajectories3D = NaN(length(matList),numFrames,3);
        triggerTimes = NaN(length(matList,1));
        for iMat = 1 : length(matList)   
            fprintf('%s, %s, video %d of %d, %s\n', ratID, sessionDate, iMat, length(matList), matList(iMat).name);
            
            if strcmp(matList(iMat).name(1:2),'._');continue;end
            
            trialNumStr = matList(iMat).name(16:18);
            trialNum = str2double(trialNumStr);
            
            matBaseName = matList(iMat).name(1:18);
            
            matName = fullfile(processedDir,matList(iMat).name);
            traj3d = load(matName);
%             points3d = traj3d.points3d;
            
            if ~isfield(traj3d, 'mean3Dtrajectory'); continue; end
            track_metadata = traj3d.track_metadata;
            trajectories3D(iMat,:,:) = traj3d.mean3Dtrajectory;
            
            triggerTimes(iMat) = traj3d.track_metadata.triggerTime;
        end
        
        smoothed_trajectories = smooth_and_align_Trajectory(trajectories3D, triggerTimes, frameRate, session_mp);
            
        %  WORKING HERE!!!
            
            
        end
        
    end
    
end
            
            