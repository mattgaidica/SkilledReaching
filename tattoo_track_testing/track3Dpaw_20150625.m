function centroids = track3Dpaw_20150625(video, ...
                                         BGimg, ...
                                         peakFrameNum, ...
                                         F, ...
                                         startPawMask, ...
                                         digitMirrorMask_dorsum, ...
                                         digitCenterMask, ...
                                         rat_metadata, ...
                                         register_ROI, ...
                                         boxMarkers, ...
                                         varargin)
%
%
%
% INPUTS:
%    video - video reader object containing the current video under
%       analysis
%    BGimg - 
%    peakFrameNum - frame in which the paw and digits were initially
%       identified
%    F - 
%    digitMirrorMask_dorsum - m x n x 5 matrix, where each m x n matrix contains a mask
%       for a part of the paw. 1st row - dorsum of paw, 2nd through 5th
%       rows are each digit from index finger to pinky. Obviously, this is
%       the mask for the dorsum of the paw in the "peakFrame"
%    digitCenterMask - m x n x 5 matrix, where each m x n matrix contains a mask
%       for a part of the paw. 1st row - dorsum of paw, 2nd through 5th
%       rows are each digit from index finger to pinky. Obviously, this is
%       the mask for the direct view in the "peakFrame"
%   rat_metadata - needed to know whether to look to the left or right of
%       the dorsal aspect of the paw to exclude points that can't be digits
%   register_ROI - 
%   boxMarkers - 
%
% VARARGS:
%    bgimg - background image 
%
% OUTPUTS:
%

decorrStretchMean_center  = [127.5 100.0 100.0     % to isolate dorsum of paw
                             127.5 100.0 127.5     % to isolate blue digits
                             127.5 100.0 127.5     % to isolate red digits
                             127.5 100.0 127.5     % to isolate green digits
                             127.5 100.0 127.5];   % to isolate red digits
decorrStretchSigma_center = [075 075 075       % to isolate dorsum of paw
                             075 075 075       % to isolate blue digits
                             075 075 075       % to isolate red digits
                             075 075 075       % to isolate green digits
                             075 075 075];     % to isolate red digits

decorrStretchMean_mirror  = [100.0 127.5 100.0     % to isolate dorsum of paw
                             100.0 127.5 100.0     % to isolate blue digits
                             100.0 127.5 100.0     % to isolate red digits
                             127.5 100.0 127.5     % to isolate green digits
                             100.0 127.5 100.0];   % to isolate red digits

decorrStretchSigma_mirror = [050 050 050       % to isolate dorsum of paw
                      050 050 050       % to isolate blue digits
                      050 050 050       % to isolate red digits
                      050 050 050       % to isolate green digits
                      050 050 050];     % to isolate red digits
                  
startTimeFromPeak = 0.2;    % in seconds
diff_threshold = 45;
maxDistPerFrame = 25;
RGBradius = 0.1;
color_zlim = 3;
pthresh = 0.9;

h = video.Height;
w = video.Width;

for iarg = 1 : 2 : nargin - 10
    switch lower(varargin{iarg})
        case 'numbgframes',
            numBGframes = varargin{iarg + 1};
        case 'trigger_roi',
            ROI_to_find_trigger_frame = varargin{iarg + 1};
        case 'graypawlimits',
            gray_paw_limits = varargin{iarg + 1};
        case 'bgimg',
            BGimg = varargin{iarg + 1};
        case 'starttimebeforepeak',
            startTimeFromPeak = varargin{iarg + 1};
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
    end
end

% WORKING HERE - CHECK THAT THE FRAME READ IN TO INITIALIZE THE TRACKING IS
% THE SAME FRAME THE INITIAL DETECTION WAS DONE ON, AND NOT A FRAME OR SO
% OFF
vidName = fullfile(video.Path, video.Name);
video = VideoReader(vidName);
peakTime = ((peakFrameNum-1) / video.FrameRate);    % need to subtract one because readFrame reads the NEXT frame, not the current frame
video.CurrentTime = peakTime;
image = readFrame(video);

