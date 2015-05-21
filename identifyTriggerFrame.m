function [triggerFrame, peakFrame] = identifyTriggerFrame( video, pawPref, varargin )
%
% INPUTS:
%   video - a VideoReader object for the relevant video
%
% VARARGs:
%   numbgframes - number of frames to use at the beginning of the video to
%       calculate the background
%   trigger_roi - 2 x 4 matrix containing coordinates of the region of
%       interest in which to look for the paw to determine the trigger 
%       frame
%   grylimits - 2-element vector containing the lower and upper limits of
%       the gray scale histogram to look for differences between the
%       background and trigger images
%
% OUTPUTS:
%   triggerFrame - the frame at which the paw is fully through the slot

numFrames = video.numberOfFrames;
numBGFrames = 50;
frames_before_max = 50;
grayLimit = [50 150];       % intensity values to look between for differences between background and current frame
first_diff_threshold = 50;  % minimum difference between adjacent frames

ROI_to_find_trigger_frame = [0030         0570         0120         0095
                             1880         0550         0120         0095];
for iarg = 1 : 2 : nargin - 2
    switch lower(varargin{iarg})
        case 'numbgframes',
            numBGFrames = varargin{iarg + 1};
        case 'trigger_roi',   % region of interest to look for trigger frame
            ROI_to_find_trigger_frame = varargin{iarg + 1};
        case 'grylimits',
            grayLimit = varargin{iarg + 1};
        case 'firstdiffthreshold',
            first_diff_threshold = varargin{iarg + 1};
    end
end

BGframes = uint8(zeros(numBGFrames, video.Height, video.Width, 3));
for ii = 1 : numBGFrames
    BGframes(ii,:,:,:) = read(video, ii);
end
BGimg = uint8(squeeze(mean(BGframes, 1)));

% identify the frames where the paw is visible over the shelf
if strcmpi(pawPref,'left')
    % use the right mirror for triggering
    BG_ROI = uint8(BGimg(ROI_to_find_trigger_frame(2,2):ROI_to_find_trigger_frame(2,2) + ROI_to_find_trigger_frame(2,4), ...
                         ROI_to_find_trigger_frame(2,1):ROI_to_find_trigger_frame(2,1) + ROI_to_find_trigger_frame(2,3), :));
else
    % use the left mirror for triggering
    BG_ROI = uint8(BGimg(ROI_to_find_trigger_frame(1,2):ROI_to_find_trigger_frame(1,2) + ROI_to_find_trigger_frame(1,4), ...
                         ROI_to_find_trigger_frame(1,1):ROI_to_find_trigger_frame(1,1) + ROI_to_find_trigger_frame(1,3), :));
end
BG_ROI_gry = rgb2gray(BG_ROI);
[BG_hist, histBins] = imhist(BG_ROI_gry);
binLimits = zeros(1,2);
binLimits(1) = find(abs(grayLimit(1) - histBins) == min(abs(grayLimit(1) - histBins)));
binLimits(2) = find(abs(grayLimit(2) - histBins) == min(abs(grayLimit(2) - histBins)));
BGsum = sum(BG_hist(binLimits(1):binLimits(2)));

histDiff = zeros(1, numFrames);
for iFrame = 1 : numFrames
%     iFrame
    img = read(video, iFrame);
    
    if strcmpi(pawPref,'left')
        ROI_img = img(ROI_to_find_trigger_frame(2,2):ROI_to_find_trigger_frame(2,2) + ROI_to_find_trigger_frame(2,4), ...
                      ROI_to_find_trigger_frame(2,1):ROI_to_find_trigger_frame(2,1) + ROI_to_find_trigger_frame(2,3), :);
    else
        ROI_img = img(ROI_to_find_trigger_frame(1,2):ROI_to_find_trigger_frame(1,2) + ROI_to_find_trigger_frame(1,4), ...
                      ROI_to_find_trigger_frame(1,1):ROI_to_find_trigger_frame(1,1) + ROI_to_find_trigger_frame(1,3), :);
    end

    ROI_gry = rgb2gray(ROI_img);
    ROI_hist = imhist(ROI_gry);
    ROI_sum = sum(ROI_hist(binLimits(1):binLimits(2)));
    
    histDiff(iFrame) = ROI_sum - BGsum;

end

% find frame with maximum difference between background and current frame
% in the region of interest
histDiff_delta = diff(histDiff);

triggerFrame = find(histDiff_delta > first_diff_threshold, 1, 'first') + 1;
peakFrame    = find(histDiff(triggerFrame : triggerFrame+frames_before_max) == ...
                    max(histDiff(triggerFrame : triggerFrame+frames_before_max)));
peakFrame = peakFrame + triggerFrame;

% now find the frame with the first significant deviation from baseline
figure
plot(histDiff)
hold on
plot(histDiff_delta,'r')
plot(triggerFrame, histDiff(triggerFrame),'linestyle','none','marker','*')
plot(peakFrame, histDiff(peakFrame),'linestyle','none','marker','*')