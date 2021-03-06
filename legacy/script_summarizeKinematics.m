% look at:
% 
% pathlength
% dist from pellet
% dist along z
% variance along trajectory
% movement of trajectory
% within session distance from pellet, then jump to next session

labeledBodypartsFolder = '/Volumes/Tbolt_01/Skilled Reaching/DLC output';

xlDir = '/Users/dan/Box Sync/Leventhal Lab/Skilled Reaching Project/Scoring Sheets';
xlfname = fullfile(xlDir,'rat_info_pawtracking_DL.xlsx');
csvfname = fullfile(xlDir,'rat_info_pawtracking_DL.csv');
ratInfo = readtable(csvfname);
ratInfo = cleanUpRatTable(ratInfo);

ratInfo_IDs = [ratInfo.ratID];

cd(labeledBodypartsFolder)
ratFolders = dir('R*');
numRatFolders = length(ratFolders);

for i_rat = 4 : numRatFolders
    
    ratID = ratFolders(i_rat).name
    ratIDnum = str2double(ratID(2:end));
    
    ratInfo_idx = find(ratInfo_IDs == ratIDnum);
    if isempty(ratInfo_idx)
        error('no entry in ratInfo structure for rat %d\n',C{1});
    end
    thisRatInfo = ratInfo(ratInfo_idx,:);
    pawPref = thisRatInfo.pawPref;
    
    ratRootFolder = fullfile(labeledBodypartsFolder,ratID);
    reachScoresFile = [ratID '_scores.csv'];
    reachScoresFile = fullfile(ratRootFolder,reachScoresFile);
    reachScores = readReachScores(reachScoresFile);
    
    numTableSessions = length(reachScores);
    dateNums_from_scores_table = zeros(numTableSessions,1);
    for iSession = 1 : numTableSessions
        dateNums_from_scores_table(iSession) = datenum(reachScores(iSession).date,'mm/dd/yy');
    end
        
    cd(ratRootFolder);
    sessionDirectories = dir([ratID '_2*']);
    numSessions = length(sessionDirectories);
    
    % for each session, extract distance from pellet for each digit
    %                   
    for iSession = 1 : numSessions
        
        fullSessionDir = fullfile(ratRootFolder,sessionDirectories(iSession).name)
        
        if ~isfolder(fullSessionDir)
            continue;
        end
        cd(fullSessionDir);
        C = textscan(sessionDirectories(iSession).name,[ratID '_%8c']);
        sessionDate = C{1}; % this will be in format yyyymmdd
                            % note date formats from the scores spreadsheet
                            % are in m/d/yy
                            
        sessionSummaryName = [ratID '_' sessionDate '_kinematicsSummary.mat'];
        
        if ~exist(sessionSummaryName,'file')
            continue;
        end
        
        
        
% look at:
% 
% pathlength
% dist from pellet
% dist along z
% variance along trajectory
% movement of trajectory
% within session distance from pellet, then jump to next session