hsv_image = rgb2hsv(image);

paw_img = cell(1,3);
for ii = 1 : 3
    paw_img{ii} = image(register_ROI(ii,2):register_ROI(ii,2) + register_ROI(ii,4),...
                        register_ROI(ii,1):register_ROI(ii,1) + register_ROI(ii,3),:);
	if ii ~= 2
        paw_img{ii} = fliplr(paw_img{ii});
    end
end

% create a mask for the box front in the left and right mirrors
boxFrontMask = poly2mask(boxMarkers.frontPanel_x(1,:), ...
                         boxMarkers.frontPanel_y(1,:), ...
                         h, w);
boxFrontMask = boxFrontMask | poly2mask(boxMarkers.frontPanel_x(2,:), ...
                                        boxMarkers.frontPanel_y(2,:), ...
                                        h, w);
                        
if strcmpi(rat_metadata.pawPref, 'right')
    pawDorsumMirrorImg = paw_img{1};
else
    pawDorsumMirrorImg = paw_img{3};
end
% initialize one track each for the dorsum of the paw and each digit in the
% mirror and center views

% WORKING HERE - NEED TO DETERMINE A SET OF PROPERTIES FOR EACH REGION THAT
% MAY INDICATE WHETHER THE NEXT DETECTION CORRESPONDS TO IT OR NOT - FOR
% EXAMPLE, MEAN COLOR/HUE/INTENSITY, ETC. MAY NEED TO DO THIS ADAPTIVELY
% OVER TIME. HERE'S AN IDEA - ASSUME THE CENTROID LOCATION DOESN'T MOVE BETWEEN
% FRAMES, USE THAT AS A SEED FOR GEODESIC DISTANCE MAPPING AFTER DOING A
% DECORRSTRETCH...
tracks = initializeTracks();
numTracks = 0;
prev_paw_mask_mirror = false(size(BGimg, 1), size(BGimg, 2));
prev_paw_mask_center = false(size(BGimg, 1), size(BGimg, 2));
s = struct('Centroid', {}, ...
           'BoundingBox', {});
num_elements_to_track = size(digitMirrorMask_dorsum, 3);
imgDigitMirrorMask = false(size(BGimg,1),size(BGimg,2),num_elements_to_track);
imgDigitCenterMask = false(size(BGimg,1),size(BGimg,2),num_elements_to_track);
for ii = 1 : num_elements_to_track
    
    temp = fliplr(squeeze(digitMirrorMask_dorsum(:,:,ii)));
    
    if strcmpi(rat_metadata.pawPref,'right')
        imgDigitMirrorMask(register_ROI(1,2):register_ROI(1,2)+register_ROI(1,4), ...
                           register_ROI(1,1):register_ROI(1,1)+register_ROI(1,3),ii) = temp;
    else
        imgDigitMirrorMask(register_ROI(3,2):register_ROI(3,2)+register_ROI(3,4), ...
                           register_ROI(3,1):register_ROI(3,3)+register_ROI(3,3),ii) = temp;
    end

    temp = squeeze(digitCenterMask(:,:,ii));
    imgDigitCenterMask(register_ROI(2,2):register_ROI(2,2)+register_ROI(2,4), ...
                       register_ROI(2,1):register_ROI(2,1)+register_ROI(2,3),ii) = temp;
                   
    s(ii) = regionprops(imgDigitMirrorMask(:,:,ii),'Centroid','BoundingBox');
    s(ii + num_elements_to_track) = regionprops(imgDigitCenterMask(:,:,ii),'Centroid','BoundingBox');
    
    prev_paw_mask_mirror = prev_paw_mask_mirror | imgDigitMirrorMask(:,:,ii);
    prev_paw_mask_center = prev_paw_mask_center | imgDigitCenterMask(:,:,ii);
