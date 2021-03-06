function img_out = createOverlayImg(sessionName, vidNum, frameNum, bp_to_plot, varargin)
%
% INPUTS:
%
% OUTPUTS:
%
vidsRoot = fullfile('/Volumes','Tbolt_01','Skilled Reaching');
analysisRoot = '/Volumes/Tbolt_01/Skilled Reaching/DLC output';

for iarg = 1 : 2 : nargin - 4
    switch lower(varargin{iarg})
        case 'vidsroot'
            vidsRoot = varargin{iarg + 1};
        case 'analysisroot'
            analysisRoot = varargin{iarg + 1};
    end
end

ratID = sessionName(1:5);
sessionVidPath = fullfile(vidsRoot, ratID, sessionName);
sessionAnalysisPath = fullfile(analysisRoot,ratID,sessionName);

vidSearchString = sprintf('%s_*_%03d.avi',sessionName(1:end-1),vidNum);
pawTrajFileSearch = sprintf('%s_*_%03d_3dtrajectory.mat',sessionName(1:end-1),vidNum);

cd(sessionVidPath);
vidInfo = dir(vidSearchString);
video = VideoReader(vidInfo.name);

video.CurrentTime = frameNum / video.FrameRate;
img_in = readFrame(video);

cd(sessionAnalysisPath);
analysisInfo = dir(pawTrajFileSearch);
load(analysisInfo.name);
img_in = undistortImage(img_in, boxCal.cameraParams);

points3D = squeeze(pawTrajectory(frameNum,:,:))';
direct_pt = squeeze(direct_pts(:,frameNum,:));
mirror_pt = squeeze(mirror_pts(:,frameNum,:));
frame_direct_p = squeeze(direct_p(:,frameNum));
frame_mirror_p = squeeze(mirror_p(:,frameNum));

[mirror_invalid_points, ~] = find_invalid_DLC_points(mirror_pts, mirror_p);
[direct_invalid_points, ~] = find_invalid_DLC_points(direct_pts, direct_p);

isPointValid{1} = ~direct_invalid_points(:,frameNum);
isPointValid{2} = ~mirror_invalid_points(:,frameNum);


if ~iscell(bp_to_plot)
    bp_to_plot = {bp_to_plot};
end

bpIdx = zeros(length(bp_to_plot));
for ii = 1 : length(bp_to_plot)
    bpIdx(ii) = find(strcmpi(bodyparts,bp_to_plot{ii}));
end
    
img_out = overlayDLCreconstruction(img_in, points3D, direct_pt, mirror_pt,...
    frame_direct_p, frame_mirror_p, direct_bp, mirror_bp, bodyparts, isPointValid, ...
    ROIs, boxCal, thisRatInfo.pawPref, 'parts_to_show', bpIdx);




end