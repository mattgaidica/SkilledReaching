% script_JOVE_sample_figure

bodypartColor.dig = [0 1 1;
                     1 0 0;
                     1 1 0;
                     0 1 0];
bodypartColor.otherPaw = [0 1 1];
bodypartColor.paw_dorsum = [0 0 1];
bodypartColor.pellet = [0 0 0];
bodypartColor.nose = [0.8 0.8 0.8];

% parameters for find_invalid_DLC_points
maxDistPerFrame = 30;
min_valid_p = 0.85;
min_certain_p = 0.97;
maxDistFromNeighbor_invalid = 70;

figROI = [800   500   450   400
          001   500   450   400];
ratIDnum = 284;
ratID = sprintf('R0%3d',ratIDnum);
sessionName = 'R0284_20190215a';
sessionDate = sessionName(7:14);

labeledBodypartsFolder = '/Volumes/Tbolt_01/Skilled Reaching/DLC output';
vidRootPath = fullfile('/Volumes','Tbolt_01','Skilled Reaching');
% shouldn't need this - calibration should be included in the pawTrajectory
% files
% calImageDir = '/Volumes/Tbolt_01/Skilled Reaching/calibration_images';

xlDir = '/Users/dan/Box Sync/Leventhal Lab/Skilled Reaching Project/Scoring Sheets';
xlfname = fullfile(xlDir,'rat_info_pawtracking_DL.xlsx');
csvfname = fullfile(xlDir,'rat_info_pawtracking_DL.csv');

ratInfo = readtable(csvfname);
% ratInfo = readExcelDB(xlfname, 'well learned');
ratInfo_IDs = [ratInfo.ratID];

vidNum = 9;
% template name for viable trajectory files (for searching)
trajectory_file_name = 'R*3dtrajectory_new.mat';

ratFolder = fullfile(labeledBodypartsFolder,ratID);
sessionFolder = fullfile(ratFolder,sessionName);

ratVidPath = fullfile(vidRootPath,ratID);   % root path for the original videos
vidDirectory = fullfile(ratVidPath,sessionName);

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

cd(sessionFolder)
matList = dir([ratID '_*_3dtrajectory_new.mat']);

sessionSummaryFile = sprintf('%s_%s_kinematicsSummary.mat',ratID,sessionDate);
load(sessionSummaryFile);

vidIdx = find(vidNum == trialNumbers(:,1));
load(matList(vidIdx).name);

frameList = [firstPawDorsumFrame,300,endPtFrame];

vidName = [matList(vidIdx).name(1:27) '.avi'];
fullVidName = fullfile(vidDirectory,vidName);
vidIn = VideoReader(fullVidName);

fprintf('working on session %s\n', sessionName);

[mirror_invalid_points, mirror_dist_perFrame] = find_invalid_DLC_points(mirror_pts, mirror_p,mirror_bp,pawPref,...
                'maxdistperframe',maxDistPerFrame,'min_valid_p',min_valid_p,'min_certain_p',min_certain_p);
[direct_invalid_points, direct_dist_perFrame] = find_invalid_DLC_points(direct_pts, direct_p,direct_bp,pawPref,...
                'maxdistperframe',maxDistPerFrame,'min_valid_p',min_valid_p,'min_certain_p',min_certain_p);

