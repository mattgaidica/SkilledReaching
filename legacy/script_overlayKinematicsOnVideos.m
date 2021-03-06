% script_overlayKinemeaticsOnVideos

labeledBodypartsFolder = '/Volumes/Tbolt_01/Skilled Reaching/DLC output';
vidRootPath = fullfile('/Volumes','Tbolt_01','Skilled Reaching');
% shouldn't need this - calibration should be included in the pawTrajectory
% files
% calImageDir = '/Volumes/Tbolt_01/Skilled Reaching/calibration_images';

script_ratInfo_for_deepcut;
ratInfo_IDs = [ratInfo.ratID];

cd(labeledBodypartsFolder)
ratFolders = dir('R*');
numRatFolders = length(ratFolders);

isPointValid = cell(1,2);

for i_rat = 1 : numRatFolders
    
    ratID = ratFolders(i_rat).name;
    ratIDnum = str2double(ratID(2:end));
    
    ratInfo_idx = find(ratInfo_IDs == ratIDnum);
    if isempty(ratInfo_idx)
        error('no entry in ratInfo structure for rat %d\n',C{1});
    end
    thisRatInfo = ratInfo(ratInfo_idx);
    pawPref = thisRatInfo.pawPref;
    
    ratRootFolder = fullfile(labeledBodypartsFolder,ratID);
    
    cd(ratRootFolder);
    
    sessionDirectories = listFolders([ratID '_*']);
    numSessions = length(sessionDirectories);
    
    ratVidPath = fullfile(vidRootPath,ratID);   % root path for the original videos
    
    for iSession = 1 : numSessions
    
        C = textscan(sessionDirectories{iSession},[ratID '_%8c']);
        sessionDate = C{1};
    
        fullSessionDir = fullfile(ratRootFolder,sessionDirectories{iSession});
        vidDirectory = fullfile(ratVidPath,sessionDirectories{iSession});
        
        cd(fullSessionDir);
        
        matList = dir([ratID '_*_3dtrajectory.mat']);
        
        for iVid = 1 : length(matList)
            
            load(matList(iVid).name);
            vidStartTime = triggerTime + frameTimeLimits(1);
            
            [mirror_invalid_points, mirror_dist_perFrame] = find_invalid_DLC_points(mirror_pts, mirror_p);
            [direct_invalid_points, direct_dist_perFrame] = find_invalid_DLC_points(direct_pts, direct_p);
            
            vidName = [matList(iVid).name(1:27) '.avi'];
            fullVidName = fullfile(vidDirectory,vidName);
            vidOutName = [matList(iVid).name(1:27) '_marked'];
            fullVidOutName = fullfile(fullSessionDir, vidOutName);
            
            vidIn = VideoReader(fullVidName);
%             vidOut = VideoWriter(fullVidOutName);
%             vidOut.FrameRate = vidIn.FrameRate;
%             open(vidOut);
            
            vidIn.CurrentTime = vidStartTime;
            
            iFrame = 1;
            while hasFrame(vidIn)
                curFrame = readFrame(vidIn);

                % need to undistort vidIn frames and points to mark
                curFrame_ud = undistortImage(curFrame, boxCal.cameraParams);

                points3D = squeeze(pawTrajectory(iFrame,:,:))';
                direct_pt = squeeze(direct_pts(:,iFrame,:));
                mirror_pt = squeeze(mirror_pts(:,iFrame,:));
                frame_direct_p = squeeze(direct_p(:,iFrame));
                frame_mirror_p = squeeze(mirror_p(:,iFrame));
                isPointValid{1} = ~direct_invalid_points(:,iFrame);
                isPointValid{2} = ~mirror_invalid_points(:,iFrame);

                curFrame_out = overlayDLCreconstruction(curFrame_ud, points3D, ...
                    direct_pt, mirror_pt, frame_direct_p, frame_mirror_p, ...
                    direct_bp, mirror_bp, bodyparts, isPointValid, ROIs, ...
                    boxCal, pawPref);
                
                % summarize how many times high probability points are
                % declared invalid
                
%                 writeVideo(vidOut,curFrame_out);
                
                iFrame = iFrame + 1; 
            end
            close(vidOut);
            
        end
        
    end
    
end