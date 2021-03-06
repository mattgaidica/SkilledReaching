% script_summaryDLCstatistics_20181129

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% set up the figures for each type of plot
% mean p heat maps
mean_p_figProps.m = 4;
mean_p_figProps.n = 2;

mean_p_figProps.panelWidth = ones(mean_p_figProps.n,1) * 9;
mean_p_figProps.panelHeight = ones(mean_p_figProps.m,1) * 5;

mean_p_figProps.colSpacing = ones(mean_p_figProps.n-1,1) * 0.5;
mean_p_figProps.rowSpacing = ones(mean_p_figProps.m-1,1) * 1;

mean_p_figProps.width = 8.5 * 2.54;
mean_p_figProps.height = 11 * 2.54;

mean_p_figProps.topMargin = 2;
mean_p_figProps.leftMargin = 2.54;

mean_p_timeLimits = [-0.5,2];

% 3D trajectories for individual trials, and mean trajectories
trajectory_figProps.m = 4;
trajectory_figProps.n = 3;

trajectory_figProps.panelWidth = ones(trajectory_figProps.n,1) * 13;
trajectory_figProps.panelHeight = ones(trajectory_figProps.m,1) * 5;

trajectory_figProps.colSpacing = ones(trajectory_figProps.n-1,1) * 0.5;
trajectory_figProps.rowSpacing = ones(trajectory_figProps.m-1,1) * 1;

trajectory_figProps.width = 20 * 2.54;
trajectory_figProps.height = 12 * 2.54;

trajectory_figProps.topMargin = 5;
trajectory_figProps.leftMargin = 2.54;

% trajectory_timeLimits = [-0.5,2];

% 2D trajectories for individual trials in direct and mirror views
trajectory2d_figProps.m = 8;
trajectory2d_figProps.n = 6;

trajectory2d_figProps.panelWidth = ones(trajectory2d_figProps.n,1) * 7;
trajectory2d_figProps.panelHeight = ones(trajectory2d_figProps.m,1) * 2.5;

trajectory2d_figProps.colSpacing = 0.5 * [0;1;0;1;0];%ones(trajectory2d_figProps.n-1,1) * 0.5;
trajectory2d_figProps.rowSpacing = [0.25;1;0.25;1;0.25;1;0.25];

trajectory2d_figProps.width = 20 * 2.54;
trajectory2d_figProps.height = 12 * 2.54;

trajectory2d_figProps.topMargin = 5;
trajectory2d_figProps.leftMargin = 2.54;

trajectory2d_figProps.fullWidth = sum(trajectory2d_figProps.panelWidth) + ...
                                  sum(trajectory2d_figProps.colSpacing) + ...
                                  trajectory2d_figProps.leftMargin;
                              
trajectory2d_figProps.fullHeight = sum(trajectory2d_figProps.panelHeight) + ...
                                      sum(trajectory2d_figProps.rowSpacing) + ...
                                      trajectory2d_figProps.topMargin;
                                  
trajectory2d_figProps.legendBot = 0.03 + (trajectory2d_figProps.fullHeight - trajectory2d_figProps.topMargin) / trajectory2d_figProps.fullHeight;
trajectory2d_figProps.legendLeft = (trajectory2d_figProps.leftMargin + (1:3) * 1.5*trajectory2d_figProps.panelWidth(1)) / trajectory2d_figProps.fullWidth;

trajectory_timeLimits = [-0.5,2];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


traj_xlim = [-30 10];
traj_ylim = [-20 60];
traj_zlim = [-20 20];

traj2D_xlim = [250 320];

bp_to_group = {{'mcp','pawdorsum'},{'pip'},{'digit'}};

labeledBodypartsFolder = '/Volumes/Tbolt_01/Skilled Reaching/DLC output';
xlDir = '/Users/dan/Box Sync/Leventhal Lab/Skilled Reaching Project/Scoring Sheets';
csvfname = fullfile(xlDir,'rat_info_pawtracking_DL.csv');
ratInfo = readtable(csvfname);
ratInfo = cleanUpRatTable(ratInfo);

ratInfo_IDs = [ratInfo.ratID];

ratFolders = findRatFolders(labeledBodypartsFolder);
numRatFolders = length(ratFolders);

for i_rat = 4 : numRatFolders
    
    ratID = ratFolders{i_rat};
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
    DLCstatsFolder = fullfile(ratRootFolder,[ratID '_DLCstats']);
    
    if ~exist(DLCstatsFolder,'dir')
        mkdir(DLCstatsFolder);
    end
    
    sessionDirectories = listFolders([ratID '_2*']);   % all were recorded after the year 2000
    numSessions = length(sessionDirectories);
    
    numSessionPages = 0;
    for iSession = 1 : numSessions
    
        C = textscan(sessionDirectories{iSession},[ratID '_%8c']);
        sessionDate = C{1};
    
        fullSessionDir = fullfile(ratRootFolder,sessionDirectories{iSession});
        
        cd(fullSessionDir);
        
        sessionSummaryName = [ratID '_' sessionDate '_kinematicsSummary.mat'];
        
        try
            load(sessionSummaryName);
        catch
