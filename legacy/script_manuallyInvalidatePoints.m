% script_manuallyInvalidatePoints

trajectory_file_name = 'R*3dtrajectory_new.mat';

max3Ddist_perFrame = 10;   % mm
maxPawSpan = 22;

maxDistPerFrame = 30;
min_valid_p = 0.85;
min_certain_p = 0.97;

% whether or not to take advantage of previously invalidated points so they
% can be skipped this time through. May set to false if think a mistake was
% made previously
use_previously_invalidated_points = true;

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

labeledBodypartsFolder = '/Volumes/Tbolt_01/Skilled Reaching/DLC output';
vidRootPath = fullfile('/Volumes','Tbolt_01','Skilled Reaching');
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

for i_rat = 4 : 13%numRatFolders
    
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
    ratVidPath = fullfile(vidRootPath,ratID);   % root path for the original videos
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
    sessionDirectories = listFolders([ratID '_2*']);
    numSessions = length(sessionDirectories);
    
    sessionType = determineSessionType(thisRatInfo, allSessionDates);
    if i_rat == 4
        startSession = 10;
    else
        startSession = 1;
    end
    for iSession = startSession : numSessions
        
        fullSessionDir = fullfile(ratRootFolder,sessionDirectories{iSession})
        vidDirectory = fullfile(ratVidPath,sessionDirectories{iSession});
        
        if ~isfolder(fullSessionDir)
            continue;
        end
        cd(fullSessionDir);
        C = textscan(sessionDirectories{iSession},[ratID '_%8c']);
        sessionDateString = C{1}; % this will be in format yyyymmdd
                            % note date formats from the scores spreadsheet
                            % are in m/d/yy

        sessionDate = datetime(sessionDateString,'inputformat','yyyyMMdd');
        allSessionIdx = find(sessionDate == allSessionDates);
        sessionDateNum = datenum(sessionDateString,'yyyymmdd');
        % figure out index of reachScores array for this session

        sessionReachScores = reachScores(dateNums_from_scores_table == sessionDateNum).scores;
        
        % find the pawTrajectory files
        pawTrajectoryList = dir(trajectory_file_name);
        if isempty(pawTrajectoryList)
            continue
        end
        
        numTrials = length(pawTrajectoryList);
        
        for iTrial = 1 : numTrials
            
            load(pawTrajectoryList(iTrial).name);
            
            % find all frames/bodyparts with distMoved > max3Ddist_perFrame
            poss_pawTooLarge = pawSpan > maxPawSpan;
            poss_movedTooFar = distMoved > max3Ddist_perFrame;

            numFrames = size(direct_p,2);
            num_bodyparts = length(bodyparts);

            % if points weren't previously invalidated, or if not supposed
            % to use previously invalidated points, make a new
            % manually_invalidated_points matrix
            if ~use_previously_invalidated_points || ~exist('manually_invalidated_points','var')
                manually_invalidated_points = false(numFrames,num_bodyparts,2);
            end
                
            if any(poss_pawTooLarge) || any(poss_movedTooFar(:))   % there's at least one suspicious point...
                
                vidName = [pawTrajectoryList(iTrial).name(1:27) '.avi'];
                fullVidName = fullfile(vidDirectory,vidName);
                vidIn = VideoReader(fullVidName);


                % last dimension is to indicate whether direct view or mirror
                % view should be invalidated (first dimension for direct view,
                % second dimension for mirror view)
                
                [mirror_invalid_points, mirror_dist_perFrame] = find_invalid_DLC_points(mirror_pts, mirror_p,mirror_bp,pawPref,...
                                'maxdistperframe',maxDistPerFrame,'min_valid_p',min_valid_p,'min_certain_p',min_certain_p);
                [direct_invalid_points, direct_dist_perFrame] = find_invalid_DLC_points(direct_pts, direct_p,direct_bp,pawPref,...
                                'maxdistperframe',maxDistPerFrame,'min_valid_p',min_valid_p,'min_certain_p',min_certain_p);

                direct_invalid_points = direct_invalid_points | squeeze(manually_invalidated_points(:,:,1))';
                mirror_invalid_points = mirror_invalid_points | squeeze(manually_invalidated_points(:,:,2))';
                % note that distMoved has one fewer point than the number of
                % frames. Potential bad frames include the frame at the index
                % of poss_movedTooFar and the next one.
                for iFrame = 2 : numFrames-1
                    % not going to care about frame 1 anyway, and this way
                    % don't have to worry about indexing < 1

%                     if any(manually_invalidated_points(iFrame,:))
%                         % already identified points to skip in this frame
%                         continue;
%                     end
                    skipPossTooLarge = true;
                    skipPossTooFar = true(1,2);
                    if poss_pawTooLarge(iFrame) || any(poss_movedTooFar(iFrame,:)) || any(poss_movedTooFar(iFrame-1,:))
                        
                        if poss_pawTooLarge(iFrame)
                            max_span_bodypartidx = find(maxSpanIdx(:,iFrame));
                            temp = squeeze(manually_invalidated_points(iFrame,max_span_bodypartidx,:));
                            if any(temp(:)) % already marked this point invalid
                                skipPossTooLarge = true;
                            else
                                fprintf('large paw for frame %d, paw parts %s and %s\n', ...
                                    iFrame, bodyparts{max_span_bodypartidx(1)}, bodyparts{max_span_bodypartidx(2)});
                                skipPossTooLarge = false;
                            end
                        end
                        if any(poss_movedTooFar(iFrame,:))
