% script_collectRatSummaries_by_experiment

labeledBodypartsFolder = '/Volumes/LL EXHD #2/DLC output';
ratSummaryDir = fullfile(labeledBodypartsFolder,'rat kinematic summaries');
[plotsDir,~,~] = fileparts(labeledBodypartsFolder);
plotsDir = fullfile(plotsDir,'DLC output plots');
if ~exist(plotsDir,'dir')
    mkdir(plotsDir);
end

xlDir = '/Users/dan/Box Sync/Leventhal Lab/Skilled Reaching Project/Scoring Sheets';
csvfname = fullfile(xlDir,'rat_info_pawtracking_20190819.csv');
ratInfo = readRatInfoTable(csvfname);

experimentInfo = getExperimentFeatures();
sessions_to_analyze = getSessionsToAnalyze();

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for i_expt = 1 : length(experimentInfo)
    
    curRatList = getExptRats(ratInfo,experimentInfo(i_expt));
    
    if i_expt == 1
        % workaround for now to exclude R0185
        curRatList = curRatList(2:end,:);
    end
    if i_expt == 2
        % workaround for now to exclude R0230 until completed
        curRatList = curRatList(1:9,:);
    end
    
    % plots to make:
    %   1. plot all mean x,y,z-endpoints per session and overall mean
    %   2. plot all mean end apertures per session and overall mean
    %   3. plot all mean orientations per session and overall mean. should
    %       probably reflect the angles for left-pawed rats
    
    
    ratIDs = [curRatList.ratID];
    numRats = length(ratIDs);
%     sessionTables = cell(numRats,1);   % load in full session tables into this cell array
%     sessions_for_analysis = cell(numRats,1);   % just the sessions to analyze for this particular analysis
    for i_rat = 1 : numRats
        
        % load session info for this rat
        cd(ratSummaryDir);
        ratIDstring = sprintf('R%04d',ratIDs(i_rat));
        ratSummaryName = [ratIDstring '_kinematicsSummary.mat'];
        summary(i_rat) = load(ratSummaryName);

    end
    cur_summary = summarizeKinematicsAcrossSessionsByExperiment(summary);
    cur_summary.experimentInfo = experimentInfo(i_expt);
    
    exptSummary(i_expt) = cur_summary;
    
    plotExptSummary(exptSummary(i_expt))
    
    clear summary
    
    
end
    
    