%             keyboard
            fprintf('no session summary found for %s\n', sessionDirectories{iSession});
            continue
        end
        
        matList = dir([ratID '_*_3dtrajectory.mat']);
        numTrials = length(matList);
        load(matList(1).name);
%         try
%         load(matList(1).name);
%         catch
%             keyboard
%         end
        numFrames = size(allTrajectories, 1);
        t = linspace(frameTimeLimits(1),frameTimeLimits(2), numFrames);
        all_p_direct = zeros(size(direct_p,1),size(direct_p,2),numTrials);
        all_p_mirror = zeros(size(mirror_p,1),size(mirror_p,2),numTrials);
        
        currentTrialList = zeros(trajectory_figProps.m,1);
        
%         trajectory_h_figAxis = zeros(num_bp,1);
%         trajectory_h_fig = zeros(num_bp,1);
%         trajectory_h_axes = zeros(trajectory_figProps.m,trajectory_figProps.n,3);
        pdf_baseName3D = [sessionDirectories{iSession} '_3dtrajectories'];
        pdf_baseName2D = [sessionDirectories{iSession} '_2dtrajectories'];
        for iTrial = 1 : numTrials
            
            load(matList(iTrial).name);
            
            [mcp_idx,pip_idx,digit_idx,pawdorsum_idx,nose_idx,pellet_idx,otherpaw_idx] = group_DLC_bodyparts(bodyparts,pawPref);
            
            [mirror_invalid_points, ~] = find_invalid_DLC_points(mirror_pts, mirror_p);
            [direct_invalid_points, ~] = find_invalid_DLC_points(direct_pts, direct_p);

            all_p_direct(:,:,iTrial) = direct_p;
            all_p_mirror(:,:,iTrial) = mirror_p;
            
            [trial_rowNum, numTrialPages] = getRow(iTrial, trajectory_figProps.m);
            
            if trial_rowNum == 1
                [trajectory_h_fig,trajectory_h_axes] = createFigPanels5(trajectory_figProps);
                trajectory_h_figAxis = createFigAxes(trajectory_h_fig);
                
                [trajectory2d_h_fig,trajectory2d_h_axes] = createFigPanels5(trajectory2d_figProps);
                trajectory2d_h_figAxis = createFigAxes(trajectory2d_h_fig);
            end
            num_bp = size(allTrajectories,3);
            
            currentTrialList(trial_rowNum) = trialNumbers(iTrial);
            curTrajectories = squeeze(allTrajectories(:,:,:,iTrial));
            
            % find outliers and only take "final" reach points that are
            % close to the other points
            % simple way is to find the earliest point and add 10 (this is
            % arbitray) frames
%             lastPt = min(partEndPtFrame) + 10;
            lastPt = endPtFrame;
            
            for i_bpGroup = 1 : length(bp_to_group)
                
                bp_idx = [];
                partEndPtIdx = [];
                for i_bpLabel = 1 : length(bp_to_group{i_bpGroup})
                    if strcmpi(bp_to_group{i_bpGroup}{i_bpLabel},'pawdorsum')
                        if iscategorical(pawPref)
                            testString = [char(pawPref) 'pawdorsum'];
                        else
                            testString = [pawPref 'pawdorsum'];
                        end
                    else
                        testString = bp_to_group{i_bpGroup}{i_bpLabel};
                    end
                    try
                        bp_idx = [bp_idx, find(contains(bodyparts,testString))];
                    catch
                        keyboard
                    end
                    partEndPtIdx = [partEndPtIdx, find(contains(pawPartsList,testString))];
                    bpList = bodyparts(bp_idx);
                end

                axes(trajectory_h_axes(trial_rowNum,i_bpGroup))
                for ii = 1 : length(bp_idx)