%                             if any(manually_invalidated_points(iFrame+1,:))
%                                 continue;
%                             end
                            excessJumpParts_idx = find(poss_movedTooFar(iFrame,:));
                            toRemove = [];
                            for ii = 1 : length(excessJumpParts_idx)
                                temp1 = squeeze(manually_invalidated_points(iFrame,excessJumpParts_idx,:));
                                temp2 = squeeze(manually_invalidated_points(iFrame+1,excessJumpParts_idx,:));
                                if any(temp1(:)) || any(temp2(:))
                                    toRemove = [toRemove,ii];
                                end
                            end
                            excessJumpParts_idx(toRemove) = [];
                            if isempty(excessJumpParts_idx)
                                skipPossTooFar(1) = true;
                            else
                                partsString = bodyparts{excessJumpParts_idx(1)};
                                if length(excessJumpParts_idx) > 1
                                    for ii = 2 : length(excessJumpParts_idx)
                                        partsString = [partsString ', ' bodyparts{excessJumpParts_idx(ii)}];
                                    end
                                end
                                fprintf('part(s) %s jumped too far between frames %d and %d\n',...
                                    partsString, iFrame, iFrame + 1);
                                skipPossTooFar(1) = false;
                            end
                        end
                        if any(poss_movedTooFar(iFrame-1,:))
%                             if any(manually_invalidated_points(iFrame-1,:))
%                                 continue;
%                             end
                            excessJumpParts_idx = find(poss_movedTooFar(iFrame-1,:));
                            toRemove = [];
                            for ii = 1 : length(excessJumpParts_idx)
                                temp1 = squeeze(manually_invalidated_points(iFrame,excessJumpParts_idx,:));
                                temp2 = squeeze(manually_invalidated_points(iFrame-1,excessJumpParts_idx,:));
                                if any(temp1(:)) || any(temp2(:))
                                    toRemove = [toRemove,ii];
                                end
                            end
                            excessJumpParts_idx(toRemove) = [];
                            if isempty(excessJumpParts_idx)
                                skipPossTooFar(2) = true;
                            else
                                partsString = bodyparts{excessJumpParts_idx(1)};
                                if length(excessJumpParts_idx) > 1
                                    for ii = 2 : length(excessJumpParts_idx)
                                        partsString = [partsString ', ' bodyparts{excessJumpParts_idx(ii)}];
                                    end
                                end
                                fprintf('part(s) %s jumped too far between frames %d and %d\n',...
                                    partsString, iFrame-1, iFrame);
                                skipPossTooFar(2) = false;
                            end
                        end
                        
                        if skipPossTooLarge && all(skipPossTooFar)
                            continue;
                        end
                        alreadyInvalidated_direct = find(squeeze(manually_invalidated_points(iFrame,:,1)));
                        alreadyInvalidated_mirror = find(squeeze(manually_invalidated_points(iFrame,:,2)));
                        if ~isempty(alreadyInvalidated_direct)
                            invalidDirect_string = [];
                            for ii = 1 : length(alreadyInvalidated_direct)
                                invalidDirect_string = [invalidDirect_string ', ' direct_bp{alreadyInvalidated_direct(ii)}];
                            end
                            fprintf('direct points already invalidated: %s\n',invalidDirect_string);
                        end
                        if ~isempty(alreadyInvalidated_mirror)
                            invalidMirror_string = [];
                            for ii = 1 : length(alreadyInvalidated_mirror)
                                invalidMirror_string = [invalidMirror_string ', ' mirror_bp{alreadyInvalidated_mirror(ii)}];
                            end
                            fprintf('mirror points already invalidated: %s\n',invalidMirror_string);
                        end
                        % there's a concerning point in this frame
                        vidIn.CurrentTime = (iFrame)/vidIn.FrameRate;
                        % need to undistort vidIn frames and points to mark
                        curFrame = readFrame(vidIn);
                        curFrame_ud = undistortImage(curFrame, boxCal.cameraParams);
                        
                        points3D = squeeze(pawTrajectory(iFrame,:,:))';
                        direct_pt = squeeze(final_direct_pts(:,iFrame,:));
                        mirror_pt = squeeze(final_mirror_pts(:,iFrame,:));
                        frame_direct_p = squeeze(direct_p(:,iFrame));
                        frame_mirror_p = squeeze(mirror_p(:,iFrame));
                        isPointValid{1} = ~direct_invalid_points(:,iFrame);
                        isPointValid{2} = ~mirror_invalid_points(:,iFrame);
                        frameEstimate = squeeze(isEstimate(:,iFrame,:));
                        
                        curFrame_out2 = overlayDLCreconstruction_b(curFrame_ud, points3D, ...
                            direct_pt, mirror_pt, frame_direct_p, frame_mirror_p, ...
                            direct_bp, mirror_bp, bodyparts, frameEstimate, ...
                            activeBoxCal, pawPref,isPointValid);

                        figure(1)
                        imshow(curFrame_out2);
                        set(gcf,'name',sprintf('%s, frame %d',vidName,iFrame));
                        
                        keyboard
                        [invalid_pt_idx,tf] = listdlg('promptstring','INVALID DIRECT VIEW POINTS','liststring',direct_bp);
                        if tf
                            manually_invalidated_points(iFrame,invalid_pt_idx,1) = true;
                        end
                        [invalid_pt_idx,tf] = listdlg('promptstring','INVALID MIRROR VIEW POINTS','liststring',mirror_bp);
                        if tf
                            manually_invalidated_points(iFrame,invalid_pt_idx,2) = true;
                        end
                        
                        
                    end
                    
                end
                
            end    % if any(poss_pawTooLarge) || any(poss_movedTooFar(:))
            
            save(pawTrajectoryList(iTrial).name,'manually_invalidated_points','-append');
            
        end
        
    end
    
end


        %   WORKING HERE...
    