end
prev_paw_mask_mirror = imdilate(prev_paw_mask_mirror, strel('disk', maxDistPerFrame));
prev_paw_mask_mirror = imfill(prev_paw_mask_mirror,'holes');
masked_mirror_img = uint8(repmat(prev_paw_mask_mirror,1,1,3));
masked_mirror_img = masked_mirror_img  .* image;

prev_paw_mask_center = imdilate(prev_paw_mask_center, strel('disk', maxDistPerFrame));
prev_paw_mask_center = imfill(prev_paw_mask_center,'holes');
masked_center_img = uint8(repmat(prev_paw_mask_center,1,1,3));
masked_center_img = masked_center_img  .* image;

meanRGBenh = zeros(1,3);stdRGBenh = zeros(1,3);
for ii = 1 : num_elements_to_track
    
    masked_mirror_img_enh = enhanceColorImage(masked_mirror_img, ...
                                              decorrStretchMean_mirror(ii,:), ...
                                              decorrStretchSigma_mirror(ii,:), ...
                                              'mask',prev_paw_mask_mirror);
	masked_mirror_hsv = rgb2hsv(masked_mirror_img_enh);
                                          
    masked_center_img_enh = enhanceColorImage(masked_center_img, ...
                                              decorrStretchMean_center(ii,:), ...
                                              decorrStretchSigma_center(ii,:), ...
                                              'mask',prev_paw_mask_center);
	masked_center_hsv = rgb2hsv(masked_center_img_enh);
    
    
	kalmanFilter = configureKalmanFilter('ConstantVelocity', ...
        s(ii).Centroid, [200, 50], [100, 25], 100);
    CAMshiftTracker = vision.HistogramBasedTracker;
    initializeObject(CAMshiftTracker, masked_mirror_hsv(:,:,1), round(s(ii).BoundingBox));
    
    tempMask = squeeze(imgDigitMirrorMask(:,:,ii));
    tempMask = imerode(tempMask,strel('disk',2));    % try eroding out the previous blob to focus on colors most characteristic of that digit
    idx = find(tempMask);
    for jj = 1 : 3
        colPlane = squeeze(masked_mirror_img_enh(:,:,jj));
        meanRGBenh(jj) = mean(colPlane(idx));
        stdRGBenh(jj) = std(colPlane(idx));
    end
    newTrack = struct(...
        'id', ii, ...
        'bbox', s(ii).BoundingBox, ...
        'kalmanFilter', kalmanFilter, ...
        'CAMshiftTracker', CAMshiftTracker, ...
        'meanRGBenh', meanRGBenh, ...
        'stdRGBenh', stdRGBenh, ...
        'currentMask', squeeze(imgDigitMirrorMask(:,:,ii)), ...
        'age', 1, ...
        'totalVisibleCount', 1, ...
        'consecutiveInvisibleCount', 1);
    numTracks = numTracks + 1;
    tracks(ii) = newTrack;
    
	kalmanFilter = configureKalmanFilter('ConstantVelocity', ...
        s(ii+num_elements_to_track).Centroid, [200, 50], [100, 25], 100);
    CAMshiftTracker = vision.HistogramBasedTracker;
    initializeObject(CAMshiftTracker, masked_center_hsv(:,:,1), round(s(ii+num_elements_to_track).BoundingBox));
    
    tempMask = squeeze(imgDigitCenterMask(:,:,ii));
    tempMask = imerode(tempMask,strel('disk',2));    % try eroding out the previous blob to focus on colors most characteristic of that digit
    idx = find(tempMask);
    for jj = 1 : 3
        colPlane = squeeze(masked_center_img_enh(:,:,jj));
        meanRGBenh(jj) = mean(colPlane(idx));
        stdRGBenh(jj) = std(colPlane(idx));
    end
    newTrack = struct(...
        'id', ii+num_elements_to_track, ...
        'bbox', s(ii+num_elements_to_track).BoundingBox, ...
        'kalmanFilter', kalmanFilter, ...
        'CAMshiftTracker', CAMshiftTracker, ...
        'meanRGBenh', meanRGBenh, ...
        'stdRGBenh', stdRGBenh, ...
        'currentMask', squeeze(imgDigitCenterMask(:,:,ii)), ...
        'age', 1, ...
        'totalVisibleCount', 1, ...
        'consecutiveInvisibleCount', 1);
    
    numTracks = numTracks + 1;
    tracks(ii+num_elements_to_track) = newTrack;