directImgs = zeros(figROI(1,4)+1,figROI(1,3)+1,3,length(frameList));
mirrorImgs = zeros(figROI(2,4)+1,figROI(2,3)+1,3,length(frameList));
% 
% figROI = [750   450   550   550
%           001   450   450   550];
numFrames = length(frameList);
for iFrame = 1 : numFrames
    
    curFrameNum = frameList(iFrame);
    
    vidIn.CurrentTime = (curFrameNum)/vidIn.FrameRate;
    curFrame = readFrame(vidIn);
    curFrame_ud = undistortImage(curFrame, boxCal.cameraParams);
    
    points3D = squeeze(pawTrajectory(curFrameNum,:,:))';
    direct_pt = squeeze(final_direct_pts(:,curFrameNum,:));
    mirror_pt = squeeze(final_mirror_pts(:,curFrameNum,:));
    frame_direct_p = squeeze(direct_p(:,curFrameNum));
    frame_mirror_p = squeeze(mirror_p(:,curFrameNum));
    isPointValid{1} = ~direct_invalid_points(:,curFrameNum);
    isPointValid{2} = ~mirror_invalid_points(:,curFrameNum);
    frameEstimate = squeeze(isEstimate(:,curFrameNum,:));
    
    if iFrame == 3
        connectDigits = true;
    else
        connectDigits = false;
    end
    
    [directImgs(:,:,:,iFrame),mirrorImgs(:,:,:,iFrame)] = overlayDLC_onFrame(curFrame_ud, points3D, ...
        direct_pt, mirror_pt, frame_direct_p, frame_mirror_p, ...
        direct_bp, mirror_bp, bodyparts, frameEstimate, ...
        activeBoxCal, pawPref,isPointValid,figROI,frameList(iFrame),connectDigits);
    
    
    
end

%%

% now make the figure
x_frameSpacing = 10;
y_frameSpacing = 10;
total_x = size(mirrorImgs,2) + size(directImgs,2) + x_frameSpacing;
total_y = size(mirrorImgs,1) * numFrames + y_frameSpacing * (numFrames-1);
finalImg = zeros(total_y,total_x,3);

for iFrame = 1 : numFrames
    
    mirror_left = 1;
    mirror_right = size(mirrorImgs,2);
    direct_left = size(mirrorImgs,2) + x_frameSpacing + 1;
    
    frameTop = (iFrame-1) * (size(mirrorImgs,1)+y_frameSpacing) + 1;
    frameBot = frameTop + size(mirrorImgs,1) - 1;
    finalImg(frameTop:frameBot,mirror_left:mirror_right,:) = mirrorImgs(:,:,:,iFrame);
    finalImg(frameTop:frameBot,direct_left:end,:) = directImgs(:,:,:,iFrame);
    
    
end

h_fig = figure(1);imshow(finalImg)
set(gcf,'units','inches','position',[1 1 6.5 9]);
fname = fullfile(sessionFolder, 'sampleImages');
print(h_fig,fname,'-dpdf','-r300');

savefig(h_fig,fname);

%%
% plot the average trajectories and individual trajectory for this rat

x_lim = [-30 10];
y_lim = [-20 10];
z_lim = [-10 50];

mean_pd_trajectory = nanmean(normalized_pd_trajectories,3);
numTrials = size(normalized_pd_trajectories,3);

digTrajectories = squeeze(normalized_digit_trajectories(9:12,:,:,:));
meanDigTrajectories = nanmean(digTrajectories,4);

h_fig2 = figure(2);
set(gcf,'units','centimeters','position',[1 1 8*2.54 8*2.54]);
viewOrientations = [-90,30;-10 15];
for iPlot = 1 : 2
    subplot(2,1,iPlot);
    hold off

    for iTrial = 1 : numTrials
        plot3(normalized_pd_trajectories(:,1,iTrial),normalized_pd_trajectories(:,3,iTrial),normalized_pd_trajectories(:,2,iTrial),'color',[0 0 1],'linewidth',0.25)
        hold on
        for iDig = 1 : 4
            toPlot = squeeze(digTrajectories(iDig,:,:,iTrial));
            plot3(toPlot(:,1),toPlot(:,3),toPlot(:,2),'color',bodypartColor.dig(iDig,:),'linewidth',0.25)
        end
    end

    plot3(mean_pd_trajectory(:,1),mean_pd_trajectory(:,3),mean_pd_trajectory(:,2),'linewidth',2,'color',[0 0 0]);

    for iDig = 1 : 4
        toPlot = squeeze(meanDigTrajectories(iDig,:,:));
        plot3(toPlot(:,1),toPlot(:,3),toPlot(:,2),'linewidth',2,'color',[0 0 0]);
    %     plot3(toPlot(:,1),toPlot(:,3),toPlot(:,2),'linewidth',2,'color',bodypartColor.dig(iDig,:)/2);
    end

    scatter3(0,0,0,50,'k','o','markerfacecolor','k')
    set(gca,'zdir','reverse','xlim',x_lim,'ylim',z_lim,'zlim',y_lim,...
        'view',viewOrientations(iPlot,:))
    xlabel('x (mm)');ylabel('z (mm)');zlabel('y (mm)');
    set(gca,'fontsize',20,'fontname','arial','xgrid','on','ygrid','on','zgrid','on')
