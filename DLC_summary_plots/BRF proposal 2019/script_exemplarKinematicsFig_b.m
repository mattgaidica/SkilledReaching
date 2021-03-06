% script_exemplarKinematicsFig_b

rootName = 'exemplarFig';

bodypartColor.dig = [1 0 0;
                     1 0 1;
                     0 0 1;
                     0 1 0];
bodypartColor.otherPaw = [0 1 1];
bodypartColor.paw_dorsum = [0 0 0];
bodypartColor.pellet = [0 1 1];
bodypartColor.nose = [0 0 0];

traj_3D_x_lim = [-30 10];
traj_3D_y_lim = [-20 10];
full_traj_z_lim = [-15 50];

endPt_3D_x_lim = [-30 10];
endPt_3D_y_lim = [-20 10];
endPt_z_lim = [-15 30];

scale3D_length = 10;

fsize = 12;

labeledBodypartsFolder = '/Volumes/LL EXHD #2/DLC output';
rootAnalysisFolder = '/Volumes/LL EXHD #2/SR opto analysis';
vidRootPath = '/Volumes/SharedX/Neuro-Leventhal/data/Skilled Reaching/SR_Opto_Raw_Data';
alternatingStimFolder = '/Volumes/LL EXHD #2/alternating stim analysis';
ratSummaryDir = fullfile('/Volumes/LL EXHD #2/','rat kinematic summaries');
histoFolder = fullfile('/Volumes/LL EXHD #2/','SR_opto_histology','stitched_images');

saveDir = '/Volumes/SharedX/Neuro-Leventhal/analysis/';

frameTextPos = [50,30];
cropRegion = [900,450,1200,850;...   % direct view
              1,400,450,800;...     % left view
              1700,450,2040,850];   % right view
          


exemplar_vidName = 'R0230_20181027_14-13-02_026';
alternateStimRatID = 216;
alternateStimDate = datetime('20180301','inputformat','yyyyMMdd');
full_exemplar_vidName = [exemplar_vidName '.avi'];

exemplar_ratID = exemplar_vidName(1:5);
exemplar_ratIDnum = str2double(exemplar_ratID(2:end));
histo_ratID = 'R0216';

sessionDateString = exemplar_vidName(7:14);
sessionDate = datetime(sessionDateString,'inputformat','yyyyMMdd');
vidNumString = exemplar_vidName(25:27);
vidNum = str2double(vidNumString);

ratVidFolder = fullfile(vidRootPath,exemplar_ratID);
cd(ratVidFolder);
sessionVidRoot = [exemplar_ratID '_' sessionDateString '*'];
sessionVidFolder = dir(sessionVidRoot);

if isempty(sessionVidFolder)
    fprintf('no sessions for %s on %s\n',exemplar_ratID,sessionDateString);
    return
end

if length(sessionVidFolder) > 1
    fprintf('more than one session for %s on %s\n',exemplar_ratID,sessionDateString);
    return
end

exemplarVidFolder = fullfile(vidRootPath,exemplar_ratID,sessionVidFolder.name);
exemplarKinematicsFolder = fullfile(labeledBodypartsFolder,exemplar_ratID,sessionVidFolder.name);

cd(exemplarKinematicsFolder);
processed_data_root = '*_processed_reaches.mat';
processed_data_file = dir(processed_data_root);
if isempty(processed_data_file)
    fprintf('no session summary found for %s on %s\n',exemplar_ratID,sessionDateString);
    return
end

interp_data_root = '*_interp_trajectories.mat';
interp_data_file = dir(interp_data_root);
if isempty(interp_data_file)
    fprintf('no interpolated trajectories file found for %s on %s\n',exemplar_ratID,sessionDateString);
    return
end

load(processed_data_file.name);
load(interp_data_file.name);
% find the reach data for this part
pawPref = thisRatInfo.pawPref;

[reachDataIdx,trajectory_name] = identifyCorrectVidIdx(exemplar_vidName,exemplarKinematicsFolder);
load(trajectory_name);

current_reachData = reachData(reachDataIdx);
% frames_of_interest = [270,300,current_reachData.reachEnds(1)];
frames_of_interest = [current_reachData.reachEnds(1)-45,current_reachData.reachEnds(1)-15,current_reachData.reachEnds(1)];
times_of_interest = (frames_of_interest - current_reachData.reachEnds(1))/300;
cd(exemplarVidFolder);

vidObj = VideoReader(full_exemplar_vidName);

initPellet3D = all_initPellet3D(reachDataIdx,:);
interp_traj_wrt_pellet = squeeze(all_interp_traj_wrt_pellet(:,:,:,reachDataIdx));
mirror_img = cell(length(frames_of_interest),1);
direct_img = cell(length(frames_of_interest),1);
pd_traj_pts = NaN(length(frames_of_interest),3);
mcp_traj_pts = NaN(length(frames_of_interest),4,3);
dig_traj_pts = NaN(length(frames_of_interest),4,3);