end
% create tracks for the full paw
masked_mirror_img_enh = enhanceColorImage(masked_mirror_img, ...
                                          decorrStretchMean_mirror(1,:), ...
                                          decorrStretchSigma_mirror(1,:), ...
                                          'mask',prev_paw_mask_mirror);
masked_mirror_hsv = rgb2hsv(masked_mirror_img_enh);
s_mirror = regionprops(prev_paw_mask_mirror,'Centroid','BoundingBox');

masked_center_img_enh = enhanceColorImage(masked_center_img, ...
                                          decorrStretchMean_center(1,:), ...
                                          decorrStretchSigma_center(1,:), ...
                                          'mask',prev_paw_mask_center);
masked_center_hsv = rgb2hsv(masked_center_img_enh);
s_center = regionprops(prev_paw_mask_center,'Centroid','BoundingBox');

kalmanFilter = configureKalmanFilter('ConstantVelocity', ...
    s_mirror.Centroid, [200, 50], [100, 25], 100);
CAMshiftTracker = vision.HistogramBasedTracker;
initializeObject(CAMshiftTracker, masked_mirror_hsv(:,:,1), round(s_mirror.BoundingBox));

idx = find(prev_paw_mask_mirror);
for jj = 1 : 3
    colPlane = squeeze(masked_mirror_img_enh(:,:,jj));
    meanRGBenh(jj) = mean(colPlane(idx));
    stdRGBenh(jj) = std(colPlane(idx));
end
newTrack = struct(...
    'id', ii, ...
    'bbox', s(ii).BoundingBox, ...
    'kalmanFilter', kalmanFilter, ...
    'CAMshiftTracker', CAMshiftTracker, ...
    'meanRGBenh', meanRGBenh, ...
    'stdRGBenh', stdRGBenh, ...
    'currentMask', prev_paw_mask_mirror, ...
    'age', 1, ...
    'totalVisibleCount', 1, ...
    'consecutiveInvisibleCount', 1);
numTracks = numTracks + 1;
tracks(numTracks) = newTrack;

kalmanFilter = configureKalmanFilter('ConstantVelocity', ...
    s_center.Centroid, [200, 50], [100, 25], 100);
CAMshiftTracker = vision.HistogramBasedTracker;
initializeObject(CAMshiftTracker, masked_center_hsv(:,:,1), round(s_center.BoundingBox));

idx = find(prev_paw_mask_center);
for jj = 1 : 3
    colPlane = squeeze(masked_center_img_enh(:,:,jj));
    meanRGBenh(jj) = mean(colPlane(idx));
    stdRGBenh(jj) = std(colPlane(idx));
end
newTrack = struct(...
    'id', ii, ...
    'bbox', s(ii).BoundingBox, ...
    'kalmanFilter', kalmanFilter, ...
    'CAMshiftTracker', CAMshiftTracker, ...
    'meanRGBenh', meanRGBenh, ...
    'stdRGBenh', stdRGBenh, ...
    'currentMask', prev_paw_mask_center, ...
    'age', 1, ...
    'totalVisibleCount', 1, ...
    'consecutiveInvisibleCount', 1);