end

fname = fullfile(sessionFolder, 'sampleTrajectories');
print(h_fig2,fname,'-dpdf','-r300');
savefig(h_fig2,fname);

%%
% histogram of frames at which paw is detected through the slot

sessionName1 = 'R0284_20190215a';
sessionName2 = 'R0284_20190218a';

sessionDate1 = sessionName1(7:14);
sessionDate2 = sessionName2(7:14);

ratFolder = fullfile(labeledBodypartsFolder,ratID);
sessionFolder1 = fullfile(ratFolder,sessionName1);
sessionFolder2 = fullfile(ratFolder,sessionName2);

sessionSummaryFile1 = sprintf('%s_%s_kinematicsSummary.mat',ratID,sessionDate1);
sessionSummaryFile2 = sprintf('%s_%s_kinematicsSummary.mat',ratID,sessionDate2);

sessionSummaryFile1 = fullfile(sessionFolder1,sessionSummaryFile1);
sessionSummaryFile2 = fullfile(sessionFolder2,sessionSummaryFile2);

summary{1} = load(sessionSummaryFile1);
summary{2} = load(sessionSummaryFile2);

binEdges = 250:2.5:500;
x = binEdges(1:end-1) + diff(binEdges)/2;
h_fig3 = figure(3);
hold off
plotCols = [1 0 0;0 1 0;0 0 1];
for iSession = 1 : 2
    [firstPawDorsum_n{iSession},~] = histcounts(summary{iSession}.all_firstPawDorsumFrame,binEdges);
    [paw_through_slot_n{iSession},~] = histcounts(summary{iSession}.all_paw_through_slot_frame,binEdges);
    [endPtFrame_n{iSession},~] = histcounts(summary{iSession}.all_endPtFrame,binEdges);
    
    if iSession == 1
        lineweight = 2;
        col_to_use = plotCols * 0.5;
        linestyle = '-';
    else
        lineweight = 0.5;
        col_to_use = plotCols;
        linestyle = ':';
    end
    toPlot = firstPawDorsum_n{iSession} / sum(firstPawDorsum_n{iSession});
    plot(x,toPlot,'linewidth',lineweight,'color',col_to_use(1,:),'linestyle',linestyle);
    hold on
    toPlot = paw_through_slot_n{iSession} / sum(paw_through_slot_n{iSession});
    plot(x,toPlot,'linewidth',lineweight,'color',col_to_use(2,:),'linestyle',linestyle);
    toPlot = endPtFrame_n{iSession} / sum(endPtFrame_n{iSession});
    plot(x,toPlot,'linewidth',lineweight,'color',col_to_use(3,:),'linestyle',linestyle);
    
    hold on
end
set(gca,'ylim',[0 1],'ytick',0:0.5:1,'xtick',250:50:500,'fontsize',20,'fontname','arial');
legend('first paw detection','paw through slot','max extension','location','northeast')
xlabel('frame number')
ylabel('normalized count')

fname = fullfile(sessionFolder, 'framehistograms');
print(h_fig3,fname,'-dpdf','-r300');
savefig(h_fig2,fname);
