function centroids = track3Dpaw_20150831(video, ...
                                         BGimg_ud, ...
                                         refImageTime, ...
                                         initDigitMasks, ...
                                         init_mask_bbox, ...
                                         rat_metadata, ...
                                         boxCalibration, ...
                                         varargin)
%
%
%
% INPUTS:
%    video - video reader object containing the current video under
%       analysis
%    BGimg_ud - undistorted background image
%    refImageTime - time in the video at which the initial digit
%       identification was made. Plan is to track backwards and forwards in
%       time
%    initDigitMasks - cell array. initDigitMasks{1} for the left mirror,
%       initDigitMasks{2} is the direct view, initDigitMasks{3} is the
%       right mirror. These are binary masks the size of the bounding box
%       around the initial paw masking
%    init_mask_bbox - 3 x 4 matrix, where each row contains the bounding
%       box for each viewMask. Format of each row is [x,y,w,h], where x,y
%       is the upper left corner of the bounding box, and w and h are the
%       width and height, respectively
%   rat_metadata - rat metadata structure containing the following fields:
%       .ratID - integer containing the rat identification number
%       .localizers_present - boolean indicating whether or not box
%           localizers (e.g., beads/checkerboards are present in the video.
%       	probably not necessary, but will leave in for now. -DL 20150831
%       .camera_distance - camera focal length; this is now stored
%           elsewhere, will probably be able to get rid of this
%       .pawPref - string or cell containing a string 'left' or 'right'
%   boxCalibration - 
%
% VARARGS:
%
% OUTPUTS:
%

decorrStretchMean  = cell(1,3);
decorrStretchSigma = cell(1,3);
decorrStretchMean{1}  = [127.5 127.5 127.5     % to isolate dorsum of paw
                         127.5 127.5 100.0     % to isolate blue digits
                         100.0 127.5 127.5     % to isolate red digits
                         127.5 100.0 127.5     % to isolate green digits
                         100.0 127.5 127.5     % to isolate red digits
                         127.5 127.5 127.5];

decorrStretchSigma{1} = [075 075 075       % to isolate dorsum of paw
                         075 075 075       % to isolate blue digits
                         075 075 075       % to isolate red digits
                         075 075 075       % to isolate green digits
                         075 075 075       % to isolate red digits
                         075 075 075];
                     
decorrStretchMean{2}  = [127.5 127.5 127.5     % to isolate dorsum of paw
                         127.5 127.5 100.0     % to isolate blue digits
                         100.0 127.5 127.5     % to isolate red digits
                         127.5 100.0 127.5     % to isolate green digits
                         100.0 127.5 127.5     % to isolate red digits
                         127.5 127.5 127.5];
                     
decorrStretchSigma{2} = [075 075 075       % to isolate dorsum of paw
                         075 075 075       % to isolate blue digits
                         075 075 075       % to isolate red digits
                         075 075 075       % to isolate green digits
                         075 075 075       % to isolate red digits
                         075 075 075];
                     
decorrStretchMean{3}  = [127.5 127.5 127.5     % to isolate dorsum of paw
                         127.5 127.5 100.0     % to isolate blue digits
                         100.0 127.5 127.5     % to isolate red digits
                         127.5 100.0 127.5     % to isolate green digits
                         100.0 127.5 127.5     % to isolate red digits
                         127.5 127.5 127.5];
                     
decorrStretchSigma{3} = [075 075 075       % to isolate dorsum of paw
                         075 075 075       % to isolate blue digits
                         075 075 075       % to isolate red digits
                         075 075 075       % to isolate green digits
                         075 075 075       % to isolate red digits
                         075 075 075];
for ii = 1 : 3
    decorrStretchMean{ii} = decorrStretchMean{ii} / 255;
    decorrStretchSigma{ii} = decorrStretchSigma{ii} / 255;
end

HSVthresh_parameters.min_thresh(1) = 0.05;    % minimum distance hue threshold must be from mean. Note hue is circular (hue = 1 is the same as hue = 0)
HSVthresh_parameters.min_thresh(2) = 0.10;    % minimum distance saturation threshold must be from mean 
HSVthresh_parameters.min_thresh(3) = 0.05;    % minimum distance value threshold must be from mean 
HSVthresh_parameters.max_thresh(1) = 0.16;    % maximum distance hue threshold can be from mean. Note hue is circular (hue = 1 is the same as hue = 0)
HSVthresh_parameters.max_thresh(2) = 0.15;    % maximum distance saturation threshold can be from mean 
HSVthresh_parameters.max_thresh(3) = 0.30;    % maximum distance value threshold can be from mean 
HSVthresh_parameters.num_stds(1) = 5;         % number of standard deviations hue can deviate from mean (unless less than min_thresh or greater than max_thresh)
HSVthresh_parameters.num_stds(2) = 5;         % number of standard deviations saturation can deviate from mean (unless less than min_thresh or greater than max_thresh)
HSVthresh_parameters.num_stds(3) = 5;         % number of standard deviations value can deviate from mean (unless less than min_thresh or greater than max_thresh)

diff_threshold = 45;
maxDistPerFrame = 20;
% <<<<<<< HEAD
RGBradius = 0.1;
color_zlim = 2;
pthresh = 0.9;

h = video.Height;
w = video.Width;

boxMarkers = boxCalibration.boxMarkers;
F = boxCalibration.F;
P = boxCalibration.P;
K = boxCalibration.cameraParams.IntrinsicMatrix;

blueBeadMask = boxMarkers.beadMasks(:,:,3);

pawPref = lower(rat_metadata.pawPref);
if iscell(pawPref)
    pawPref = pawPref{1};
end

BGimg_info = whos('BGimg_ud');
if strcmpi(BGimg_info.class,'uint8')
    BGimg_ud = double(BGimg_ud) / 255;
end

% list of tattooed colors - first is paw dorsum, then index to pinky finger
colorList = {'darkgreen','blue','red','green','red'};
satLimits = [0.80000    1.00
             0.90000    1.00
             0.90000    1.00
             0.90000    1.00
             0.90000    1.00];
valLimits = [0.00001    0.70
             0.95000    1.00
             0.95000    1.00
             0.95000    1.00
             0.95000    1.00];
hueLimits = [0.00, 0.16;    % red
             0.33, 0.16;    % green
             0.66, 0.05;    % blue
             0.45  0.16];   % dark green
         
digitBlob = cell(1,2);
digitBlob{1} = vision.BlobAnalysis;
digitBlob{1}.AreaOutputPort = true;
digitBlob{1}.CentroidOutputPort = true;
digitBlob{1}.BoundingBoxOutputPort = true;
digitBlob{1}.ExtentOutputPort = true;
digitBlob{1}.LabelMatrixOutputPort = true;
digitBlob{1}.MinimumBlobArea = 100;
digitBlob{1}.MaximumBlobArea = 30000;

digitBlob{2} = vision.BlobAnalysis;
digitBlob{2}.AreaOutputPort = true;
digitBlob{2}.CentroidOutputPort = true;
digitBlob{2}.BoundingBoxOutputPort = true;
digitBlob{2}.ExtentOutputPort = true;
digitBlob{2}.LabelMatrixOutputPort = true;
digitBlob{2}.MinimumBlobArea = 40;
digitBlob{2}.MaximumBlobArea = 30000;

pdBlob{1} = vision.BlobAnalysis;
pdBlob{1}.AreaOutputPort = true;
pdBlob{1}.CentroidOutputPort = true;
pdBlob{1}.BoundingBoxOutputPort = true;
pdBlob{1}.ExtentOutputPort = true;
pdBlob{1}.LabelMatrixOutputPort = true;
pdBlob{1}.MinimumBlobArea = 50;
pdBlob{1}.MaximumBlobArea = 30000;

pdBlob{2} = vision.BlobAnalysis;
pdBlob{2}.AreaOutputPort = true;
pdBlob{2}.CentroidOutputPort = true;
pdBlob{2}.BoundingBoxOutputPort = true;
pdBlob{2}.ExtentOutputPort = true;
pdBlob{2}.LabelMatrixOutputPort = true;
pdBlob{2}.MinimumBlobArea = 50;
pdBlob{2}.MaximumBlobArea = 30000;

trackCheck.maxDistPerFrame = 5;    % in mm
trackCheck.maxReprojError = 0.1;   % not sure what this needs to be, will need some trial and error
% =======
% >>>>>>> origin/master
for iarg = 1 : 2 : nargin - 10
    switch lower(varargin{iarg})
        case 'graypawlimits',
            gray_paw_limits = varargin{iarg + 1};
        case 'diffthreshold',
            diff_threshold = varargin{iarg + 1};
        case 'decorrstretchmean_mirror',
            decorrStretchMean_mirror = varargin{iarg + 1};
        case 'decorrstretchsigma_mirror',
            decorrStretchSigma_mirror = varargin{iarg + 1};
        case 'decorrstretchmean_center',
            decorrStretchMean_center = varargin{iarg + 1};
        case 'decorrstretchsigma_center',
            decorrStretchSigma_center = varargin{iarg + 1};
        case 'colorlist',
            colorList = varargin{iarg + 1};
        case 'maxdistperframe',
            trackCheck.maxDistPerFrame = varargin{iarg + 1};
        case 'maxreprojerror',
            trackCheck.maxReprojError = varargin{iarg + 1};
    end
end

digitColors = unique(colorList(2:5));   % possible digit colors
if diff_threshold > 1
    diff_threshold = diff_threshold / 255;
end

[~, center_region_mask] = reach_region_mask(boxMarkers, [h,w]);

switch pawPref
    case 'left',
        dMirrorIdx = 3;   % index of mirror with dorsal view of paw
        pMirrorIdx = 1;   % index of mirror with palmar view of paw
        F_side = F.right;
        P2 = P.right;
        scale = boxCalibration.scale(2);
    case 'right',
        dMirrorIdx = 1;   % index of mirror with dorsal view of paw
        pMirrorIdx = 3;   % index of mirror with palmar view of paw
        F_side = F.left;
        P2 = P.left;
        scale = boxCalibration.scale(1);
end
trackingBoxParams.K = K;
trackingBoxParams.F = F_side;
trackingBoxParams.P1 = eye(4,3);
trackingBoxParams.P2 = P2;
trackingBoxParams.scale = scale;
[~,trackingBoxParams.epipole] = isEpipoleInImage(F_side,[size(BGimg_ud,1),size(BGimg_ud,2)]);

% make the first view the direct view, the second view is the mirror view
P1 = eye(4,3);
digitMasks = cell(2,1);
digitMasks{1} = initDigitMasks{2};
digitMasks{2} = initDigitMasks{dMirrorIdx};
mask_bbox = zeros(2,4);
mask_bbox(1,:) = init_mask_bbox(2,:);
mask_bbox(2,:) = init_mask_bbox(dMirrorIdx,:);

vidName = fullfile(video.Path, video.Name);
video = VideoReader(vidName);
video.CurrentTime = refImageTime;
image = readFrame(video);
image_ud = undistortImage(image, boxCalibration.cameraParams);
image_ud = double(image_ud) / 255;

% initialize one track each for the dorsum of the paw and each digit in the
% mirror and center views

tracks = initializeTracks();
numTracks = 0;

s = struct('Centroid', {}, ...
           'BoundingBox', {});
num_elements_to_track = size(digitMasks{2}, 3);
meanHSV = zeros(2,num_elements_to_track,3);
stdHSV = zeros(2,num_elements_to_track,3);
isVisible = false(num_elements_to_track, 2);
totalVisCount = zeros(num_elements_to_track, 2);
consecInvisibleCount = zeros(num_elements_to_track, 2);
for ii = 1 : num_elements_to_track

    for iView = 1 : 2

        temp = digitMasks{iView}(:,:,ii);
        if any(temp(:))   % the digit was found in this view
            isVisible(ii,iView) = true;
            totalVisCount(ii,iView) = totalVisCount(ii,iView) + 1;
            
            s(iView,ii) = regionprops(squeeze(digitMasks{iView}(:,:,ii)),'centroid','BoundingBox');
            s(iView,ii).Centroid = s(iView,ii).Centroid + mask_bbox(iView,1:2);
            s(iView,ii).BoundingBox(1:2) = floor(s(iView,ii).BoundingBox(1:2)) + mask_bbox(iView,1:2);
            s(iView,ii).BoundingBox(3:4) = s(iView,ii).BoundingBox(3:4) + 2;

            paw_img = image_ud(mask_bbox(iView,2) : mask_bbox(iView,2) + mask_bbox(iView,4), ...
                               mask_bbox(iView,1) : mask_bbox(iView,1) + mask_bbox(iView,3),:);
            paw_enh = enhanceColorImage(paw_img, ...
                                        decorrStretchMean{iView}(ii,:), ...
                                        decorrStretchSigma{iView}(ii,:), ...
                                        'mask', digitMasks{iView}(:,:,6));
            paw_hsv = rgb2hsv(paw_enh);
            
            [meanHSV(iView,ii,:), stdHSV(iView,ii,:)] = ...
                calcHSVstats(paw_hsv, digitMasks{iView}(:,:,ii));
            
        else
            consecInvisibleCount(ii,iView) = consecInvisibleCount(ii,iView) + 1;
            switch lower(colorList{ii}),
                case 'red',
                    colorIdx = 1;
                case 'green',
                    colorIdx = 2;
                case 'blue',
                    colorIdx = 3;
                case 'darkgreen',
                    colorIdx = 4;
            end
            meanHSV(iView,ii,1) = hueLimits(colorIdx,1);
            stdHSV(iView,ii,1) = hueLimits(colorIdx,2) / num_h_stds;
            meanHSV(iView,ii,2) = mean(satLimits(ii,:),2);
            stdHSV(iView,ii,2) = range(satLimits(ii,:)) / num_s_stds;
            meanHSV(iView,ii,3) = mean(valLimits(ii,:),2);
            stdHSV(iView,ii,3) = range(valLimits(ii,:)) / num_v_stds;
            
        end
    end
    
end

mp1 = [s(1,:).Centroid]; mp2 = [s(2,:).Centroid];
mp1 = reshape(mp1,[2 num_elements_to_track])';
mp2 = reshape(mp2,[2 num_elements_to_track])';
mp1_norm = normalize_points(mp1, K);
mp2_norm = normalize_points(mp2, K);

% what will points3d be if one of the digits is missing from one of the
% views?
[points3d,~,~] = triangulate_DL(mp1_norm, mp2_norm, P1, P2);    % multiply by scale factor to get real 3d coordinates w.r.t. the direct camera view
points3d = points3d * scale;

tracks = initializeTracks();
markers3D = zeros(3);
for ii = 1 : num_elements_to_track
    
    bbox = [s(:,ii).BoundingBox];
    bbox = reshape(bbox,[4,2])';
    
    markers3D(2,:) = points3d(ii,:);
    
    newTrack = struct(...
        'id', ii, ...
        'bbox', bbox, ...
        'digitmask1', squeeze(digitMasks{1}(:,:,ii)), ...
        'digitmask2', squeeze(digitMasks{2}(:,:,ii)), ...
        'meanHSV', squeeze(meanHSV(:,ii,:)), ...
        'stdHSV', squeeze(stdHSV(:,ii,:)), ...
        'markers3D', markers3D, ...
        'age', 1, ...
        'isvisible', isVisible(ii,:), ...
        'totalVisibleCount', totalVisCount(ii,:), ...
        'consecutiveInvisibleCount', consecInvisibleCount(ii,:));
    tracks(ii) = newTrack;
        
end

% now that tracks are initialized, do the actual tracking
paw_hsv = cell(1,2);
HSVlimits = zeros(num_elements_to_track-1, 6, 2);
numFrames = 0;
while video.CurrentTime < video.Duration
    numFrames = numFrames + 1
    image = readFrame(video);
    image_ud = undistortImage(image, boxCalibration.cameraParams);
    image_ud = double(image_ud) / 255;
    
    BG_diff = imabsdiff(BGimg_ud,image_ud);
    
    BG_mask = false(h,w);
    for iCh = 1 : 3
        BG_mask = BG_mask | (squeeze(BG_diff(:,:,iCh)) > diff_threshold);
    end
    
    SE = strel('disk',2);
    BG_mask = bwdist(BG_mask) < 2;
    BG_mask = imopen(BG_mask, SE);
    BG_mask = imclose(BG_mask,SE);
    BG_mask = imfill(BG_mask,'holes');
    prev_mask_bbox = mask_bbox;
    prev_paw_mask = false(h,w);
    
    prev_paw_mask(prev_mask_bbox(1,2) : prev_mask_bbox(1,2) + prev_mask_bbox(1,4),...
                  prev_mask_bbox(1,1) : prev_mask_bbox(1,1) + prev_mask_bbox(1,3)) = tracks(num_elements_to_track).digitmask1;
    prev_paw_mask(prev_mask_bbox(2,2) : prev_mask_bbox(2,2) + prev_mask_bbox(2,4),...
                  prev_mask_bbox(2,1) : prev_mask_bbox(2,1) + prev_mask_bbox(2,3)) = tracks(num_elements_to_track).digitmask2;

	% find overlap between previous mask and current mask, and keep those
    % parts of the background mask that overlapped with the previous mask
    overlapMask = prev_paw_mask & BG_mask;
    BG_mask = imreconstruct(overlapMask, BG_mask);
%     BG_mask = imdilate(BG_mask,strel('disk',10));

    % will eventually need code here to deal with partial occlusions of the
    % full paw mask
    current_paw_mask{1} = center_region_mask & BG_mask;
    current_paw_mask{2} = ~center_region_mask & BG_mask;
    projMask = pawProjectionMask(current_paw_mask{2}, F_side', [h,w]);
    projMask = imdilate(projMask,strel('disk',10));
    current_paw_mask{1} = current_paw_mask{1} & projMask;
    
    for iView = 1 : 2
        s = regionprops(current_paw_mask{iView},'BoundingBox');
        mask_bbox(iView,:) = floor(s.BoundingBox) - 10;
        mask_bbox(iView,3:4) = mask_bbox(iView,3:4) + 30;
        
        tempMask = current_paw_mask{iView};
        current_paw_mask{iView} = tempMask(mask_bbox(iView,2) : mask_bbox(iView,2) + mask_bbox(iView,4), ...
                                           mask_bbox(iView,1) : mask_bbox(iView,1) + mask_bbox(iView,3));
        paw_hsv{iView} = zeros(mask_bbox(iView,4)+1,mask_bbox(iView,3)+1,3,num_elements_to_track);
    end
    % now, get rid of all the bits that are too small, the wrong shape, 
    % etc. This is where we need to start thinking about what to do when
    % the paw passes behind the edge of the box and there will be two paw 
    % parts. A model of the paw might solve this problem, but would like to 
    % get away with doing this without one...
    
    for ii = 1 : num_elements_to_track
        
        for iView = 1 : 2
            paw_img = image_ud(mask_bbox(iView,2) : mask_bbox(iView,2) + mask_bbox(iView,4), ...
                               mask_bbox(iView,1) : mask_bbox(iView,1) + mask_bbox(iView,3),:);
            paw_enh = enhanceColorImage(paw_img, ...
                                        decorrStretchMean{iView}(ii,:), ...
                                        decorrStretchSigma{iView}(ii,:), ...
                                        'mask',current_paw_mask{iView});
            hsvMask = double(repmat(current_paw_mask{iView},1,1,3));
            paw_hsv{iView}(:,:,:,ii) = rgb2hsv(hsvMask .* paw_enh);
            
        end
    end
    
    % now do the thresholding
    hsv = cell(1,2);
    prelim_digitMask = cell(1,num_elements_to_track-1);
    
    for ii = 2 : num_elements_to_track - 1    % do the digits first
        prelim_digitMask{ii} = cell(1,2);
        
        sameColIdx = find(strcmp(colorList{ii},colorList));
        numSameColorObjects = length(sameColIdx);
        
        for iView = 1 : 2
            hsv{iView} = squeeze(paw_hsv{iView}(:,:,:,ii));
        end
        tempMask = thresholdDigits(tracks(ii).meanHSV, ...
                                   tracks(ii).stdHSV, ...
                                   HSVthresh_parameters, ...
                                   hsv, ...
                                   numSameColorObjects, ...
                                   digitBlob);
        for iView = 1 : 2
            if strcmpi(colorList{ii},'blue')
                bbox_blueBeadMask = blueBeadMask(mask_bbox(iView,2) : mask_bbox(iView,2) + mask_bbox(iView,4), ...
                                                 mask_bbox(iView,1) : mask_bbox(iView,1) + mask_bbox(iView,3));
                % eliminate any identified blue regions that overlap with blue
                % beads
                tempMask{iView} = tempMask{iView} & ~bbox_blueBeadMask;% squeeze(boxMarkers.beadMasks(:,:,3));
            end
            prelim_digitMask{ii}{iView} = tempMask{iView};
        end
        
    end
    % now have preliminary masks in each view, need to assign blobs to
    % digits
%     fullDigitMasks = cell(1,2);
%     fullDigitMasks{1} = false(size(hsv{1},1),size(hsv{1},2));
%     fullDigitMasks{2} = false(size(hsv{2},1),size(hsv{2},2));
% not using the above right now, instead passing all the tracks data to the
% paw dorsum identification subroutine

%     digit_centroids = 
    for iColor = 1 : length(digitColors)
        
        sameColIdx = find(strcmp(digitColors{iColor},colorList));
        numSameColorObjects = length(sameColIdx);
        colorTracks = initializeTracks();
        prelimMask = cell(numSameColorObjects, 2);
        for iDigit = 1 : numSameColorObjects
            colorTracks(iDigit) = tracks(sameColIdx(iDigit));
            for iView = 1 : 2
                prelimMask{iDigit,iView} = prelim_digitMask{sameColIdx(iDigit)}{iView};
            end
        end
            
        newTracks = assign_prelim_blobs_to_tracks(colorTracks, ...
                                                  prelimMask, ...
                                                  mask_bbox, ...
                                                  trackingBoxParams, ...
                                                  trackCheck);
            
        for iDigit = 1 : numSameColorObjects
            tracks(sameColIdx(iDigit)) = newTracks(iDigit);
%             fullDigitMasks{1} = fullDigitMasks{1} | ...
%                                 tracks(sameColIdx(iDigit)).digitmask1;
%             fullDigitMasks{2} = fullDigitMasks{2} | ...
%                                 tracks(sameColIdx(iDigit)).digitmask2;
        end
    end    % end for iColor...
    
    % find the 3d points of all digits visible in both views, and the
    % general region in which the dorsum of the paw must appear
    [digitMarkers, dorsumRegionMask] = ...
        findDorsumRegion(tracks, pawPref);
    % triangulate all available digit markers
	tracks(2:5) = digit3Dpoints(digitMarkers, trackingBoxParams, tracks(2:5), mask_bbox);
    
    % now should have the digits - need to identify the dorsal aspect of
    % the paw...
    hsv{iView} = squeeze(paw_hsv{iView}(:,:,:,1));
    pdMask = thresholdDorsum(tracks(1).meanHSV, ...
                             tracks(1).stdHSV, ..., ...
                             HSVthresh_parameters, ...
                             hsv, ...
                             digitMarkers, ...
                             dorsumRegionMask, ...
                             pdBlob);

end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tracks = initializeTracks()
    % create an empty array of tracks
    tracks = struct(...
        'id', {}, ...
        'bbox', {}, ...
        'digitmask1', {}, ...
        'digitmask2', {}, ...
        'meanHSV', {}, ...
        'stdHSV', {}, ...
        'markers3D', {}, ...
        'age', {}, ...
        'isvisible', {}, ...
        'totalVisibleCount', {}, ...
        'consecutiveInvisibleCount', {});
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function obj = setupSystemObjects()
        % Initialize Video I/O
        % Create objects for reading a video from a file, drawing the tracked
        % objects in each frame, and playing the video.

        % Create a video file reader.
        obj.reader = vision.VideoFileReader('atrium.avi');

        % Create two video players, one to display the video,
        % and one to display the foreground mask.
        obj.videoPlayer = vision.VideoPlayer('Position', [20, 400, 700, 400]);
        obj.maskPlayer = vision.VideoPlayer('Position', [740, 400, 700, 400]);

        % Create System objects for foreground detection and blob analysis

        % The foreground detector is used to segment moving objects from
        % the background. It outputs a binary mask, where the pixel value
        % of 1 corresponds to the foreground and the value of 0 corresponds
        % to the background.

        obj.detector = vision.ForegroundDetector('NumGaussians', 3, ...
            'NumTrainingFrames', 40, 'MinimumBackgroundRatio', 0.7);

        % Connected groups of foreground pixels are likely to correspond to moving
        % objects.  The blob analysis System object is used to find such groups
        % (called 'blobs' or 'connected components'), and compute their
        % characteristics, such as area, centroid, and the bounding box.

        obj.blobAnalyser = vision.BlobAnalysis('BoundingBoxOutputPort', true, ...
            'AreaOutputPort', true, 'CentroidOutputPort', true, ...
            'MinimumBlobArea', 400);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [normalized_points] = normalize_points(points2d, K)
% INPUTS
%   points2d - m x 2 array containing (x,y) pairs in each row
%   K - intrinsic matrix (lower triangular format)
homogeneous_points = [points2d,ones(size(points2d,1),1)];
normalized_points  = (K' \ homogeneous_points')';
normalized_points = bsxfun(@rdivide,normalized_points(:,1:2),normalized_points(:,3));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [meanHSV, stdHSV] = calcHSVstats(paw_hsv, digitMask)

    meanHSV = zeros(1,3);
    stdHSV  = zeros(1,3);
    idx = squeeze(digitMask);
    idx = idx(:);
    for jj = 1 : 3
        colPlane = squeeze(paw_hsv(:,:,jj));
        colPlane = colPlane(:);
        if jj == 1
            meanAngle = wrapTo2Pi(circ_mean(colPlane(idx)*2*pi));
            stdAngle = wrapTo2Pi(circ_std(colPlane(idx)*2*pi));
            meanHSV(jj) = meanAngle / (2*pi);
            stdHSV(jj) = stdAngle / (2*pi);
        else
            meanHSV(jj) = mean(colPlane(idx));
            stdHSV(jj) = std(colPlane(idx));
        end
    end
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function blobID = selectBlobForTrack(blobMask, ...
                                     paw_hsv, ...
                                     currentTrack, ...
                                     otherTrack, ...
                                     iView, ...
                                     prev_mask_bbox, ...
                                     mask_bbox)
% INPUTS:
%   blobMask - mask of the currently detected blobs    
    % figure out where the previous mask for this digit is in the
    % current bounding box
    switch iView
        case 1,
            prev_digit_mask = currentTrack.digitmask1;
            other_digit_mask = otherTrack.digitmask1;
        case 2,
            prev_digit_mask = currentTrack.digitmask2;
            other_digit_mask = other_digit_mask.digitmask2;
    end
    temp = false(h,w);
    temp(prev_mask_bbox(2) : prev_mask_bbox(2) + prev_mask_bbox(4), ...
         prev_mask_bbox(1) : prev_mask_bbox(1) + prev_mask_bbox(3)) = ...
             prev_digit_mask;
    prev_digit_mask = temp(mask_bbox(2) : mask_bbox(2) + mask_bbox(4), ...
                           mask_bbox(1) : mask_bbox(1) + mask_bbox(3));
                       
    temp = false(h,w);
    temp(prev_mask_bbox(2) : prev_mask_bbox(2) + prev_mask_bbox(4), ...
         prev_mask_bbox(1) : prev_mask_bbox(1) + prev_mask_bbox(3)) = ...
             other_digit_mask;
    other_digit_mask = temp(mask_bbox(2) : mask_bbox(2) + mask_bbox(4), ...
                            mask_bbox(1) : mask_bbox(1) + mask_bbox(3));
                           
    % a few possibilities
    % first, both digits could have been visible in the previous frame. In
    % that case, we can compare the blobs in blobMask to each of the digit
    % blobs from the previous frame, and see which fits better to the
    % current digit. 
    s = regionprops(blobMask,'Centroid','Area');
    L = bwlabel(blobMask);
    % calculate mean hsv values in each blob
    meanHSV = zeros(length(s),3);
    for ii = 1 : length(s)
        [meanHSV(ii,:), stdHSV] = calcHSVstats(paw_hsv, (L == ii));   % not sure if stdHSV will be useful or not
    end
        
    if currentTrack.isvisible(iView) && otherTrack.isvisible(iView)

        % calculate Euclidean distances between the centroids of the blobs
        % in blobMask and the previous digit blobs
        
    end

%     prev_bbox = track.bbox(iView,:);
%     prev_bbox(1:2) = prev_bbox(1:2) - mask_bbox(iView,1:2) + 1;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [mp1, mp2] = points3d_to_images(points3d, P1, P2, K)

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function digitMask = thresholdDigits(meanHSV, ...
                                     stdHSV, ...
                                     HSVthresh_parameters, ...
                                     hsv, ...
                                     numSameColorObjects, ...
                                     digitBlob)
%
% INPUTS:
%   meanHSV - 3 element vector with mean hue, saturation, and value values,
%       respectively for the target region
%   stdHSV - 3 element vector with standard deviation of the hue, 
%       saturation, and value values, respectively for the target region
%   HSVthresh_parameters - structure with the following fields:
%       .min_thresh - 3 element vector containing mininum distance h/s/v
%           thresholds must be from their respective means
%       .num_stds - 3 element vector containing number of standard
%           deviations away from the mean h/s/v values to set threshold.
%           The threshold is set as whichever is further from the mean -
%           min_thresh or num_stds * std
%   hsv - 2-element cell array containing the enhanced hsv image of the paw
%       within the bounding box for the direct view (index 1) and mirror
%       view (index 2)
%   numSameColorObjects - scalar, number of digits that have the same color
%       tattoo as the current digit
%   digitBlob - cell array of blob objects containing blob parameters for
%       the direct view (index 1) and mirror view (index 2)
%
% OUTPUTS:
%   digitMask - 1 x 2 cell array containing the mask for the direct
%       (center) and mirror views, respectively


% consider adjusting this algorithm to include knowledge from the previous
% frame

    min_thresh = HSVthresh_parameters.min_thresh;
    max_thresh = HSVthresh_parameters.max_thresh;
    num_stds   = HSVthresh_parameters.num_stds;
    
    HSVlimits = zeros(2,6);
    digitMask = cell(1,2);
    for iView = 1 : 2
        % construct HSV limits vector from track, HSVthresh_parameters
        HSVlimits(iView,1) = meanHSV(iView,1);            % hue mean
        HSVlimits(iView,2) = max(min_thresh(1), stdHSV(iView,1) * num_stds(1));  % hue range
        HSVlimits(iView,2) = min(max_thresh(1), HSVlimits(iView,2));  % hue range

        s_range = max(min_thresh(2), stdHSV(iView,2) * num_stds(2));
        s_range = min(max_thresh(2), s_range);
        HSVlimits(iView,3) = max(0.001, meanHSV(iView,2) - s_range);    % saturation lower bound
        HSVlimits(iView,4) = min(1.000, meanHSV(iView,2) + s_range);    % saturation upper bound

        v_range = max(min_thresh(3), stdHSV(iView,3) * num_stds(3));
        v_range = min(max_thresh(3), v_range);
        HSVlimits(iView,5) = max(0.001, meanHSV(iView,3) - v_range);    % saturation lower bound
        HSVlimits(iView,6) = min(1.000, meanHSV(iView,3) + v_range);    % saturation upper bound    
        
        % threshold the image
        tempMask = HSVthreshold(squeeze(hsv{iView}), ...
                                HSVlimits(iView,:));

        if ~any(tempMask(:)); continue; end

        SE = strel('disk',2);
        tempMask = imopen(tempMask, SE);
        tempMask = imclose(tempMask, SE);
        tempMask = imfill(tempMask, 'holes');

        [A,~,~,~,labMat] = step(digitBlob{iView}, tempMask);
        % take at most the numSameColorObjects largest blobs
        [~,idx] = sort(A, 'descend');
        if ~isempty(A)
            tempMask = false(size(tempMask));
            for kk = 1 : min(numSameColorObjects, length(idx))
                tempMask = tempMask | (labMat == idx(kk));
            end
        end
        
        digitMask{iView} = tempMask;
    end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function pdMask = thresholdDorsum(meanHSV, ...
                                  stdHSV, ...
                                  HSVthresh_parameters, ...
                                  hsv, ...
                                  digitMarkers, ...
                                  dorsumRegionMask, ...
                                  pdBlob)
%
% INPUTS:
%   meanHSV - 3 element vector with mean hue, saturation, and value values,
%       respectively for the target region
%   stdHSV - 3 element vector with standard deviation of the hue, 
%       saturation, and value values, respectively for the target region
%   HSVthresh_parameters - structure with the following fields:
%       .min_thresh - 3 element vector containing mininum distance h/s/v
%           thresholds must be from their respective means
%       .num_stds - 3 element vector containing number of standard
%           deviations away from the mean h/s/v values to set threshold.
%           The threshold is set as whichever is further from the mean -
%           min_thresh or num_stds * std
%   hsv - 2-element cell array containing the enhanced hsv image of the paw
%       within the bounding box for the direct view (index 1) and mirror
%       view (index 2)
%   digitMarkers - 4x2x3x2 array. First dimension is the digit ID, second
%       dimension is (x,y), third dimension is proximal,centroid,tip of
%       each digit, 4th dimension is the view (1 = direct, 2 = mirror)
%   dorsumRegionMask - cell array containing masks for where the paw dorsum
%       can be with respect to the digits (index 1 id direct view, index 2
%       is mirror view)
%   pdBlob - cell array of blob objects containing blob parameters for
%       the direct view (index 1) and mirror view (index 2)
%
% OUTPUTS:
%   digitMask - 1 x 2 cell array containing the mask for the direct
%       (center) and mirror views, respectively


                        
    min_thresh = HSVthresh_parameters.min_thresh;
    max_thresh = HSVthresh_parameters.max_thresh;
    num_stds   = HSVthresh_parameters.num_stds;
    
    HSVlimits = zeros(2,6);
    pdMask = cell(1,2);
    
    currentMask = cell(1,2);
    currentMask{1} = false(size(hsv{1},1),size(hsv{1},2));
    currentMask{2} = false(size(hsv{2},1),size(hsv{2},2));
    

    for iView = 2 : -1 : 1   % easier to start with the mirror view
            
        % construct HSV limits vector from track, HSVthresh_parameters
        % construct HSV limits vector from track, HSVthresh_parameters
        HSVlimits(iView,1) = meanHSV(iView,1);            % hue mean
        HSVlimits(iView,2) = max(min_thresh(1), stdHSV(iView,1) * num_stds(1));  % hue range
        HSVlimits(iView,2) = min(max_thresh(1), HSVlimits(iView,2));  % hue range

        s_range = max(min_thresh(2), stdHSV(iView,2) * num_stds(2));
        s_range = min(max_thresh(2), s_range);
        HSVlimits(iView,3) = max(0.001, meanHSV(iView,2) - s_range);    % saturation lower bound
        HSVlimits(iView,4) = min(1.000, meanHSV(iView,2) + s_range);    % saturation upper bound

        v_range = max(min_thresh(3), stdHSV(iView,3) * num_stds(3));
        v_range = min(max_thresh(3), v_range);
        HSVlimits(iView,5) = max(0.001, meanHSV(iView,3) - v_range);    % saturation lower bound
        HSVlimits(iView,6) = min(1.000, meanHSV(iView,3) + v_range);    % saturation upper bound  
        
        % threshold the image
        tempMask = HSVthreshold(squeeze(hsv{iView}), ...
                                HSVlimits(iView,:));

        if ~any(tempMask(:)); continue; end

        SE = strel('disk',2);
        tempMask = imopen(tempMask, SE);
        tempMask = imclose(tempMask, SE);
        tempMask = imfill(tempMask, 'holes');

        tempMask = tempMask & dorsumRegionMask{iView};
        
        [A,~,~,~,labMat] = step(pdBlob{iView}, tempMask);
        % take at most the numSameColorObjects largest blobs
        [~,idx] = sort(A, 'descend');
        if ~isempty(idx)
            tempMask = (labMat == idx(1));
        end
        
        pdMask{iView} = tempMask;
    end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function newTracks = assign_prelim_blobs_to_tracks(colorTracks, ...
                                                   prelimMask, ...
                                                   mask_bbox, ...
                                                   trackingBoxParams, ...
                                                   trackCheck)
%
% INPUTS:
%   colorTracks - cell array containing 
%   prelimMask - m x 2 cell array, where m is the number of digits with the
%       same coloring (should be one or two), and the second index is the
%       direct view (index 1) or mirror view (index 2)
%   prev_mask_bbox - 2 x 4 array, 1st row is bounding box for the direct
%       view, second row is for the mirror view
%   mask_bbox - 
%
% OUTPUTS:
%

% first, check 3D reconstructions of prelimMask in mirror and center views;
% is there a large reprojection error? If more than one blob in each view,
% which combo has the smallest reprojection errors?

if length(colorTracks) == 1
    % only one color to deal with
    newTracks = checkSingleTrack(colorTracks, ...
                                 prelimMask, ...
                                 mask_bbox, ...
                                 trackingBoxParams, ...
                                 trackCheck);
else
    newTracks = checkTwoTracks(colorTracks, ...
                               prelimMask, ...
                               mask_bbox, ...
                               trackingBoxParams, ...
                               trackCheck);
end

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function newTrack = checkSingleTrack(prevTrack, ...
                                     prelimMask, ...
                                     mask_bbox, ...
                                     trackingBoxParams, ...
                                     trackCheck)

	newTrack = prevTrack;
    
    % several possibilities: a blob is visible in both views, a blob is
    % visible in one view but not the other, blob isn't visible in either view
    if any(prelimMask{1,1}(:)) && any(prelimMask{1,2}(:))

        new_centroids = zeros(2,2);
        % triangulate the centroids of the direct and mirror view blobs
        s_direct = regionprops(prelimMask{1},'Centroid');
        s_mirror = regionprops(prelimMask{2},'Centroid');

        new_centroids(1,:) = s_direct.Centroid + mask_bbox(1,1:2) - 1;
        new_centroids(2,:) = s_mirror.Centroid + mask_bbox(2,1:2) - 1;

        new_centroids_norm = normalize_points(new_centroids, trackingBoxParams.K);
        [points3d,~,reprojErrors] = triangulate_DL(new_centroids_norm(1,:), ...
                                                new_centroids_norm(2,:), ...
                                                trackingBoxParams.P1, ...
                                                trackingBoxParams.P2); 
        % calculate mean reprojection error
        meanReprojError = mean(sqrt(sum(reprojErrors.^2,2)));
        points3d = points3d * trackingBoxParams.scale;

        % distance from previous point
        d3d = norm(points3d - prevTrack.markers3D(2,:));
        
        % if reprojection errors and/or 3-d distance don't make sense, is
        % one of the blobs off? Is the other OK, or are both mistakes? If
        % so, how do we estimate current 3D point?
        if d3d > trackCheck.maxDistPerFrame || ...
           meanReprojError > trackCheck.maxReprojError
        % WORKING HERE... NOW NEED TO DETERMINE IF REPROJECTION ERRORS ARE
        % SMALL ENOUGH AND CURRENT 3D POINT IS CLOSE ENOUGH TO THE PREVIOUS
        % POINT TO ACCEPT IT. IF SO, UPDATE NEW TRACK WITH THE NEW MASK. IF
        % NOT, DECIDE THAT THIS DIGIT IS NOT VISIBLE IN AT LEAST ONE OF THE
        % VIEWS; THEN NEED TO DECIDE IF ONE OF THE VIEWS IS VALID. FOR NOW,
        % ASSUME TRACKING IS OK
        
        else
            newTrack.digitmask1 = prelimMask{1};
            newTrack.digitmask2 = prelimMask{2};
            newTrack.markers3D(2,:) = points3d;
            newTrack.isvisible = true(1,2);
            newTrack.totalVisibleCount = newTrack.totalVisibleCount + 1;
            newTrack.consecutiveInvisibleCount = [0 0];
        end
    end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function newTracks = checkTwoTracks(prevTracks, ...
                                    prelimMask, ...
                                    mask_bbox, ...
                                    trackingBoxParams, ...
                                    trackCheck)

% INPUTS:
%   prevTracks - track structures for the two tracks that are the same
%       color
%   prelimMask - m x 2 cell array, where m is the number of digits with the
%       same coloring (should be one or two), and the second index is the
%       direct view (index 1) or mirror view (index 2)\
%   mask_bbox - 
%	trackingBoxParams - 
	newTracks = prevTracks;
    prev_3dpoints = zeros(2,3);
    prev_3dpoints(1,:) = prevTracks(1).markers3D(2,:);
    prev_3dpoints(2,:) = prevTracks(2).markers3D(2,:);
    
    % several possibilities: two blobs visible in both views; one blob
    % visible in one view, two blobs in the other; none in one view, two in
    % the other, etc.
    
    % figure out how many blobs in each view
    numBlobs = zeros(2,2);
    s = cell(2,2);
    digLabelMask = cell(2,2);
    for iTrack = 1 : 2
        for iView = 1 : 2
            s{iTrack,iView} = regionprops(prelimMask{iTrack,iView},'area','centroid');
            numBlobs(iTrack,iView) = length(s{iTrack,iView});
            digLabelMask{iTrack,iView} = bwlabel(prelimMask{iTrack,iView});
        end
        if numBlobs(iTrack,1) == 2 && numBlobs(iTrack,2) == 2
            % two blobs visible in each view

            new_centroids = zeros(2,2,2);
%             points3d = zeros(2,3);   % first dimension indexes the 3d points,
%                                      % second dimension is [x,y,z], third
%                                      % dimension is different combinations
            % triangulate the centroids of the direct and mirror view blobs
            for iView = 1 : 2
                for iBlob = 1 : 2
                    new_centroids(iView,iBlob,:) = s{iTrack,iView}(iBlob).Centroid + mask_bbox(iView,1:2) - 1;
%                     new_centroids_norm(iView,iBlob,:) = ...
%                         normalize_points(squeeze(new_centroids(iView,iBlob,:))', trackingBoxParams.K);
                end
            end
            % find intersections of lines connecting centroids of the blobs
            % in the direct and mirror views
            % for blobs that are correctly paired, they should interect at
            % the epipole because of the planar mirror geometry
            test_epipoles = zeros(2,2);
            epi_error = zeros(1,2);
            m = zeros(2,2);
            b = zeros(2,2);
            for ii = 1 : 2    % ii is the index of the blob in the front view
                % calculate slopes and y-intercepts
                m(1,ii) = (new_centroids(1,ii,2) - new_centroids(2,ii,2)) / ...
                          (new_centroids(1,ii,1) - new_centroids(2,ii,1));
                m(2,ii) = (new_centroids(1,ii,2) - new_centroids(2,3-ii,2)) / ...
                          (new_centroids(1,ii,1) - new_centroids(2,3-ii,1));
                b(1,ii) = new_centroids(1,ii,2) - m(1,ii) * new_centroids(1,ii,1);
                b(2,ii) = new_centroids(1,ii,2) - m(2,ii) * new_centroids(1,ii,1);
            end
            for jj = 1 : 2    % jj is the index of the combination
                test_epipoles(jj,1) = (b(jj,2) - b(jj,1)) / (m(jj,1)-m(jj,2));
                test_epipoles(jj,2) = m(jj,1)*test_epipoles(jj,1) + b(jj,1);
                epi_error(jj) = norm(test_epipoles(jj,:) - trackingBoxParams.epipole);
            end
            % figure out which "test" epipole is closest to the real
            % epipole
            direct_view_pts = squeeze(new_centroids(1,:,:));
            if epi_error(1) < epi_error(2)    % indices of blobs in the two views match up
                mirror_view_pts = squeeze(new_centroids(2,:,:));
            else    % indices of blobs in the two views don't match up
                mirror_view_pts = squeeze(new_centroids(2,2:-1:1,:));
            end
            direct_view_pts_norm = normalize_points(direct_view_pts, trackingBoxParams.K);
            mirror_view_pts_norm = normalize_points(mirror_view_pts, trackingBoxParams.K);
            [points3d,~,reprojErrors] = triangulate_DL(direct_view_pts_norm, ...
                                                       mirror_view_pts_norm, ...
                                                       trackingBoxParams.P1, ...
                                                       trackingBoxParams.P2);
            points3d = points3d * trackingBoxParams.scale;
            % now need to assign one of these points to the current digit.
            % To do this, find the distance between both 3d points and each
            % of the previous digit 3d locations. Then pick the assignments
            % that minimize the maximum distance between the current points
            % and the previous points.
            % does direct view centroid 1 correspond to previous 3d
            % centroid from first or second track?
            poss_3d_diffs = zeros(4,3);
            maxDist = zeros(1,2);
            poss_3d_diffs(1:2,:) = bsxfun(@minus,prev_3dpoints,points3d(1,:));
            poss_3d_diffs(3:4,:) = bsxfun(@minus,prev_3dpoints,points3d(2,:));
            poss_distances = sqrt(sum(poss_3d_diffs.^2,2));
            % poss_distances is a 4 x 1 vector. The first and fourth
            % entries go together, as do the 2nd and third
            maxDist(1) = max(poss_distances([1,4]));
            maxDist(2) = max(poss_distances(2:3));
            
            if maxDist(1) < maxDist(2)
                % first center view blob corresponds with 1st track
                centerMask = (digLabelMask{iTrack,1} == iTrack);
                if epi_error(1) < epi_error(2)
                    mirrorMask = (digLabelMask{iTrack,2} == iTrack);
                else
                    mirrorMask = (digLabelMask{iTrack,2} == (3-iTrack));
                end
                curr_3dpoint = points3d(iTrack,:);
                curr_reproj_error = reprojErrors(iTrack,:);
            else
                centerMask = (digLabelMask{iTrack,1} == (3-iTrack));
                if epi_error(1) < epi_error(2)
                    mirrorMask = (digLabelMask{iTrack,2} == (3-iTrack));
                else
                    mirrorMask = (digLabelMask{iTrack,2} == iTrack);
                end
                curr_3dpoint = points3d((3-iTrack),:);
                curr_reproj_error = reprojErrors((3-iTrack),:);
            end
            meanReprojError = mean(sqrt(sum(reprojErrors.^2,2)));
            d3d = norm(curr_3dpoint - prev_3dpoints(iTrack,:));
            
            if d3d > trackCheck.maxDistPerFrame || ...
               meanReprojError > trackCheck.maxReprojError

            end
            
            newTracks(iTrack).digitmask1 = centerMask;
            newTracks(iTrack).digitmask2 = mirrorMask;
            newTracks(iTrack).markers3D(2,:) = curr_3dpoint;
            newTracks(iTrack).isvisible = true(1,2);
            newTracks(iTrack).totalVisibleCount = newTracks(iTrack).totalVisibleCount + 1;
            newTracks(iTrack).consecutiveInvisibleCount = [0 0];

        else    % what to do if all the blobs aren't there for this digit track?
            
        end

    end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function testPoint = selectDorsumTestPoint(pawPref, iView, currentMask)

% function to find a test point to determine where the dorsum of the paw
% should be with respect to the digits

    if iView == 1    % direct view
        if strcmpi(pawPref,'right')
            testPoint = [1,1];
        else
            testPoint = [1,size(currentMask{iView},2)];
        end
    else    % mirror view
        if strcmpi(pawPref,'right')
            testPoint = round([size(curentMask{iView},1)/2, size(currentMask{iView},2)]);
        else
            testPoint = round([size(curentMask{iView},1)/2, 1]);
        end
    end
    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [digitMarkers, dorsumRegionMask] = ...
    findDorsumRegion(tracks, pawPref)
%
% INPUTS:
%   tracks - the full set of digit tracks, after the digits have been
%       identified for the current frame
%   pawPref - string containing 'left' or 'right'
%
% OUTPUTS:
%   digitMarkers - 4x2x3x2 array. First dimension is the digit ID, second
%       dimension is (x,y), third dimension is proximal,centroid,tip of
%       each digit, 4th dimension is the view (1 = direct, 2 = mirror)
%   dorsumRegionMask - cell array containing masks for where the paw dorsum
%       can be with respect to the digits (index 1 id direct view, index 2
%       is mirror view)

fixed_pts = zeros(3,2,2);    % 3 points by (x,y) coords by 2 views (1 - direct, 2 - mirror)
switch lower(pawPref)
    case 'right',
        fixed_pts(:,:,1) = [ 2.0   0.0    % most radial digit
                             0.0   0.0    % most ulnar digit
                             1.0  -1.0];  % palm region
        fixed_pts(:,:,2) = [0.0  0.0
                            0.0  2.0
                            1.0  1.0];
    case 'left',
        fixed_pts(:,:,1) = [0.0  0.0    % most radial digit
                            2.0  0.0    % most ulnar digit
                            1.0  -1.0];  % palm region
        fixed_pts(:,:,2) = [1.0  0.0
                            1.0  2.0
                            0.0  1.0];
end
% CHECK THAT I'M DOING THIS ROTATION RIGHT FOR BOTH SIDES!


digitMarkers = zeros(length(tracks)-2, 2, 3, 2);    % number of digits by (x,y) by base/centroid/tip by view number

firstVisibleDigitFound = false(1,2);
digCentroids = zeros(2,2,2);
currentMask = cell(1,2);
digitMasks = cell(1,2);
digitMasks{1} = false(size(tracks(2).digitmask1));
digitMasks{2} = false(size(tracks(2).digitmask2));
firstMask = cell(1,2);
lastMask = cell(1,2);
for ii = 2 : length(tracks)-1
    currentMask{1} = tracks(ii).digitmask1;
    currentMask{2} = tracks(ii).digitmask2;
    digitMasks{1} = digitMasks{1} | currentMask{1};
    digitMasks{2} = digitMasks{2} | currentMask{2};

    for iView = 1 : 2
        if tracks(ii).isvisible(iView)
            s = regionprops(currentMask{iView},'centroid');
            if ~firstVisibleDigitFound(iView)
                firstVisibleDigitFound(iView) = true;
                digCentroids(1,:,iView) = s.Centroid;
                digitMarkers(ii-1,:,2,iView) = s.Centroid;
                firstMask{iView} = currentMask{iView};
            else
                digCentroids(2,:,iView) = s.Centroid;
                lastMask{iView} = currentMask{iView};
                digitMarkers(ii-1,:,2,iView) = s.Centroid;
            end
        end
    end
end

H = zeros(3,3,2);
linepts = zeros(2,2);
validImageBorderPts = zeros(2,2);
dorsumRegionMask = cell(1,2);
for iView = 1 : 2
    movingPoints = squeeze(digCentroids(:,:,iView));
    tform = fitgeotrans(squeeze(fixed_pts(1:2,:,iView)), movingPoints, 'nonreflectivesimilarity');
    H(:,:,iView) = tform.T';
    fixed_pts_hom = [squeeze(fixed_pts(:,:,iView)), ones(3,1)];
    pts_transformed = (H(:,:,iView) * fixed_pts_hom')';
    pts_transformed = bsxfun(@rdivide,pts_transformed(:,1:2), pts_transformed(:,3));
    
    [A,B,C] = constructParallelLine(pts_transformed(1,:), ...
                                    pts_transformed(2,:), ...
                                    pts_transformed(3,:));
    borderPts = lineToBorderPoints([A,B,C], size(digitMasks{iView}));
    
    linepts(1,:) = borderPts(1:2);
    linepts(2,:) = borderPts(3:4);
    % find the points from each digit closest to and farthest from the
    % estimated paw dorsum centroid. WOULD PROBABLY WORK BETTER IF I
    % CALCULATED THE DISTANCE FROM A LINE PARALLEL TO THE LINE BETWEEN
    % DIGIT CENTROIDS INSTEAD OF THE DORSUM CENTER - OR MOVE THE DORSUM
    % CENTER FURTHER AWAY
    firstValidIdx = 0;lastValidIdx = 0;
    for ii = 2 : length(tracks) - 1
        if ~tracks(ii).isvisible(iView)
            continue;
        end
        if firstValidIdx == 0; firstValidIdx = ii-1; end
        lastValidIdx = ii-1;
        
        if iView == 1
            currentMask{iView} = tracks(ii).digitmask1;
        else
            currentMask{iView} = tracks(ii).digitmask2;
        end
        
        edge_I = bwmorph(currentMask{iView},'remove');
        [y,x] = find(edge_I);
        [~,nnidx] = findNearestPointToLine(linepts, [x,y]);
%         [~,nnidx] = findNearestNeighbor(pts_transformed(3,:), [x,y]);
        digitMarkers(ii-1,:,1,iView) = [x(nnidx),y(nnidx)];
        [~,nnidx] = findFarthestPointFromLine(linepts, [x,y]);
%         [~,nnidx] = findFarthestPoint(pts_transformed(3,:), [x,y]);
        digitMarkers(ii-1,:,3,iView) = [x(nnidx),y(nnidx)];
    end
    validImageBorderPts(1,:) = squeeze(digitMarkers(firstValidIdx,:,1,iView));
    validImageBorderPts(2,:) = squeeze(digitMarkers(lastValidIdx,:,1,iView));
    dorsumRegionMask{iView} = segregateImage(validImageBorderPts, ...
                                             pts_transformed(3,:), size(digitMasks{iView}));
%     dorsumRegionMask{iView} = segregateImage(pts_transformed(1:2,:), ...
%                                              pts_transformed(3,:), size(digitMasks{iView}));
    
    [digitsHull,~] = multiRegionConvexHullMask(digitMasks{iView});
    dorsumRegionMask{iView} = dorsumRegionMask{iView} & ~digitsHull;
end
        
            
            

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tracks = digit3Dpoints(digitMarkers, trackingBoxParams, tracks, mask_bbox)
% INPUTS:
%   digitMarkers - 4x2x3x2 array. First dimension is the digit ID, second
%       dimension is (x,y), third dimension is proximal,centroid,tip of
%       each digit, 4th dimension is the view (1 = direct, 2 = mirror)
%   tracks - tracks structures containing only the 4 digits (index 1 is
%       index finger, index 4 is pinky)
%   mask_bbox - 2 x 4 array, where each row is a standard bounding box
%       vector [x,y,w,h]

P1 = trackingBoxParams.P1;
P2 = trackingBoxParams.P2;
numDigits = size(digitMarkers,1);
matched_points = zeros(3,2,2);
for iDigit = 1 : numDigits

    currentTrack = tracks(iDigit);
    if any(~currentTrack.isvisible); continue; end   % can't see the digit in at least one view

    for iView = 1 : 2
        for iSite = 1 : 3
            matched_points(iSite,:,iView) = squeeze(digitMarkers(iDigit,:,iSite,iView));
        end
        matched_points(:,1,iView) = matched_points(:,1,iView) + mask_bbox(iView,1);
        matched_points(:,2,iView) = matched_points(:,2,iView) + mask_bbox(iView,2);
        % WORKING HERE - NEED TO MOVE THE MATCHED PONTS BACK INTO FULL
        % IMAGE COORDINATES FROM THE BOUNDING BOX COORDINATES (SHOULD BE
        % ABLE TO PULL FROM TRACKS(6))
        matched_points(:,:,iView) = normalize_points(squeeze(matched_points(:,:,iView)), ...
                                                         trackingBoxParams.K);
    end
    
    [points3d,~,~] = triangulate_DL(squeeze(matched_points(:,:,1)), ...
                                    squeeze(matched_points(:,:,2)), ...
                                    P1, P2);
    tracks(iDigit).markers3D = points3d * trackingBoxParams.scale;
    end
end