numTracks = numTracks + 1;
tracks(numTracks) = newTrack;
    
    
while video.CurrentTime < video.Duration
    image  = readFrame(video);
    imdiff = imabsdiff(image, BGimg);
    thresh_mask = rgb2gray(imdiff) > diff_threshold;
    
    SE = strel('disk',4);
    thresh_mask = bwdist(thresh_mask) < 2;
    thresh_mask = imopen(thresh_mask, SE);
    thresh_mask = imclose(thresh_mask,SE);
    thresh_mask = imfill(thresh_mask,'holes');
    thresh_mask = imdilate(thresh_mask,SE);
    
    % could use the Kalman filter here to predict where the digit centroid
    % shoud be next to narrow down where to move the mask from the previous
    % detection
    curr_paw_mask_mirror = imdilate(tracks(11).currentMask, strel('disk', maxDistPerFrame)) & thresh_mask;
    curr_paw_mask_mirror = bwdist(curr_paw_mask_mirror) < 2;
    curr_paw_mask_mirror = imopen(curr_paw_mask_mirror, SE);
    curr_paw_mask_mirror = imclose(curr_paw_mask_mirror, SE);
    curr_paw_mask_mirror = imfill(curr_paw_mask_mirror, 'holes');
    curr_paw_mask_mirror = imdilate(curr_paw_mask_mirror, strel('disk',6));
    
    % within that mask, look for regions that match with the previous digit
    % colors
    currentDigitMirrorMask = false(h,w,num_elements_to_track);
    for ii = 2 : num_elements_to_track    % do the digits first
        curr_mirror_img_enh = enhanceColorImage(image, ...
                                                decorrStretchMean_mirror(ii,:), ...
                                                decorrStretchSigma_mirror(ii,:), ...
                                                'mask', curr_paw_mask_mirror);
        prev_digit_mask = imdilate(tracks(ii).currentMask, strel('disk',maxDistPerFrame)) & thresh_mask;
        prev_digit_mask = bwdist(prev_digit_mask) < 2;
        prev_digit_mask = imopen(prev_digit_mask, SE);
        prev_digit_mask = imclose(prev_digit_mask, SE);
        prev_digit_mask = imfill(prev_digit_mask, 'holes');
        
        curr_mirror_digImg_enh = curr_mirror_img_enh .* double(repmat(prev_digit_mask,1,1,3));
        RGBdistMap = RGBzdist(curr_mirror_digImg_enh, ...
                              tracks(ii).meanRGBenh, ...
                              tracks(ii).stdRGBenh);
        currentDigitMirrorMask(:,:,ii) = (RGBdistMap < color_zlim);
        currentDigitMirrorMask(:,:,ii) = imerode(currentDigitMirrorMask(:,:,ii), strel('disk',2));
                          
    end
    masked_mirror_img = uint8(repmat(curr_paw_mask_mirror,1,1,3));
    masked_mirror_img = masked_mirror_img  .* image;
    masked_mirror_img_enh = enhanceColorImage(masked_mirror_img, ...
                                              decorrStretchMean_mirror(2,:), ...
                                              decorrStretchSigma_mirror(2,:), ...
                                              'mask',prev_paw_mask_mirror);
    [~,mirror_P] = imseggeodesic(masked_mirror_img_enh, currentDigitMirrorMask(:,:,2), currentDigitMirrorMask(:,:,3), currentDigitMirrorMask(:,:,4));
    [~,mirror_P2] = imseggeodesic(masked_mirror_img_enh, currentDigitMirrorMask(:,:,3), currentDigitMirrorMask(:,:,4), currentDigitMirrorMask(:,:,5));
        
    % CURRENT PROBLEM - HOW TO THRESHOLD BASED ON COLOR? BEST WAY MAY BE TO
    % GO THROUGH EACH DIGIT AND PAW DORSUM SEPARATELY TO GENERATE A MASK,
    % THEN ASK WHETHER THAT MASK IS LIKELY TO HAVE BEEN PARTIALLY OCCLUDED
    % BY THE FRONT OF THE BOX