%                     lastPt = partEndPtFrame(partEndPtIdx(ii));
                    if isnan(lastPt)
                        if isnan(endPtFrame)   % happens on the rare total dud video
                            continue
                        end
                        lastPt = endPtFrame;
                    end
                    toPlot = squeeze(curTrajectories(:,:,bp_idx(ii)));
                    % only plot points if both are valid
                    % these are the direct points that are OK
                    direct_nanPoints = direct_invalid_points(bp_idx(ii),:) & ~isEstimate(bp_idx(ii),:,1);
                    % these are the mirror view points that are OK
                    mirror_nanPoints = mirror_invalid_points(bp_idx(ii),:) & ~isEstimate(bp_idx(ii),:,2);
                    nanFrames = direct_nanPoints | mirror_nanPoints;
                    toPlot(nanFrames,:) = NaN;
                    toPlot = toPlot(1:lastPt,:);
                    plot3(toPlot(:,1),toPlot(:,3),toPlot(:,2))
                    hold on
                end
                
                scatter3(0,0,0,25,'k','o','markerfacecolor','k')
                if trial_rowNum == 1
                    legend(bpList)
                end
                set(gca,'zdir','reverse')
                set(gca,'xlim',traj_xlim,'ylim',traj_ylim,'zlim',traj_zlim);
                xlabel('x');ylabel('z');zlabel('y')
                
                h_leg = zeros(length(bp_idx),1);
                for ii = 1 : length(bp_idx)

                    if isnan(lastPt)
                        if isnan(endPtFrame)   % happens on the rare total dud video
                            continue
                        end
                        lastPt = endPtFrame;
                    end
                    
                    % direct x
                    axes(trajectory2d_h_axes(trial_rowNum*2-1,i_bpGroup*2-1))
%                     if bp_idx(ii) ~= pawdorsum_idx
%                         cur_direct_pts = squeeze(direct_pts(bp_idx(ii),:,:));
%                         cur_direct_pts = ROI_to_full_image(cur_direct_pts, ROIs(1,:), boxCal.cameraParams);
                        
                        cur_direct_pts = squeeze(final_direct_pts(bp_idx(ii),:,:));
                        
                        toPlot = cur_direct_pts(:,1);
                        nanPoints = direct_invalid_points(bp_idx(ii),:) & ~isEstimate(bp_idx(ii),:,1);
                        toPlot(nanPoints) = NaN;
%                         toPlot(direct_invalid_points(bp_idx(ii),:)) = NaN;
%                     else
%                         % keep from eliminating estimated paw dorsum position in direct view
%                         cur_direct_pts = final_directPawDorsum_pts;
%                         toPlot = cur_direct_pts(:,1);
%                     end
                    toPlot = toPlot(1:lastPt);
                    plot(toPlot)
                    hold on
                    if trial_rowNum == 1
                        title('direct view')
                    end
                    if i_bpGroup == 1
                        ylabel('x');
                    end
                    set(gca,'xlim',traj2D_xlim);
                    
                    % mirror x
                    axes(trajectory2d_h_axes(trial_rowNum*2-1,i_bpGroup*2))
%                     cur_mirror_pts = squeeze(mirror_pts(bp_idx(ii),:,:));
                    cur_mirror_pts = squeeze(final_mirror_pts(bp_idx(ii),:,:));
%                     cur_mirror_pts = ROI_to_full_image(cur_mirror_pts, ROIs(2,:), boxCal.cameraParams);
                    toPlot = cur_mirror_pts(:,1);
                    nanPoints = mirror_invalid_points(bp_idx(ii),:) & ~isEstimate(bp_idx(ii),:,2);
                    toPlot(nanPoints) = NaN;
%                     toPlot(mirror_invalid_points(bp_idx(ii),:)) = NaN;
                    toPlot = toPlot(1:lastPt);
                    plot(toPlot)
                    hold on
                    if trial_rowNum == 1
                        title('mirror view')
                    end
                    set(gca,'xlim',traj2D_xlim);
                    
                    if trial_rowNum == 1
                        h_leg(i_bpGroup) = legend(bpList,'location','none');
                        set(h_leg(i_bpGroup),'position',[trajectory2d_figProps.legendLeft(i_bpGroup),...
                                                trajectory2d_figProps.legendBot,0.08,0.05]);
                    end
                    
                    % direct y
                    axes(trajectory2d_h_axes(trial_rowNum*2,i_bpGroup*2-1))
                    toPlot = cur_direct_pts(:,2);
                    nanPoints = direct_invalid_points(bp_idx(ii),:) & ~isEstimate(bp_idx(ii),:,1);
                    toPlot(nanPoints) = NaN;
%                     if bp_idx(ii) ~= pawdorsum_idx   % keep from eliminating estimated paw dorsum position in direct view
%                         toPlot(direct_invalid_points(bp_idx(ii),:)) = NaN;
%                     end
                    toPlot = toPlot(1:lastPt);
                    plot(toPlot)
                    hold on
                    if i_bpGroup == 1
                        ylabel('y');
                    end
                    set(gca,'xlim',traj2D_xlim);
                    
                    % mirror_y
                    axes(trajectory2d_h_axes(trial_rowNum*2,i_bpGroup*2))
                    toPlot = cur_mirror_pts(:,2);
                    nanPoints = mirror_invalid_points(bp_idx(ii),:) & ~isEstimate(bp_idx(ii),:,2);
                    toPlot(nanPoints) = NaN;
