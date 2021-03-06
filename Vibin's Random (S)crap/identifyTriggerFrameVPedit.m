function [triggerFrame,mean_BG_subt_values] = identifyTriggerFrame( video, pawPref, varargin )
%
% INPUTS:
%   video - a VideoReader object for the relevant video
%
% VARARGs:
%   numbgframes - number of frames to use at the beginning of the video to
%       calculate the background
%
% OUTPUTS:
%   triggerFrame - the frame at which the paw is fully through the slot

numFrames = video.numberOfFrames;
numBGFrames = 50;
frames_before_max = 50;

ROI_to_find_trigger_frame = [  0030         0570         0120         0095
                               1880         0550         0120         0095];
for iarg = 1 : 2 : nargin - 2
    switch lower(varargin{iarg})
        case 'numbgframes',
            numBGFrames = varargin{iarg + 1};
        case 'trigger_roi',   % region of interest to look for trigger frame
            ROI_to_find_trigger_frame = varargin{iarg + 1};
    end
end

BGframes = uint8(zeros(numBGFrames, video.Height, video.Width, 3));
for ii = 1 : numBGFrames
    BGframes(ii,:,:,:) = read(video, ii);
end
BGimg = uint8(squeeze(mean(BGframes, 1)));

% identify the frames where the paw is visible over the shelf
BG_lft = uint8(BGimg(ROI_to_find_trigger_frame(1,2):ROI_to_find_trigger_frame(1,2) + ROI_to_find_trigger_frame(1,4), ...
                     ROI_to_find_trigger_frame(1,1):ROI_to_find_trigger_frame(1,1) + ROI_to_find_trigger_frame(1,3), :));
BG_rgt = uint8(BGimg(ROI_to_find_trigger_frame(2,2):ROI_to_find_trigger_frame(2,2) + ROI_to_find_trigger_frame(2,4), ...
                     ROI_to_find_trigger_frame(2,1):ROI_to_find_trigger_frame(2,1) + ROI_to_find_trigger_frame(2,3), :));

mean_BG_subt_values = zeros(2,numFrames);
for iFrame = 1 : numFrames570+95
%     iFrame
    img = read(video, iFrame);
    
    lft_mirror_img = img(ROI_to_find_trigger_frame(1,2):ROI_to_find_trigger_frame(1,2) + ROI_to_find_trigger_frame(1,4), ...
                         ROI_to_find_trigger_frame(1,1):ROI_to_find_trigger_frame(1,1) + ROI_to_find_trigger_frame(1,3), :);
    rgt_mirror_img = img(ROI_to_find_trigger_frame(2,2):ROI_to_find_trigger_frame(2,2) + ROI_to_find_trigger_frame(2,4), ...
                         ROI_to_find_trigger_frame(2,1):ROI_to_find_trigger_frame(2,1) + ROI_to_find_trigger_frame(2,3), :);
                
%     lft_mirror_img = rgb2gray(lft_mirror_img);
%     rgt_mirror_img = rgb2gray(rgt_mirror_img);
    
    lft_mirror_BG = imabsdiff(lft_mirror_img, BG_lft);
    rgt_mirror_BG = imabsdiff(rgt_mirror_img, BG_rgt);
    
	lft_mirror_gry = rgb2gray(lft_mirror_BG);
    rgt_mirror_gry = rgb2gray(rgt_mirror_BG);
    
    lft_values = reshape(lft_mirror_gry, [1, numel(lft_mirror_gry)]);
    rgt_values = reshape(rgt_mirror_gry, [1, numel(rgt_mirror_gry)]);
    mean_BG_subt_values(1, iFrame) = mean(lft_values);
    mean_BG_subt_values(2, iFrame) = mean(rgt_values);
    %assignin('base','mean_BG_subt_values',mean_BG_subt_values);
    
end

if strcmpi(pawPref,'left')
    % use the right mirror for triggering
    mirror_idx = 2;
else
    % use the left mirror for triggering
    mirror_idx = 1;
end

% find frame with maximum difference between background and current frame
% in the region of interest
diffFrame_delta = diff(mean_BG_subt_values(mirror_idx,:));
maxDiffFrame = find(mean_BG_subt_values(mirror_idx,:) == max(mean_BG_subt_values(mirror_idx,:)));
maxDeltaFrame = find(diffFrame_delta(maxDiffFrame-frames_before_max:maxDiffFrame) == ...
                     max(diffFrame_delta(maxDiffFrame-frames_before_max:maxDiffFrame)));
triggerFrame = maxDeltaFrame + (maxDiffFrame-frames_before_max);
% now find the frame with the first significant deviation from baseline
% figure
% plot(mean_BG_subt_values(1,:))
% hold on
% plot(mean_BG_subt_values(2,:),'r')
% plot(triggerFrame, mean_BG_subt_values(mirror_idx,triggerFrame),'linestyle','none','marker','*')