[mcpIdx,pipIdx,digIdx,pawDorsumIdx] = findReachingPawParts(bodyparts,pawPref);
pd_trajectory = squeeze(interp_traj_wrt_pellet(:,:,pawDorsumIdx));
dig_trajectory = squeeze(interp_traj_wrt_pellet(:,:,digIdx));
for i_frame = 1 : length(frames_of_interest)
    
    curFrameIdx = frames_of_interest(i_frame);
    vidObj.CurrentTime = curFrameIdx / vidObj.FrameRate;
    
    curFrame = readFrame(vidObj);
    curFrame_ud = undistortImage(curFrame, activeBoxCal.cameraParams);
    
    interp_points3D = squeeze(interp_traj_wrt_pellet(curFrameIdx,:,:))';
    points3D_wrt_camera = bsxfun(@plus,interp_points3D,initPellet3D);
    direct_pt = squeeze(final_direct_pts(:,curFrameIdx,:));
    mirror_pt = squeeze(final_mirror_pts(:,curFrameIdx,:));
    frame_direct_p = squeeze(direct_p(:,curFrameIdx));
    frame_mirror_p = squeeze(mirror_p(:,curFrameIdx));
%     isPointValid{1} = ~direct_invalid_points(:,i_frame);
%     isPointValid{2} = ~mirror_invalid_points(:,i_frame);
    frameEstimate = squeeze(isEstimate(:,curFrameIdx,:));
    
    pd_traj_pts(i_frame,:) = interp_points3D(pawDorsumIdx,:);
    mcp_traj_pts(i_frame,:,:) = interp_points3D(mcpIdx,:);
    dig_traj_pts(i_frame,:,:) = interp_points3D(digIdx,:);
    curFrame_out2 = overlayDLC_for_fig(curFrame_ud, points3D_wrt_camera, ...
        direct_pt, mirror_pt, frame_direct_p, frame_mirror_p, ...
        direct_bp, mirror_bp, bodyparts, frameEstimate, ...
        activeBoxCal, pawPref,'bodypartcolor',bodypartColor);
    
    switch pawPref
        case 'left'
            mirror_img{i_frame} = curFrame_out2(cropRegion(3,2):cropRegion(3,4),cropRegion(3,1):cropRegion(3,3),:);
        case 'right'
            mirror_img{i_frame} = curFrame_out2(cropRegion(2,2):cropRegion(2,4),cropRegion(2,1):cropRegion(2,3),:);
    end
    direct_img{i_frame} = curFrame_out2(cropRegion(1,2):cropRegion(1,4),cropRegion(1,1):cropRegion(1,3),:);

end

switch pawPref
    % crop the images
    case 'left'
        full_img = [direct_img,mirror_img];
    case 'right'
        full_img = [mirror_img,direct_img];
end
clear vidObj

figProps.m = 3;
figProps.n = 3;

figProps.panelWidth = ones(figProps.n,1) * 5;
figProps.panelHeight = ones(figProps.m,1) * 4;

figProps.colSpacing = [0;0.25;0.5];
figProps.rowSpacing = ones(figProps.m-1,1) * 0.25;

figProps.topMargin = 1;
figProps.leftMargin = 1;

figProps.width = sum(figProps.panelWidth) + ...
    sum(figProps.colSpacing) + ...
    figProps.leftMargin + 2.54;
figProps.height = sum(figProps.panelHeight) + ...
    sum(figProps.rowSpacing) + ...
    figProps.topMargin + 2.54;

[h_fig,h_axes] = createFigPanels5(figProps);


cur_pd_trajectory = current_reachData.pd_trajectory{1};
cur_dig_trajectory = current_reachData.dig_trajectory{1};
switch pawPref
    case 'left'
        mirror_idx = 2;
        direct_idx = 1;
        cur_pd_trajectory(:,1) = -cur_pd_trajectory(:,1);
        cur_dig_trajectory(:,1,:) = -cur_dig_trajectory(:,1,:);
    case 'right'
        mirror_idx = 1;
        direct_idx = 2;
end

% for annotating the images at the end
frameHeight = cropRegion(1,4)-cropRegion(1,2) + 1;
for i_frame = 1 : length(frames_of_interest)
    axes(h_axes(i_frame,direct_idx))
    imshow(direct_img{i_frame});
    axes(h_axes(i_frame,mirror_idx))
    imshow(mirror_img{i_frame});
    
    axes(h_axes(i_frame,1))
%     textPos = [frameTextPos(1),(i_frame-1)*frameHeight + frameTextPos(2)];
%     textString = sprintf('frame %03d',frames_of_interest(i_frame));
    textString = sprintf('t = %.2f s',times_of_interest(i_frame));
    text(frameTextPos(1),frameTextPos(2),textString,'color','w','fontname','arial','fontsize',fsize)
end

% plot trajectory for this reach
plot_single_trajectory(current_reachData,pd_trajectory,dig_trajectory,frames_of_interest,bodypartColor,h_axes(1,3),'vieworientation',[-70,30]);
% plot_single_trajectory(current_reachData,pd_trajectory,dig_trajectory,frames_of_interest,bodypartColor,h_axes(1,4),'vieworientation',[50 20]);