%                     toPlot(mirror_invalid_points(bp_idx(ii),:)) = NaN;
                    toPlot = toPlot(1:lastPt);
                    plot(toPlot)
                    hold on
                    set(gca,'xlim',traj2D_xlim);
                end


                
                if (trial_rowNum == trajectory_figProps.m || ...
                    iTrial == numTrials) && ...
                    i_bpGroup == length(bp_to_group)
                   % annotate figures, save figures and close figures
                    textString{1} = sprintf('%s individual trial 3D trajectories', sessionDirectories{iSession});
                    textString{2} = sprintf('trial numbers: %d', currentTrialList(1));
                    for ii = 2 : length(currentTrialList)
                        textString{2} = sprintf('%s, %d', textString{2}, currentTrialList(ii));
                    end
                    axes(trajectory_h_figAxis);
                    text(trajectory_figProps.leftMargin,trajectory_figProps.height-0.5,textString,'units','centimeters','interpreter','none');
                    
                    pdfName3D = sprintf('%s_%02d.pdf',pdf_baseName3D,numTrialPages);
                    print(trajectory_h_fig,pdfName3D,'-dpdf');
                    close(trajectory_h_fig);
                
                    axes(trajectory2d_h_figAxis);
                    textString{1} = sprintf('%s individual trial 2D trajectories', sessionDirectories{iSession});
                    text(trajectory_figProps.leftMargin,trajectory_figProps.height-0.5,textString,'units','centimeters','interpreter','none');
                    
                    pdfName2D = sprintf('%s_%02d.pdf',pdf_baseName2D,numTrialPages);
                    print(trajectory2d_h_fig,pdfName2D,'-dpdf');
                    close(trajectory2d_h_fig);
                end
                
            % WORKING HERE - NEED TO CREATE SUMMARY FIGURES OF PAW
            % LOCATIONS, FIGURE OUT WHICH BODYPARTS WILL BE BEST FOR
            % OVERALL TRACKING - PLOT 3D AND INDIVIDUAL TRAJECTORIES ACROSS
            % SESSIONS
            
            end
            
        end
        
        mean_p_direct = mean(all_p_direct,3);
        mean_p_mirror = mean(all_p_mirror,3);
        
%         rowNum = mod(iSession, mean_p_figProps.m);
%         if rowNum == 0
%             rowNum = mean_p_figProps.m;
%         end

        [rowNum, numSessionPages] = getRow(iSession, mean_p_figProps.m);
        if rowNum == 1
            [mean_p_h_fig,mean_p_h_axes] = createFigPanels5(mean_p_figProps);
            currentSessionList = {[ratID '\_' sessionDate]};
            mean_p_h_figAxis = createFigAxes(mean_p_h_fig);
        else
            currentSessionList{rowNum} = [ratID '\_' sessionDate];
        end
        
        axes(mean_p_h_axes(rowNum,1));
        imagesc(t, 1:length(bodyparts), mean_p_direct)
        set(gca,'clim',[0 1],'xlim',mean_p_timeLimits);
        set(gca,'ytick',1:16,'yticklabel',bodyparts);
        if rowNum == 1
            title('direct');
        end
        
        axes(mean_p_h_axes(rowNum,2));
        imagesc(t, 1:length(bodyparts), mean_p_mirror)
        set(gca,'clim',[0 1],'xlim',mean_p_timeLimits,'ytick',[]);
        if rowNum == 1
            title('mirror');
        end
        
        if rowNum == mean_p_figProps.m || iSession == numSessions
            textString{1} = 'mean p-values for DLC point detection';
            textString{2} = sprintf('sessions: %s', currentSessionList{1});
            for ii = 2 : rowNum
                textString{2} = sprintf('%s, %s', textString{2},currentSessionList{ii});
            end
            
            axes(mean_p_h_figAxis);
            text(mean_p_figProps.leftMargin,mean_p_figProps.height-0.5,textString,'units','centimeters','interpreter','none');
            
%             numSessionPages = numSessionPages + 1;
            
            mean_p_summaryName = sprintf('%s_mean_p_heatmaps_%02d',ratID,numSessionPages);
            
            mean_p_summaryName = fullfile(DLCstatsFolder,mean_p_summaryName);
            mean_p_figName = [mean_p_summaryName '.fig'];
            mean_p_pdfName = [mean_p_summaryName '.pdf'];
            
            print(mean_p_pdfName, '-dpdf');
            savefig(mean_p_figName);
            
            close(mean_p_h_fig);
        end
%         set(gca,'ytick',1:16,'yticklabel',bodyparts);

        
           
    end
    
end
% mean p-value as a function of frame number