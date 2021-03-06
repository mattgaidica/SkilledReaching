% script to summarize data across rats

xlDir = '/Users/dan/Box Sync/Leventhal Lab/Skilled Reaching Project/Scoring Sheets';
csvfname = fullfile(xlDir,'rat_info_pawtracking_20190315.csv');

preTestingSessionsToAnalyze = 2;
pawPartIdx = 9;    % analyze tip of second digit

ratInfo = readRatInfoTable(csvfname);

labeledBodypartsFolder = '/Volumes/Tbolt_01/Skilled Reaching/DLC output';

% find rats with ChR2 and during reach stimulation
opsin = 'ChR2';
% laserTiming = 'During Reach';   % alternative is 'Between Reach'
% 
% if strcmp(laserTiming,'During Reach')
%     laserOnTiming = 'beambreak';
%     laserOffTiming = 'vidTrigger+3000';
% end
% 
% if strcmp(laserTiming,'Between Reach')
%     laserOnTiming = 'vidTrigger+4000';
%     laserOffTiming = 'laserOn+5000';
% end



numValidRats = 0;

for i_timing = 1 : 2
    switch i_timing
        case 1
            laserTiming = 'During Reach';   % alternative is 'Between Reach'
            laserOnTiming = 'beambreak';
            laserOffTiming = 'vidTrigger+3000';
            ratIDs = [186,187,189,191,193,195];
        case 2
            laserTiming = 'Between Reach';
            laserOnTiming = 'vidTrigger+4000';
            laserOffTiming = 'laserOn+5000';
            ratIDs = [197,216];
    end
    
    % generalize this later
    mean_endPoints{i_timing} = zeros(22,3,length(ratIDs));
    selectedRats = extractTableRows(ratInfo,'Virus',opsin,'laserTiming',laserTiming,'ratID',ratIDs);
    
    for i_rat = 1 : height(selectedRats)

        cd(labeledBodypartsFolder)

        ratID = selectedRats.ratID(i_rat);
        ratIDstring = sprintf('R%04d',ratID);

        if ~exist(ratIDstring,'dir')
            continue;
        end

        ratFolder = fullfile(labeledBodypartsFolder,ratIDstring);
        cd(ratFolder);

        sessionsCSVname = sprintf('%s_sessions.csv',ratIDstring);
        if ~exist(sessionsCSVname,'file')
            fprintf('No sessions info .csv file found for %s\n',ratIDstring);
            continue;
        end
        sessionsInfo = readReachingSessionTable(sessionsCSVname);

        % pull out the last preTestingSessionsToAnalyze training days
        lastTrainingDates = findFinalTrainingSessions(sessionsInfo, preTestingSessionsToAnalyze);
        laserOnDates = sessionsInfo.date(sessionsInfo.laserStim == 'on');
        occludeDates = sessionsInfo.date(sessionsInfo.laserStim == 'occlude');
        % 
        preTestingEndPoints = summarizeRatReachEndPoints(ratFolder,lastTrainingDates);
        laserOnEndPoints = summarizeRatReachEndPoints(ratFolder,laserOnDates);
        occlusionEndPoints = summarizeRatReachEndPoints(ratFolder,occludeDates);

        for ii = 1 : length(preTestingEndPoints)
            temp = squeeze(preTestingEndPoints{ii}{1}(pawPartIdx,:,:))';
            mean_endPoints{i_timing}(ii,:,i_rat) = nanmean(temp);
        end
        for ii = 1 : length(laserOnEndPoints)
            temp = squeeze(laserOnEndPoints{ii}{1}(pawPartIdx,:,:))';
            mean_endPoints{i_timing}(ii+preTestingSessionsToAnalyze,:,i_rat) = nanmean(temp);
        end
        for ii = 1 : length(occlusionEndPoints)
            temp = squeeze(occlusionEndPoints{ii}{1}(pawPartIdx,:,:))';
            mean_endPoints{i_timing}(ii+preTestingSessionsToAnalyze+10,:,i_rat) = nanmean(temp);
        end
        numValidRats = numValidRats + 1;

    end
    
end