% plot average 3D digit 2 endpoints for alternating session
axes(h_axes(3,3))
cd(alternatingStimFolder)
load('alternating_stim_kinematics_summary.mat');
% find the alternating_stim entry for the desired session
sessionIdx = identifyAlternateStimIdx(alternateKinematics,alternateStimRatID,alternateStimDate);

cur_alternateKinematics = alternateKinematics(sessionIdx);
on_dig2_endPts = cur_alternateKinematics.on_dig2_endPts;
off_dig2_endPts = cur_alternateKinematics.off_dig2_endPts;

for i_onBlock = 1 : size(on_dig2_endPts,1)
    cur_pts = squeeze(on_dig2_endPts(i_onBlock,:,:));
    scatter3(cur_pts(:,1),cur_pts(:,3),cur_pts(:,2),15,'marker','o','markerfacecolor','none',...
        'markeredgecolor','b');
    hold on
end

for i_offBlock = 1 : size(off_dig2_endPts,1)
    cur_pts = squeeze(off_dig2_endPts(i_offBlock,:,:));
    scatter3(cur_pts(:,1),cur_pts(:,3),cur_pts(:,2),15,'marker','o','markerfacecolor','b',...
        'markeredgecolor','b');
    hold on
end
scatter3(0,0,0,25,'marker','o','markerfacecolor',bodypartColor.pellet,'markeredgecolor','k');

line([endPt_3D_x_lim(1),endPt_3D_x_lim(1)+scale3D_length],[endPt_z_lim(2),endPt_z_lim(2)],[endPt_3D_y_lim(1),endPt_3D_y_lim(1)],'color','k','linewidth',2)
line([endPt_3D_x_lim(1),endPt_3D_x_lim(1)],[endPt_z_lim(2),endPt_z_lim(2)-scale3D_length],[endPt_3D_y_lim(1),endPt_3D_y_lim(1)],'color','k','linewidth',2)
line([endPt_3D_x_lim(1),endPt_3D_x_lim(1)],[endPt_z_lim(2),endPt_z_lim(2)],[endPt_3D_y_lim(1),endPt_3D_y_lim(1)+scale3D_length],'color','k','linewidth',2)

text(endPt_3D_x_lim(1)+scale3D_length,endPt_z_lim(2),endPt_3D_y_lim(1),'x','fontname','arial','fontsize',fsize)
text(endPt_3D_x_lim(1),endPt_z_lim(2),endPt_3D_y_lim(1)+scale3D_length,'y','fontname','arial','fontsize',fsize)
text(endPt_3D_x_lim(1),endPt_z_lim(2)-scale3D_length,endPt_3D_y_lim(1),'z','fontname','arial','fontsize',fsize)

slot_z = nanmean(cur_alternateKinematics.slot_z_wrt_pellet);
h_patch = patch([endPt_3D_x_lim(1),endPt_3D_x_lim(1),endPt_3D_x_lim(2),endPt_3D_x_lim(2)],...
                [slot_z,slot_z,slot_z,slot_z],...
                [endPt_3D_y_lim(1),endPt_3D_y_lim(2),endPt_3D_y_lim(2),endPt_3D_y_lim(1)],...
                'k','facealpha',0.1);
set(gca,'zdir','reverse','xlim',endPt_3D_x_lim,'ylim',endPt_z_lim,'zlim',endPt_3D_y_lim,...
    'view',[-70,30])
set(gca,'visible','off')


cd(ratSummaryDir)
load('experiment_summaries.mat')

plot_dig2_z_end_for_one_experiment(exptSummary(1),h_axes(2,3))
plot_dig2_z_end_for_one_experiment(exptSummary(2),h_axes(2,3))
% plot_dig2_z_end_for_one_experiment(exptSummary(3),h_axes(1,4))
xlabel('session number','fontname','arial','fontsize',fsize)
ylabel('digit 2 z-endpoint (mm)','fontname','arial','fontsize',fsize)

% plot_end_aperture_for_one_experiment(exptSummary(1),h_axes(3,3));
% plot_end_aperture_for_one_experiment(exptSummary(2),h_axes(3,3));
% xlabel('session number','fontname','arial','fontsize',fsize)
% ylabel('aperture (mm)','fontname','arial','fontsize',fsize)

% plot_aperture_trajectory_for_one_experiment(exptSummary(1),h_axes(2,4));
% xlabel('z (mm)','fontname','arial','fontsize',fsize)
% ylabel('aperture (mm)','fontname','arial','fontsize',fsize)

cd(histoFolder)
testName = [histo_ratID '_*'];
current_rat_histo = dir(testName);
hist_img = imread(current_rat_histo.name);

% axes(h_axes(1,4))
% new_hist_img = imadjust(hist_img,[0.1,0.99]);
% imshow(new_hist_img)

figName = [rootName,'.fig'];
pdfName = [rootName,'.pdf'];
epsName = [rootName,'.eps'];
pdfName = fullfile(saveDir,pdfName);
figName = fullfile(saveDir,figName);
epsName = fullfile(saveDir,epsName);
savefig(h_fig,figName);
print(h_fig,pdfName,'-dpdf');
print(h_fig,epsName,'-depsc');