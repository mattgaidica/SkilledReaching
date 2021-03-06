function [h_figs] = plotOverallSummaryFigs(ratInfo, meanOrientations,MRL,endApertures,mean_dig_trajectories,mean_pd_trajectories,first_reachEndPoints,experimentType,sessionType,summariesFolder)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here


% WORKING HERE - NEED TO EXTRACT THE DATA FOR THE RELEVANT SESSIONS FROM
% THE RELEVANT RATS FOR EACH PLOT


labelfontsize = 24;
ticklabelfontsize = 18;

% (paw_endAngle,endApertures,mean_dig_trajectories,mean_pd_trajectories,all_reachEndPoints,experimentType,sessionType)
numRats = length(experimentType);
digitIdx = 10;
% collect all reach endpoints for each experiment type for baseline, laser
% on, and occlusion sessions


% collect all rats with ChR2 during stim
exptTable{1} = findSubTable(ratInfo,'Virus','chr2','laserTiming','during reach');
exptTable{2} = findSubTable(ratInfo,'Virus','chr2','laserTiming','between reach');
exptTable{3} = findSubTable(ratInfo,'Virus','eyfp','laserTiming','during reach');
exptTable{4} = findSubTable(ratInfo,'Virus','arch','laserTiming','during reach');

num_exptTypes = length(exptTable);
mean_endPoints = cell(num_exptTypes,1);
mean_endAngle = cell(num_exptTypes,1);
mean_MRL = cell(num_exptTypes,1);
mean_endApertures = cell(num_exptTypes,1);
numExperiments = zeros(num_exptTypes,1);

for ii = 1 : length(exptTable)
    numExperiments(ii) = sum(experimentType == ii);
    
    mean_endPoints{ii} = zeros(22,3,numExperiments(ii));   % 22 = 2 baseline sessions + 10 laser + 10 occlusion
    mean_endAngle{ii} = zeros(22,numExperiments(ii));   % 22 = 2 baseline sessions + 10 laser + 10 occlusion
    mean_MRL{ii} = zeros(22,numExperiments(ii));
    mean_endApertures{ii} = zeros(22,numExperiments(ii));
    
end
    
idx_to_collect = zeros(22,1);
expTypeIdx = zeros(num_exptTypes,1);
for i_rat = 1 : numRats

    % find the last 2 baseline sessions
    if experimentType(i_rat) == 0
        continue;
    end
    currentExpType = experimentType(i_rat);
    expTypeIdx(currentExpType) = expTypeIdx(currentExpType) + 1;
%     [baselineIdx,laserIdx,occIdx] = findSessionIndices(sessionType{i_rat});
%     idx_to_collect(1:2) = baselineIdx(end-1:end);
%     idx_to_collect(3:12) = laserIdx(1:10);
%     idx_to_collect(13:22) = occIdx(1:10);
    idx_to_collect = 1 : 22;
    for ii = 1 : length(idx_to_collect)
        cur_endPoints = squeeze(first_reachEndPoints{i_rat}{ii}{1}(digitIdx,:,:));
        mean_endPoint = nanmean(cur_endPoints,2);
        mean_endPoints{currentExpType}(ii,:,expTypeIdx(currentExpType)) = mean_endPoint;
        
        curApertures = sqrt(sum(endApertures{i_rat}{ii}.^2,2));
        mean_aperture = nanmean(curApertures);
        mean_endApertures{currentExpType}(ii,expTypeIdx(currentExpType)) = mean_aperture;
%         mean_endAngle{currentExpType}(ii,expTypeIdx(currentExpType)) = 
%         mean_MRL{currentExpType}(ii,expTypeIdx(currentExpType)) = 
    end
    
end
h_figs = plotMeanEndPoints(mean_endPoints);

end    % function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function sessionsTable = findAnalyzedRats(ratTable,summariesFolder)

numRats_in_group = size(ratTable,1);
analyzedRows = false(numRats_in_group,1);
for iRow = 1 : numRats_in_group
    
    ratID_num = ratTable(iRow).ratID;
    ratID_str = sprintf('R%04d',ratID_num);
    
    ratRootFolder = fullfile(summariesFolder,ratID_str);
    cd(ratRootFolder);
    
    % read rat summary table from this folder
    sessionsSummary_csv = sprintf('%s_sessions.csv',ratID_str);
    if exist(sessionsSummary_csv,'file')
        sessionsTable = readReachingSessionTable(sessionsSummary_csv);
    else
        continue;
    end
        
end

end
