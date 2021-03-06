% script_calculateKinematics


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

labeledBodypartsFolder = '/Volumes/Tbolt_01/Skilled Reaching/DLC output';
% shouldn't need this - calibration should be included in the pawTrajectory
% files
% calImageDir = '/Volumes/Tbolt_01/Skilled Reaching/calibration_images';

cd(labeledBodypartsFolder)
ratFolders = dir('R*');
numRatFolders = length(ratFolders);

vidView = {'direct','right','left'};
numViews = length(vidView);

for i_rat = 1 : numRatFolders

    ratID = ratFolders(i_rat).name;
    ratIDnum = str2double(ratID(2:end));
    
    csvScoreName = [ratID '_scores_auto.csv'];
    
%     ratInfo_idx = find(ratInfo_IDs == ratIDnum);
%     if isempty(ratInfo_idx)
%         error('no entry in ratInfo structure for rat %d\n',C{1});
%     end
%     thisRatInfo = ratInfo(ratInfo_idx);
%     pawPref = thisRatInfo.pawPref;
    
    ratRootFolder = fullfile(labeledBodypartsFolder,ratID);
    
    cd(ratRootFolder);
    
    sessionDirectories = dir([ratID '_*']);
    numSessions = 0;
    sessionList = {};
    for ii = 1 : length(sessionDirectories)
        if isfolder(sessionDirectories(ii).name)
            numSessions = numSessions + 1;
            sessionList{numSessions} = sessionDirectories(ii).name;
        end
    end
%     numSessions = length(sessionDirectories);
    
    sessionDate = cell(numSessions,1);
    sessionDateNums = zeros(1,numSessions);
    maxTrialNumber = 0;
    trialOutcomes = cell(1,numSessions);
    for iSession = 1 : numSessions
        
%         fullSessionDir = fullfile(ratRootFolder,sessionDirectories(iSession).name);
        fullSessionDir = fullfile(ratRootFolder,sessionList{iSession});
        C = textscan(sessionList{iSession},[ratID '_%8c']);
%         sessionDate{iSession} = datestr(datenum(C{1},'yyyymmdd'),'mm/dd/yy');
        sessionDateNums(iSession) = str2double(C{1});
        cd(fullSessionDir);
        
        % find the pawTrajectory files
        pawTrajectoryList = dir('R*3dtrajectory.mat');
        
        % find the largest video number
        numTrials = length(pawTrajectoryList);
        trialNumbers = zeros(numTrials,1);
        for iTrial = 1 : numTrials
            C = textscan(pawTrajectoryList(iTrial).name,[ratID '_%8c_%8c_%03d_3dtrajectory.mat']);
            trialNumbers(iTrial) = C{3};
        end
        if max(trialNumbers) > maxTrialNumber
            maxTrialNumber = max(trialNumbers);
        end
        trialOutcomes{iSession} = NaN(max(trialNumbers),1);
        for iTrial = 1 : numTrials
            
            load(pawTrajectoryList(iTrial).name);
            trialOutcomes{iSession}(trialNumbers(iTrial)) = determineTrialOutcome(pawTrajectory,bodyparts,direct_pts,direct_bp,direct_p,ROIs,frameRate,frameTimeLimits,triggerTime);
%             trialOutcomeMatrix(trialNumbers(iTrial),iSession) = determineTrialOutcome(pawTrajectory,bodyparts,direct_pts,direct_bp,direct_p,ROIs,frameRate,frameTimeLimits,triggerTime);
            
        end
        
        cd(ratRootFolder);
%         if exist(csvScoreName,'file')
%             [status,sheets] = xlsfinfo(xlScoreName);
%             numSheets = length(sheets);
%         else
%             numSheets = 0;
%         end
%         matrixToWrite = [
%         xlswrite(xlScoreName,sessionDate,numSheets+1,'A1');
%         xlswrite(xlScoreName,1:numSessions,numSheets+1,'A3');
        
    end
    
    trialOutcomeMatrix = NaN(maxTrialNumber,numSessions+1);
    trialOutcomeMatrix(:,1) = 1:size(trialOutcomeMatrix,1);
    for iSession = 1 : numSessions
        trialOutcomeMatrix(1:length(trialOutcomes{iSession}),iSession+1) = ...
            trialOutcomes{iSession};
    end
    dlmwrite(csvScoreName,sessionDateNums,'delimiter',',',...
        'roffset',0,'coffset',1,'precision',8);
    dlmwrite(csvScoreName,1:length(sessionDateNums),'-append','roffset',0,'coffset',1);
    dlmwrite(csvScoreName,trialOutcomeMatrix,'-append');
    
    
end