%     newMask = false(h,w);
%     for ii = 1 : num_elements_to_track   % threshold for each digit/dorsum of the paw to eliminate blobs
%                                          % that represent movement but
%                                          % couldn't be the paw
%         curr_mirror_img_enh = enhanceColorImage(image, ...
%                                                 decorrStretchMean_mirror(ii,:), ...
%                                                 decorrStretchSigma_mirror(ii,:), ...
%                                                 'mask', curr_paw_mask_mirror);
%         mirror_RGBz = zeros(h,w,3);
%         for jj = 1 : 3
%             colPlane = squeeze(curr_mirror_img_enh(:,:,jj));
%             mirror_RGBz(:,:,jj) = (colPlane - tracks(ii).meanRGBenh(jj)) / ...
%                 tracks(ii).stdRGBenh(jj);
%         end
%         mirror_RGBzdist = sqrt(sum(mirror_RGBz.^2, 3));
%         newMask = newMask | (mirror_RGBzdist < color_zlim);
%         
%     end
%     SE = strel('disk',2');
%     newMask = imopen(newMask, SE);
%     newMask = imclose(newMask, SE);
%     newMask = imfill(newMask, 'holes');
    % 
    
%     % do a color enhancement and threshold just to eliminate anything that
%     % moves but doesn't look like paw (for example, dark fur on the arm)
%     curr_mirror_img_enh = enhanceColorImage(image, ...
%                                             decorrStretchMean_mirror(1,:), ...
%                                             decorrStretchSigma_mirror(1,:), ...
%                                             'mask', curr_paw_mask_mirror);
    
    % now figure out if part of the paw is hidden behind the front panel
    s = regionprops(curr_paw_mask_mirror,'Area','BoundingBox', 'Centroid','ConvexHull','ConvexImage');
    if length(s) > 1
        [fullMask, fullHull] = multiRegionConvexHullMask(curr_paw_mask_mirror);
        % does the full mask overlap with the front panel?
        testMask = (boxFrontMask & fullMask);
        if any(testMask(:))
            % do some crude thresholding to determine 
        end
        
    end
    
    masked_mirror_img = uint8(repmat(prev_paw_mask_mirror,1,1,3));
    masked_mirror_img = masked_mirror_img  .* image;

    masked_center_img = uint8(repmat(prev_paw_mask_center,1,1,3));
    masked_center_img = masked_center_img  .* image;
    

    mirror_zmask = false(h,w,num_elements_to_track);
    center_zmask = false(h,w,num_elements_to_track);
    for ii = 2 : num_elements_to_track    % do all the digits first
        masked_mirror_img_enh = enhanceColorImage(masked_mirror_img, ...
                                                  decorrStretchMean_mirror(ii,:), ...
                                                  decorrStretchSigma_mirror(ii,:), ...
                                                  'mask',prev_paw_mask_mirror);
        masked_mirror_hsv = rgb2hsv(masked_mirror_img_enh);

        masked_center_img_enh = enhanceColorImage(masked_center_img, ...
                                                  decorrStretchMean_center(ii,:), ...
                                                  decorrStretchSigma_center(ii,:), ...
                                                  'mask',prev_paw_mask_center);
        masked_center_hsv = rgb2hsv(masked_center_img_enh);
        
        mirror_bbox = step(tracks(ii).CAMshiftTracker, masked_mirror_hsv(:,:,1));
        center_bbox = step(tracks(ii+num_elements_to_track).CAMshiftTracker, masked_center_hsv(:,:,1));
        
        % create a "scribble" mask for each digit using the previous
        % meanRGB values for that digit. Look only within the bounding box
        % defined by the histogram tracker
        mirror_bboxMask = false(h,w);
        center_bboxMask = false(h,w);
        mirror_bboxMask(mirror_bbox(2):mirror_bbox(2)+mirror_bbox(4)-1,...
                        mirror_bbox(1):mirror_bbox(1)+mirror_bbox(3)-1) = true;
        center_bboxMask(center_bbox(2):center_bbox(2)+center_bbox(4)-1,...
                        center_bbox(1):center_bbox(1)+center_bbox(3)-1) = true;
        mirror_RGBz = zeros(h,w,3);
        center_RGBz = zeros(h,w,3);
        for jj = 1 : 3
            colPlane = squeeze(masked_mirror_img_enh(:,:,jj));
            mirror_RGBz(:,:,jj) = (colPlane - tracks(ii).meanRGBenh(jj)) / ...
                tracks(ii).stdRGBenh(jj);
            
            colPlane = squeeze(masked_center_img_enh(:,:,jj));
            center_RGBz(:,:,jj) = (colPlane - tracks(ii+num_elements_to_track).meanRGBenh(jj)) / ...
                tracks(ii+num_elements_to_track).stdRGBenh(jj);
        end
        
        mirror_RGBzdist = sqrt(sum(mirror_RGBz.^2, 3));
        center_RGBzdist = sqrt(sum(center_RGBz.^2, 3));
        
        mirror_zmask(:,:,ii) = (abs(mirror_RGBzdist) < color_zlim);
        center_zmask(:,:,ii) = (abs(center_RGBzdist) < color_zlim);
        
        mirror_zmask(:,:,ii) = mirror_zmask(:,:,ii) & mirror_bboxMask;
        center_zmask(:,:,ii) = center_zmask(:,:,ii) & center_bboxMask;
        
    end
    masked_mirror_img_enh = enhanceColorImage(masked_mirror_img, ...
                                              decorrStretchMean_mirror(2,:), ...
                                              decorrStretchSigma_mirror(2,:), ...
                                              'mask',prev_paw_mask_center);
    [~,mirror_P] = imseggeodesic(masked_mirror_img_enh, mirror_zmask(:,:,2), mirror_zmask(:,:,3), mirror_zmask(:,:,4));
    [~,mirror_P2] = imseggeodesic(masked_mirror_img_enh, mirror_zmask(:,:,3), mirror_zmask(:,:,4), mirror_zmask(:,:,5));
    
    masked_center_img_enh = enhanceColorImage(masked_center_img, ...
                                              decorrStretchMean_center(2,:), ...
                                              decorrStretchSigma_center(2,:), ...
                                              'mask',prev_paw_mask_center);
    [~,center_P] = imseggeodesic(masked_center_img_enh, center_zmask(:,:,2), center_zmask(:,:,3), center_zmask(:,:,4));
    [~,center_P2] = imseggeodesic(masked_center_img_enh, center_zmask(:,:,3), center_zmask(:,:,4), center_zmask(:,:,5));
        
    mirrorMask = false(h,w,num_elements_to_track);
    centerMask = false(h,w,num_elements_to_track);
    SE = strel('disk',2);
    for ii = 2 : num_elements_to_track
        switch ii,
            case 2,   % index finger
                mirrorMask(:,:,ii) = (mirror_P(:,:,1) > pthresh);
                centerMask(:,:,ii) = (center_P(:,:,1) > pthresh);
            case 3,   % middle finger
                mirrorMask(:,:,ii) = (mirror_P(:,:,2) > pthresh);
                centerMask(:,:,ii) = (center_P(:,:,2) > pthresh);
            case 4,   % ring finger
                mirrorMask(:,:,ii) = (mirror_P2(:,:,2) > pthresh);
                centerMask(:,:,ii) = (center_P2(:,:,2) > pthresh);
            case 5,   % pinky finger
                mirrorMask(:,:,ii) = (mirror_P2(:,:,3) > pthresh);
                centerMask(:,:,ii) = (center_P2(:,:,3) > pthresh);
        end
    
        mirrorMask(:,:,ii) = imopen(mirrorMask(:,:,ii), SE);
        mirrorMask(:,:,ii) = imclose(mirrorMask(:,:,ii), SE);
        mirrorMask(:,:,ii) = imfill(mirrorMask(:,:,ii), 'holes');
        
        centerMask(:,:,ii) = imopen(centerMask(:,:,ii), SE);
        centerMask(:,:,ii) = imclose(centerMask(:,:,ii), SE);
        centerMask(:,:,ii) = imfill(centerMask(:,:,ii), 'holes');
        
    end
    
    % we have the previous paw mask, let's assume

    
    masked_mirror_img_enh = enhanceColorImage(masked_mirror_img, ...    % for paw dorsum
                                              decorrStretchMean_center(1,:), ...
                                              decorrStretchSigma_center(1,:), ...
                                              'mask',prev_paw_mask_center);
        
        
%         mirror_idx = find(mirror_bboxMask);
%         center_idx = find(center_bboxMask);
%         
%         RGBdist = zeros(h,w);
%         for jj = 1 : 3
%             masked_mirror_img_enh(mirror_bbox(2):mirror_bbox(2)+mirror_bbox(4)-1,...
%                         mirror_bbox(1):mirror_bbox(1)+mirror_bbox(3)-1)
%             colPlane = squeeze(masked_mirror_img_enh(:,:,jj));
%             mirror_RGBdist(jj) = colPlane(mirror_idx) - tracks(ii).meanRGBenh(jj);
%             
%             colPlane = squeeze(masked_center_img_enh(:,:,jj));
%             center_RGBdist(jj) = colPlane(center_idx) - tracks(ii+num_elements_to_track).meanRGBenh(jj);
%         end
% %         mirror_RGBdist = 
%         figure(1)
%         rectangle('position',mirror_bbox,'edgecolor','r');
%         rectangle('position',center_bbox,'edgecolor','r');
%         
%         figure(2)
%         if ii == 1
%             imshow(masked_mirror_img_enh)
%         end
%         rectangle('position',mirror_bbox,'edgecolor','r');
%         
%         figure(3)
%         if ii == 1
%             imshow(masked_center_img_enh)
%         end
%         rectangle('position',center_bbox,'edgecolor','r');
    
        
%     paw_mask = maskPaw_moving(image, BGimg, prev_paw_mask, register_ROI, F, rat_metadata, boxMarkers);
%     diff_image  = imabsdiff(image, BGimg);
%     thresh_mask = (rgb2gray(diff_image) > diff_threshold);
%     
%     curr_mask = thresh_mask & prev_paw_mask;
%     
%     hsv_image = rgb2hsv(image.*uint8(repmat(curr_mask,1,1,3)));
%     figure(1)
%     imshow(image)
%     hold on

%     for ii = 1 : numTracks
%         bbox = step(tracks(ii).CAMshiftTracker, hsv_image(:,:,1));
%         rectangle('position',bbox,'edgecolor','r');
%     end
%     paw_mask = maskPaw_moving(image, BGimg, digitMirrorMask_dorsum, digitCenterMask, register_ROI, F, rat_metadata, boxMarkers);
    
    
%     figure(2)
%     imshow(image);
end
% detector = vision.ForegroundDetector(...
%    'NumTrainingFrames', 50, ... % 5 because of short video
%    'InitialVariance', 30*30); % initial standard deviation of 30
% blob = vision.BlobAnalysis(...
%    'CentroidOutputPort', false, 'AreaOutputPort', false, ...
%    'BoundingBoxOutputPort', true, ...
%    'MinimumBlobAreaSource', 'Property', 'MinimumBlobArea', 200);

sTime = (peakFrameNum / video.FrameRate);
figure(1)
frameNum = 0;
while video.CurrentTime < video.Duration
    image = readFrame(video);
    fgMask = step(detector, image);
    imshow(fgMask);
    frameNum = frameNum + 1;
end
mirrorTracks_dorsum = initializeTracks();
centerTracks        = initializeTracks();

% rewind 
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tracks = initializeTracks()
    % create an empty array of tracks
    tracks = struct(...
        'id', {}, ...
        'bbox', {}, ...
        'kalmanFilter', {}, ...
        'CAMshiftTracker', {}, ...
        'meanRGBenh', {}, ...
        'stdRGBenh', {}, ...
        'currentMask', {}, ...
        'age', {}, ...
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