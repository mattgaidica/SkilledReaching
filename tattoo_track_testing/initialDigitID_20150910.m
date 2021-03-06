function [viewMask, mask_bbox, digitMarkers, refImageTime, dig_edge3D] = ...
    initialDigitID_20150910(video, triggerTime, BGimg_ud, rat_metadata, boxCalibration, varargin)
%
% usage
%
% function to find the initial location of the paw and digits in an image
% with a clear view of the paw in the mirrors and direct view. It will
% continue to look for an image where all the digits are clearly visible in
% both views until it finds one.
%
% INPUTS:
%   video - videoReader object
%   triggerTime - time (in seconds) at which a substantial portion of the
%       paw appears in the mirror view
%   BGimg_ud - undistorted background image
%   pawMask - mask of the paw in the appropriate mirror (logical matrix)
%   rat_metadata - needed to know whether to look to the left or right of
%       the dorsal aspect of the paw to exclude points that can't be digits
%
% VARARGS:
%
% OUTPUTS:
%   viewMask - cell array. viewMask{1} for the left mirror, viewMask{2} is
%       the direct view, viewMask{3} is the right mirror. These are binary
%       masks the size of the bounding box around the initial paw masking
%   mask_bbox - 3 x 4 matrix, where each row contains the bounding box for
%       each viewMask. Format of each row is [x,y,w,h], where x,y is the
%       upper left corner of the bounding box, and w and h are the
%       width
%       and height, respectively
%   digitMarkers - 5x2x3x2 array. First dimension is the digit ID, second
%       dimension is (x,y), third dimension is proximal,centroid,tip of
%       each digit, 4th dimension is the view (1 = direct, 2 = mirror)
%   refImageTime - the time in the video at which the reference image was
%       taken

% TO DO - MODIFY DIGITMARKERS TO INCLUDE THE PAW DORSUM






% NEED TO ADJUST THE VALUES TO ENHANCE THE DESIRED PAW BITS
decorrStretchMean  = cell(1,3);
decorrStretchSigma = cell(1,3);
decorrStretchMean{1}  = [127.5 127.5 127.5     % to isolate dorsum of paw
                         127.5 127.5 100.0     % to isolate blue digits
                         100.0 127.5 127.5     % to isolate red digits
                         100.0 025.0 100.0     % to isolate green digits
                         100.0 127.5 127.5     % to isolate red digits
                         127.5 127.5 127.5
                         127.5 127.5 127.5];

decorrStretchSigma{1} = [075 075 075       % to isolate dorsum of paw
                         075 075 075       % to isolate blue digits
                         075 075 075       % to isolate red digits
                         075 075 075       % to isolate green digits
                         075 075 075       % to isolate red digits
                         075 075 075
                         075 075 075];
                     
decorrStretchMean{2}  = [127.5 127.5 127.5     % to isolate dorsum of paw
                         127.5 127.5 100.0     % to isolate blue digits
                         100.0 127.5 127.5     % to isolate red digits
                         127.5 100.0 127.5     % to isolate green digits
                         100.0 127.5 127.5     % to isolate red digits
                         127.5 127.5 127.5
                         127.5 127.5 127.5];
                     
decorrStretchSigma{2} = [075 075 075       % to isolate dorsum of paw
                         075 075 075       % to isolate blue digits
                         075 075 075       % to isolate red digits
                         075 075 075       % to isolate green digits
                         075 075 075       % to isolate red digits
                         075 075 075
                         075 075 075];
                     
decorrStretchMean{3}  = [127.5 127.5 127.5     % to isolate dorsum of paw
                         127.5 127.5 100.0     % to isolate blue digits
                         100.0 127.5 127.5     % to isolate red digits
                         127.5 100.0 127.5     % to isolate green digits
                         100.0 127.5 127.5     % to isolate red digits
                         127.5 127.5 127.5
                         127.5 127.5 127.5];
                     
decorrStretchSigma{3} = [075 075 075       % to isolate dorsum of paw
                         075 075 075       % to isolate blue digits
                         075 075 075       % to isolate red digits
                         075 075 075       % to isolate green digits
                         075 075 075       % to isolate red digits
                         075 075 075
                         075 075 075];
                     
for ii = 1 : 3
    decorrStretchMean{ii} = decorrStretchMean{ii} / 255;
    decorrStretchSigma{ii} = decorrStretchSigma{ii} / 255;
end

diff_threshold = 45 / 255;

mirrorPawBlob = vision.BlobAnalysis;
mirrorPawBlob.AreaOutputPort = true;
mirrorPawBlob.CentroidOutputPort = true;
mirrorPawBlob.BoundingBoxOutputPort = true;
mirrorPawBlob.ExtentOutputPort = true;
mirrorPawBlob.LabelMatrixOutputPort = true;
mirrorPawBlob.MinimumBlobArea = 2500;
mirrorPawBlob.MaximumBlobArea = 30000;

centerPawBlob = vision.BlobAnalysis;
centerPawBlob.AreaOutputPort = true;
centerPawBlob.CentroidOutputPort = true;
centerPawBlob.BoundingBoxOutputPort = true;
centerPawBlob.ExtentOutputPort = true;
centerPawBlob.LabelMatrixOutputPort = true;
centerPawBlob.MinimumBlobArea = 3000;
centerPawBlob.MaximumBlobArea = 30000;

centerDigitBlob = vision.BlobAnalysis;
centerDigitBlob.AreaOutputPort = true;
centerDigitBlob.CentroidOutputPort = true;
centerDigitBlob.BoundingBoxOutputPort = true;
centerDigitBlob.ExtentOutputPort = true;
centerDigitBlob.LabelMatrixOutputPort = true;
centerDigitBlob.MinimumBlobArea = 100;
centerDigitBlob.MaximumBlobArea = 30000;

mirrorDigitBlob = vision.BlobAnalysis;
mirrorDigitBlob.AreaOutputPort = true;
mirrorDigitBlob.CentroidOutputPort = true;
mirrorDigitBlob.BoundingBoxOutputPort = true;
mirrorDigitBlob.ExtentOutputPort = true;
mirrorDigitBlob.LabelMatrixOutputPort = true;
mirrorDigitBlob.MinimumBlobArea = 50;
mirrorDigitBlob.MaximumBlobArea = 30000;

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

colorList = {'darkgreen','blue','red','green','red'};
satLimits{1} = [0.20000    1.00
             0.90000    1.00
             0.90000    1.00
             0.90000    1.00
             0.90000    1.00];
valLimits{1} = [0.20000    1.00
             0.95000    1.00
             0.95000    1.00
             0.95000    1.00
             0.95000    1.00];
hueLimits{1} = [0.00, 0.16;    % red
             0.33, 0.16;    % green
             0.66, 0.05;    % blue
             0.50, 0.16];   % dark green
         
satLimits{2} = [0.20000    1.00
             0.90000    1.00
             0.90000    1.00
             0.90000    1.00
             0.90000    1.00];
valLimits{2} = [0.20000    1.00
             0.95000    1.00
             0.95000    1.00
             0.95000    1.00
             0.95000    1.00];
hueLimits{2} = [0.00, 0.16;    % red
             0.33, 0.16;    % green
             0.66, 0.05;    % blue
             0.33, 0.16];   % dark green
         
satLimits{3} = [0.20000    1.00
             0.90000    1.00
             0.90000    1.00
             0.90000    1.00
             0.90000    1.00];
valLimits{3} = [0.20000    1.00
             0.95000    1.00
             0.95000    1.00
             0.95000    1.00
             0.95000    1.00];
hueLimits{3} = [0.00, 0.16;    % red
             0.33, 0.16;    % green
             0.66, 0.05;    % blue
             0.50, 0.16];   % dark green

h = video.Height;
w = video.Width;

dorsumAngle = -3*pi/8;
% further down, will draw a line between the base of the 1st and 4th
% digits. The paw dorsum is assumed to lie on one side of this line,
% constrained by the geometry of the reach.

boxMarkers = boxCalibration.boxMarkers;
F = boxCalibration.F;

register_ROI = boxMarkers.register_ROI;

pawPref = lower(rat_metadata.pawPref);
if iscell(pawPref)
    pawPref = pawPref{1};
end

minSideOverlap = 0.25;   % mirror image projection into the direct view must
                        % overlap by this much to be counted
                        
numViews = 3;

trackCheck.maxEpiLineDist = 10;     % how far a point in the mirror view can be from the epipolar line passing through the corresponding point in the direct view
raw_threshold = 0.2;

for iarg = 1 : 2 : nargin - 5
    switch lower(varargin{iarg})
        case 'diffthreshold',
            diff_threshold = varargin{iarg + 1};
        case 'decorrstretchmean',
            decorrStretchMean = varargin{iarg + 1};
        case 'decorrstretchsigma',
            decorrStretchSigma = varargin{iarg + 1};
        case 'colorlist',
            colorList = varargin{iarg + 1};
        case 'minsideoverlap',
            minSideOverlap = varargin{iarg + 1};
        case 'minmirrorpawarea',
            mirrorPawBlob.MinimumBlobArea = varargin{iarg + 1};
        case 'maxmirrorpawarea',
            mirrorPawBlob.MaximumBlobArea = varargin{iarg + 1};
        case 'maxEpiLineDist',
            trackCheck.maxEpiLineDist = varargin{iarg + 1};
        case 'blackthreshold',
            raw_threshold = varargin{iarg + 1};    % values smaller than this are too black to be the paw in the raw image
            % NEED TO CLEAN UP THE REST OF THE VARARGINS...
    end
end

if diff_threshold > 1
    diff_threshold = diff_threshold / 255;
end

if raw_threshold > 1
    raw_threshold = raw_threshold / 255;
end

S = whos('BGimg_ud');
if strcmpi(S.class,'uint8')
    BGimg_ud = double(BGimg_ud) / 255;
end

vidName = fullfile(video.Path, video.Name);
video = VideoReader(vidName);
video.CurrentTime = triggerTime;

switch pawPref
    case 'left',
        dMirrorIdx = 3;   % index of mirror with dorsal view of paw
        pMirrorIdx = 1;   % index of mirror with palmar view of paw
        F_side = F.right;
        dorsumAngle = -dorsumAngle;
    case 'right',
        dMirrorIdx = 1;   % index of mirror with dorsal view of paw
        pMirrorIdx = 3;   % index of mirror with palmar view of paw
        F_side = F.left;
end
    
digitMissing = true;

[mirror_shelf_mask, center_region_mask] = reach_region_mask(boxMarkers, [h,w]);

numObjects = size(decorrStretchMean{1}, 1) - 2;
numFramesChecked = 0;

blueBeadMask = boxMarkers.beadMasks(:,:,3);
while digitMissing
    numFramesChecked = numFramesChecked  + 1;
    fprintf('number of frames: %d\n',numFramesChecked)
    
    
    
    image = readFrame(video);
    image_ud = undistortImage(image, boxCalibration.cameraParams);
    image_ud = double(image_ud) / 255;
    BG_diff = imabsdiff(BGimg_ud,image_ud);

    figure(4);imshow(image_ud);
    
    
    BG_mask = false(h,w);
    for iCh = 1 : 3
        BG_mask = BG_mask | (squeeze(BG_diff(:,:,iCh)) > diff_threshold);
    end

    SE = strel('disk',2);
    mirrorMask = BG_mask & mirror_shelf_mask;
    mirrorMask = bwdist(mirrorMask) < 2;
    mirrorMask = imopen(mirrorMask, SE);
    mirrorMask = imclose(mirrorMask,SE);
    mirrorMask = imfill(mirrorMask,'holes');
    
    if ~any(mirrorMask(:)); continue; end

    % keep only the largest mirror mask blobs
    leftMask = false(h,w);
    leftMask(:,1:round(w/2)) = true;
    leftMirrorMask = mirrorMask & leftMask;
    rightMirrorMask = mirrorMask & ~leftMask;
    [left_A,~,~,~,leftLabMat] = step(mirrorPawBlob, leftMirrorMask);
    if isempty(left_A); continue; end   % too small a blob detected in the reaching area
    
    idx = find(left_A == max(left_A));
    leftMirrorPawMask = (leftLabMat == idx);

    [right_A,~,~,~,rightLabMat] = step(mirrorPawBlob, rightMirrorMask);
    if isempty(right_A); continue; end   % too small a blob detected in the reaching area
    idx = find(right_A == max(right_A));
    rightMirrorPawMask = (rightLabMat == idx);

    mirrorMask = leftMirrorPawMask | rightMirrorPawMask;
    
    leftProjMask  = pawProjectionMask(leftMirrorPawMask, F.left', [h,w]);
    rightProjMask = pawProjectionMask(rightMirrorPawMask, F.right', [h,w]);

    projMask = (leftProjMask & rightProjMask);
    projMask = imdilate(projMask,strel('disk',10));
    
    grayMask = false(h,w);
    for iColor = 1 : 3
        grayMask = grayMask | (image_ud(:,:,iColor) > raw_threshold);
    end
    BG_mask = BG_mask & grayMask;
    centerMask = projMask & BG_mask & center_region_mask;
    centerMask = bwdist(centerMask) < 2;
    centerMask = imopen(centerMask, SE);
    centerMask = imclose(centerMask,SE);
    centerMask = imfill(centerMask,'holes');
    
    % find a region that includes bright green
    rgb_enh = enhanceColorImage(image_ud, ...
                                decorrStretchMean{2}(4,:), ...
                                decorrStretchSigma{2}(4,:), ...
                                'mask',centerMask);
	tempMask = HSVthreshold(rgb2hsv(rgb_enh), ...
                            [hueLimits{2}(2,:), satLimits{2}(4,:), valLimits{2}(4,:)]);                    
	tempMask = tempMask & centerMask;
    [A,~,~,~,labMat] = step(centerDigitBlob, tempMask);
    if isempty(A); continue; end
    
    idx = find(A == max(A));
    tempMask = (labMat == idx);   % make sure there's only one green blob so imreconstruct doesn't get confused
    
    centerMask = imreconstruct(tempMask, centerMask);
    [A,~,~,~,~] = step(centerPawBlob, centerMask);
    if isempty(A);
        continue;
    end

    BG_mask = mirrorMask | centerMask;

    masked_hsv_enh = cell(numViews,1);
    rgb_enh = cell(numViews,1);
    dMask = cell(numViews,1);
    mask_bbox = zeros(numViews,4);
    for iView = 1 : numViews
            
        switch iView
            case 1,
                mask = (leftMask & mirror_shelf_mask) & BG_mask;
            case 2,
                mask = center_region_mask & BG_mask;
            case 3,
                mask = (~leftMask & mirror_shelf_mask) & BG_mask;
        end
        mask = mask & BG_mask;
        % find the bounding box for the current region
        S = regionprops(mask, 'boundingbox');
        mask_bbox(iView,:) = floor(S.BoundingBox) - 10;
        mask_bbox(iView,3:4) = mask_bbox(iView,3:4) + 30;
        
        if iView == pMirrorIdx; continue; end    % don't bother with the palmar view
        
        mask = mask(mask_bbox(iView,2):mask_bbox(iView,2) + mask_bbox(iView,4), ...
                    mask_bbox(iView,1):mask_bbox(iView,1) + mask_bbox(iView,3));
        rgbMask = double(repmat(mask,1,1,3));

        masked_hsv_enh{iView} = zeros(mask_bbox(iView,4)+1, ...
                                      mask_bbox(iView,3)+1, ...
                                      3, numObjects);
        rgb_enh{iView} = zeros(mask_bbox(iView,4)+1, ...
                                      mask_bbox(iView,3)+1, ...
                                      3, numObjects);
        dMask{iView} = false(mask_bbox(iView,4)+1, ...
                             mask_bbox(iView,3)+1, ...
                             numObjects);
        for ii = 1 : numObjects
            im_bbox = image_ud(mask_bbox(iView,2):mask_bbox(iView,2) + mask_bbox(iView,4), ...
                               mask_bbox(iView,1):mask_bbox(iView,1) + mask_bbox(iView,3),:);
            rgb_enh{iView}(:,:,:,ii) = enhanceColorImage(im_bbox, ...
                                        decorrStretchMean{iView}(ii,:), ...
                                        decorrStretchSigma{iView}(ii,:), ...
                                        'mask',mask);
%                                     figure(1);imshow(rgb_enh);figure(2);imshow(rgb2hsv(rgb_enh));

            masked_hsv_enh{iView}(:,:,:,ii) = rgb2hsv(rgbMask .* rgb_enh{iView}(:,:,:,ii));
        end
    end

    SE = strel('disk',2);

    numSameColorObjects = zeros(numObjects, 1);
    isDigitVisible = true(numObjects,3);
    for ii = 2 : numObjects
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
        sameColIdx = find(strcmp(colorList{ii},colorList));
        numSameColorObjects(ii) = length(sameColIdx);

        for iView = 1 : numViews
            if iView == pMirrorIdx; continue; end    % don't bother with the palmar view
           
            if any(sameColIdx < ii)   % if mask already computed for a color, use the previous mask
                lastColIdx = max(sameColIdx(sameColIdx < ii));
                tempMask = squeeze(dMask{iView}(:,:,lastColIdx));
            else
                tempMask = HSVthreshold(squeeze(masked_hsv_enh{iView}(:,:,:,ii)), ...
                                        [hueLimits{iView}(colorIdx,:), satLimits{iView}(ii,:), valLimits{iView}(ii,:)]);

                regMask = projMask | mirrorMask;
                regMask = regMask(mask_bbox(iView,2) : mask_bbox(iView,2) + mask_bbox(iView,4), ...
                                  mask_bbox(iView,1) : mask_bbox(iView,1) + mask_bbox(iView,3));
                tempMask = tempMask & regMask;

                if ~any(tempMask(:))
                    isDigitVisible(ii, iView) = false;
                    break;
                end
                
                if strcmpi(colorList{ii},'blue')
                    bbox_blueBeadMask = blueBeadMask(mask_bbox(iView,2) : mask_bbox(iView,2) + mask_bbox(iView,4), ...
                                                     mask_bbox(iView,1) : mask_bbox(iView,1) + mask_bbox(iView,3));
                    % eliminate any identified blue regions that overlap with blue
                    % beads
                    tempMask = tempMask & ~bbox_blueBeadMask;% squeeze(boxMarkers.beadMasks(:,:,3));
                end

                tempMask = imopen(tempMask, SE);
                tempMask = imclose(tempMask, SE);
                tempMask = imfill(tempMask, 'holes');

                % take only the largest n blobs from each view, where n is the number of blobs that should have the same color
                % ALTERNATIVE APPROACH - CAN WE KEEP ALL THE BLOBS, THEN
                % MATCH THEM ACCORDING TO WHETHER THEY APPEAR IN BOTH
                % VIEWS?
                if iView == 2
                    blobObject = centerDigitBlob;
                else
                    blobObject = mirrorDigitBlob;
                end
                [A,~,~,~,labMat] = step(blobObject, tempMask);
                if ~isempty(A)
                    [~,idx] = sort(A, 'descend');
                    tempMask = false(size(tempMask));
                    if (length(idx) < numSameColorObjects(ii)) && (iView ~= pMirrorIdx)   % OK if can't identify a digit independently in the palmar view
                        % all the digits weren't identified
                        isDigitVisible(ii,iView) = false;  % didn't find the ii'th digit in iView
                        break;
                    end
                    for kk = 1 : min(numSameColorObjects(ii), length(idx))
                        tempMask = tempMask | (labMat == idx(kk));
                    end
                end
            end
            
            % make sure digits don't overlap with each other
            overlapMask = dMask{iView}(:,:,ii-1) & tempMask;
            dMask{iView}(:,:,ii-1) = dMask{iView}(:,:,ii-1) & ~overlapMask;
            tempMask = tempMask & ~overlapMask;
            
            if ~any(tempMask(:))
                isDigitVisible(ii, iView) = false;
                break;
            end

            dMask{iView}(:,:,ii) = tempMask;

        end

        if any(~isDigitVisible(:))   % one of the digits isn't visible in one of the views
            break
        end

    end    % for ii = 2 : numObjects

    if any(~isDigitVisible(:))   % one of the digits isn't visible in one of the views
        continue   % go back and try the next video frame
    end

    fullDigitMask = cell(numViews,1);
    viewMask = cell(numViews,1);
    hsv = cell(1,2);
    for iView = 1 : numViews
        if iView == pMirrorIdx; continue; end    % don't bother with the palmar view
        
        fullDigitMask{iView} = false(mask_bbox(iView,4)+1,mask_bbox(iView,3)+1);
        viewMask{iView} = false(mask_bbox(iView,4)+1,mask_bbox(iView,3) + 1,numObjects+1);
        
        for ii = 2 : numObjects
            tempMask = imerode(dMask{iView}(:,:,ii),strel('disk',1));
            % make sure erosion didn't separate a single digit blob into
            % multiple blobs
%             if iView == 2
%                 blobObject = centerDigitBlob;
%             else
%                 blobObject = mirrorDigitBlob;
%             end
            labMat = bwlabel(tempMask);
            s = regionprops(tempMask,'area');
            A = [s.Area];
            [~,idx] = sort(A, 'descend');
            tempMask = false(size(tempMask));
            if (length(idx) < numSameColorObjects(ii)) && (iView ~= pMirrorIdx)   % OK if can't identify a digit independently in the palmar view
                % all the digits weren't identified
                isDigitVisible(ii,iView) = false;  % didn't find the ii'th digit in iView
                break;
            end
            for kk = 1 : min(numSameColorObjects(ii), length(idx))
                tempMask = tempMask | (labMat == idx(kk));
            end
            fullDigitMask{iView} = fullDigitMask{iView} | tempMask;
            viewMask{iView}(:,:,ii) = tempMask;
        end
    end

    if any(~isDigitVisible(:))   % one of the digits isn't visible in one of the views
        continue   % go back and try the next video frame
    end
    
    % check that centroids of blobs in different views lie on the same
    % epipolar lines
    if dMirrorIdx == 1
        dorsum_F = boxCalibration.F.left;
    else
        dorsum_F = boxCalibration.F.right;
    end
    areBlobsAligned = checkEpipolarAlignment(viewMask, ...
                                             dorsum_F, ...
                                             trackCheck, ...
                                             dMirrorIdx, ...
                                             mask_bbox, ...
                                             [h,w]);
	if any(~areBlobsAligned)
        continue;
    end
    
    for iView = 1 : numViews
        if iView == pMirrorIdx; continue; end    % don't bother with the palmar view
        
        % now need to assign blobs that are the same color to the appropriate digit
        % start with the index finger
        s = regionprops(fullDigitMask{iView},'centroid');
        fv_centroids = [s.Centroid];
        fv_centroids = round(reshape(fv_centroids,2,[]))';   % now an m x 2 array where each row is another centroid
        if numSameColorObjects(2) > 1   % if equal to 1, viewMask{iView}(:,:,2) already contains the mask of only the index finger
            [ctr_distances,pts_idx] = calcDistancesBetweenPoints(fv_centroids);
            maxDistPts = pts_idx((ctr_distances == max(ctr_distances)),:);
            
            % now find the overlap between dMask(:,:,2) and the centroids
            % that are furthest apart. That overlap should be the index
            % finger as long as the index and pinkies are different colors
            % and both digits were found in the current image
            for jj = 1 : 2
                regionMarker = false(size(fullDigitMask{iView}));
                regionMarker(fv_centroids(maxDistPts(jj),2), fv_centroids(maxDistPts(jj),1)) = true;
                tempMask = regionMarker & viewMask{iView}(:,:,2);
                if any(tempMask(:))
                    viewMask{iView}(:,:,2) = imreconstruct(regionMarker, viewMask{iView}(:,:,2));
                end
            end
        end
        
        % now that we have the index finger, can assign the rest of the
        % digits.
        
        for jj = 3 : numObjects

            if numSameColorObjects(jj) > 1   % if equal to 1, viewMask{iView}(:,:,jj) already contains the mask of only the index finger
                tempMask = viewMask{iView}(:,:,jj);
                for kk = 2 : jj-1
                    tempMask = tempMask & ~viewMask{iView}(:,:,kk);    % eliminate blobs already assigned to a digit
                end
                s = regionprops(tempMask);
                cd_centroids = [s.Centroid];    % current digit centroids
                cd_centroids = reshape(cd_centroids,2,[])';   % now an m x 2 array where each row is another centroid
                
                s = regionprops(viewMask{iView}(:,:,jj-1));
                pd_centroid = [s.Centroid];    % previous digit centroid

                centroids = round([pd_centroid; cd_centroids]);
                [~,~,nnidx] = nearestNeighbor(centroids);
                
                regionMarker = false(size(fullDigitMask{iView}));
                regionMarker(centroids(nnidx(1),2), centroids(nnidx(1),1)) = true;
                
                viewMask{iView}(:,:,jj) = imreconstruct(regionMarker, viewMask{iView}(:,:,jj));
            end
        end    % for jj = 3 : numObjects
      
    end    % for iView
    if any(~isDigitVisible(:)); continue; end
    
    [digitMarkers, dorsumRegionMask] = ...
        findInitDorsumRegion(viewMask, pawPref, dorsumAngle);
    switch lower(colorList{1}),
        case 'red',
            colorIdx = 1;
        case 'green',
            colorIdx = 2;
        case 'blue',
            colorIdx = 3;
        case 'darkgreen',
            colorIdx = 4;
    end
        
    HSVlimits = zeros(2,6);
    HSVlimits(1,:) = [hueLimits{2}(colorIdx,:), satLimits{2}(1,:), valLimits{2}(1,:)];
    HSVlimits(2,:) = [hueLimits{1}(colorIdx,:), satLimits{1}(1,:), valLimits{1}(1,:)];
    
    hsv{1} = squeeze(masked_hsv_enh{2}(:,:,:,1));
    hsv{2} = squeeze(masked_hsv_enh{dMirrorIdx}(:,:,:,1));

    pdMask = initThresholdDorsum(HSVlimits, ...
                                 hsv, ...
                                 dorsumRegionMask, ...
                                 pdBlob);
    for iView = 1 : 2    % this is confusing. Here, iView = 1 for direct view, 2 for the mirror view with the paw dorsum

        switch iView
            case 1,
                viewIdx = 2;
            case 2,
                viewIdx = dMirrorIdx;
        end
        if ~any(pdMask{iView}(:))
            isDigitVisible(1, viewIdx) = false;
            break;
        end
            
        viewMask{viewIdx}(:,:,1) = pdMask{iView};
        s_dorsum = regionprops(pdMask{iView},'centroid');
        digitMarkers(1,:,2,iView) = s_dorsum.Centroid;
        
    end    % for iView...
    
    if any(~isDigitVisible(:))
        continue;
    end
    % now check that there is overlap between each object and its
    % projection in the other view
    overlapCheckMask = cell(1,2);
    overlapCheckMask{1} = viewMask{dMirrorIdx};
    overlapCheckMask{2} = viewMask{2};
    overlap_bbox = zeros(2, 4);
    overlap_bbox(1,:) = mask_bbox(dMirrorIdx,:);
    overlap_bbox(2,:) = mask_bbox(2,:);

    [validOverlap, overlapFract] = checkDigitOverlap_fromSide(overlapCheckMask, ...
                                                              F_side, ...
                                                              overlap_bbox, ...
                                                              [h,w], ...
                                                              'minoverlap', minSideOverlap);
% CONSIDER ADDING ANOTHER CRITERION THAT THE REPROJECTION ERRORS OF THE
% REGION CENTROIDS HAVE TO BE LESS THAN SOME THRESHOLD. ALSO MAKE SURE THAT
% WE PICK THE MAXIMUM PAW EXTENT IN THE MIRROR VIEW. CAN CONSIDER TAKING A
% PICTURE OF THE PAW IN A CALIBRATED VIEW IN THE FUTURE SO WE HAVE AN
% ESTIMATE OF HOW BIG THE DIGITS AND PAW SHOULD BE.
    if all(validOverlap(2:5))
        digitMissing = false;
    end
        
end    % while digitMissing

% match the paw dorsum blob points
pdMask{1} = viewMask{2}(:,:,1);
pdMask{2} = viewMask{dMirrorIdx}(:,:,1);
bboxes = zeros(2,4);
bboxes(1,:) = mask_bbox(2,:);
bboxes(2,:) = mask_bbox(dMirrorIdx,:);

% find average location of digits in direct and mirror views
dig_edge3D = cell(1,5);
fullPawMasks = false(h,w,2);
fullPawMasks(:,:,1) = centerMask;
digitMasks = cell(1,2);
current_digitMasks = cell(1,2);
possObscuredMatrix = false(5,5,2);
if dMirrorIdx == 1
    fullPawMasks(:,:,2) = leftMirrorPawMask;
else
    fullPawMasks(:,:,2) = rightMirrorPawMask;
end
for iView = 1 : 2
    digitMasks{iView} = false(bboxes(iView,4)+1,bboxes(iView,3)+1,5);
%     current_digitMasks{iView} = false(bboxes(iView,2),bboxes(iView,1),4);   % for all digit masks except the one for which we're currently trying to match silhouettes

    for iDigit = 1 : 5
        if iView == 1
            digitMasks{iView}(:,:,iDigit) = viewMask{2}(:,:,iDigit);
%             tempDigMask = viewMask{2}(:,:,iDigit);
        else
%             tempDigMask = viewMask{dMirrorIdx}(:,:,iDigit);
            digitMasks{iView}(:,:,iDigit) = viewMask{dMirrorIdx}(:,:,iDigit);
        end

%         tempMask(bboxes(iView,2):bboxes(iView,2) + bboxes(iView,4), ...
%                  bboxes(iView,1):bboxes(iView,1) + bboxes(iView,3)) = tempDigMask;
%         fullPawMasks{iView} = fullPawMasks{iView} & ~tempMask;
    end
    if iView == 1
        F = F_side;
    else
        F = F_side';
    end
    possObscuredMatrix(:,:,iView) = findPotentialObscurations(digitMasks{iView}, ...
                                                              F, ...
                                                              bboxes(iView,:), ...
                                                              [h,w], ...
                                                              2-iView);    % true for direct view, false for mirror view
%     current_digitMasks{iView} = digitMasks{iView}(:,:,2:5);
end

% [matchedMasks, tangentPoints] = matchSilhouettes(pdMask, F_side, bboxes, [h,w], fullPawMasks, current_digitMasks);
% pd_edge3D = silhouetteTo3D(matchedMasks, boxCalibration, bboxes, tangentPoints, [h,w], fullPawMasks, digitMasks);

for iDigit = 1 : 5
    digitMask{1} = viewMask{2}(:,:,iDigit);
    digitMask{2} = viewMask{dMirrorIdx}(:,:,iDigit);
    
%     otherDigitIdx = setdiff(1:5, iDigit+1);
%     current_digitMasks{1} = digitMasks{1}(:,:,otherDigitIdx);
%     current_digitMasks{2} = digitMasks{2}(:,:,otherDigitIdx);
    [matchedMasks, tangentPoints] = matchSilhouettes(digitMask, ...
                                                     F_side, ...
                                                     bboxes, ...
                                                     [h,w], ...
                                                     fullPawMasks, ...
                                                     digitMasks, ...
                                                     possObscuredMatrix, ...
                                                     iDigit);
    dig_edge3D{iDigit} = silhouetteTo3D(matchedMasks, boxCalibration, bboxes, tangentPoints, [h,w], fullPawMasks);
    viewMask{dMirrorIdx}(:,:,iDigit) = matchedMasks{2};
    viewMask{2}(:,:,iDigit) = matchedMasks{1};
end
% PROBABLY NEED SOMETHING HERE TO CHECK THAT WE HAVE THE OPTIMUM MATCHES
% BEFORE LEAVING THIS ROUTINE (NOT JUST ALL DIGITS/PAW DORSUM VISIBLE IN
% ALL VIEWS)

% viewMask{dMirrorIdx}(:,:,1) = matchedMasks{2};
% viewMask{2}(:,:,1) = matchedMasks{1};

refImageTime = video.CurrentTime - 1/video.FrameRate;

for iView = 1 : 3
    viewMask{iView}(:,:,6) = BG_mask(mask_bbox(iView,2) : mask_bbox(iView,2) + mask_bbox(iView,4), ...
                                     mask_bbox(iView,1) : mask_bbox(iView,1) + mask_bbox(iView,3));
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%WORKING HERE - NEED TO ADAPT THIS ALGORITHM FOR THE INITIAL DIGIT ID PART
%- GOAL IS TO FIND THE REGION WHERE THE PAW DORSUM CAN BE GIVEN DIGIT
%LOCATIONS, AS WELL AS FIND THE EXTREME POINTS ON THE DIGITS
function [digitMarkers, dorsumRegionMask] = ...
    findInitDorsumRegion(viewMask, pawPref, dorsumAngle)
%
% INPUTS:
%   viewMask - cell array. viewMask{1} for the left mirror, viewMask{2} is
%       the direct view, viewMask{3} is the right mirror. These are binary
%       masks the size of the bounding box around the initial paw masking.
%       Each cell contains an h x w x 6 array, where the last index is the
%       digit (1 = paw dorsum, 2-5 are index through pinky, 6 is the full
%       paw)
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
processingMask = cell(1,2);
switch lower(pawPref)
    case 'right',
        fixed_pts(:,:,1) = [ 2.0   0.0    % most radial digit
                             0.0   0.0    % most ulnar digit
                             1.0  -1.0];  % palm region
        fixed_pts(:,:,2) = [0.0  0.0
                            0.0  2.0
                            1.0  1.0];
        processingMask{2} = viewMask{1};
    case 'left',
        fixed_pts(:,:,1) = [0.0  0.0    % most radial digit
                            2.0  0.0    % most ulnar digit
                            1.0  -1.0];  % palm region
        fixed_pts(:,:,2) = [1.0  0.0
                            1.0  2.0
                            0.0  1.0];
        processingMask{2} = viewMask{3};       % for now, look only at the paw dorsum mirror
end
processingMask{1} = viewMask{2};

numDigits = size(processingMask{1},3) - 1;
digitMarkers = zeros(numDigits, 2, 3, 2);    % number of digits by (x,y) by base/centroid/tip by view number

firstVisibleDigitFound = false(1,2);
digCentroids = zeros(2,2,2);
currentMask = cell(1,2);
digitMasks = cell(1,2);
for iView = 1 : 2
    digitMasks{iView} = false(size(processingMask{iView},1),size(processingMask{iView},2));
end
firstMask = cell(1,2);
lastMask = cell(1,2);
for ii = 2 : numDigits
    for iView = 1 : 2
        currentMask{iView} = processingMask{iView}(:,:,ii);
        digitMasks{iView} = digitMasks{iView} | currentMask{iView};

        if any(currentMask{iView}(:))
            s = regionprops(currentMask{iView},'centroid');
            if ~firstVisibleDigitFound(iView)
                firstVisibleDigitFound(iView) = true;
                digCentroids(1,:,iView) = s.Centroid;
                digitMarkers(ii,:,2,iView) = s.Centroid;
                firstMask{iView} = currentMask{iView};
            else
                digCentroids(2,:,iView) = s.Centroid;
                lastMask{iView} = currentMask{iView};
                digitMarkers(ii,:,2,iView) = s.Centroid;
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
    for ii = 2 : 5
        if ~any(currentMask{iView}(:))
            continue;
        end
        if firstValidIdx == 0; firstValidIdx = ii; end
        lastValidIdx = ii;
        
        currentMask{iView} = processingMask{iView}(:,:,ii);
        
        edge_I = bwmorph(currentMask{iView},'remove');
        [y,x] = find(edge_I);
        [~,nnidx] = findNearestPointToLine(linepts, [x,y]);
%         [~,nnidx] = findNearestNeighbor(pts_transformed(3,:), [x,y]);
        digitMarkers(ii,:,1,iView) = [x(nnidx),y(nnidx)];
        [~,nnidx] = findFarthestPointFromLine(linepts, [x,y]);
%         [~,nnidx] = findFarthestPoint(pts_transformed(3,:), [x,y]);
        digitMarkers(ii,:,3,iView) = [x(nnidx),y(nnidx)];
    end
    validImageBorderPts(1,:) = squeeze(digitMarkers(firstValidIdx,:,1,iView));
    validImageBorderPts(2,:) = squeeze(digitMarkers(lastValidIdx,:,1,iView));
    
    testPt = mean(validImageBorderPts, 1);
    lineCoeff = lineCoeffFromPoints(validImageBorderPts);
    
    if iView == 2
        rotationAngle = -dorsumAngle;
    else
        rotationAngle = dorsumAngle;
    end
    angledLine1 = angledLine(lineCoeff, validImageBorderPts(1,:), rotationAngle);
    angledLine2 = angledLine(lineCoeff, validImageBorderPts(2,:), -rotationAngle);
    
    angledPts1 = lineToBorderPoints(angledLine1, size(currentMask{iView}));
    angledPts2 = lineToBorderPoints(angledLine2, size(currentMask{iView}));
    
    angledPts1 = reshape(angledPts1,[2 2])';
    angledPts2 = reshape(angledPts2,[2 2])';
    
    angledRegion1 = segregateImage(angledPts1, testPt, size(currentMask{iView}));
    angledRegion2 = segregateImage(angledPts2, testPt, size(currentMask{iView}));
    
    angledRegion = angledRegion1 & angledRegion2;
    
    dorsumRegionMask{iView} = segregateImage(validImageBorderPts, ...
                                             pts_transformed(3,:), size(digitMasks{iView}));
                                         
%     [digitsHull,~] = multiRegionConvexHullMask(digitMasks{iView});
    digitsHull = bwconvhull(digitMasks{iView},'union');
    dorsumRegionMask{iView} = dorsumRegionMask{iView} & ~digitsHull & angledRegion;
    
    
%     perpLine1 = perpendicularLine(lineCoeff, validImageBorderPts(1,:));
%     perpLine2 = perpendicularLine(lineCoeff, validImageBorderPts(2,:));
%     
%     perpPts1 = lineToBorderPoints(perpLine1, size(currentMask{iView}));
%     perpPts2 = lineToBorderPoints(perpLine2, size(currentMask{iView}));
%     
%     perpPts1 = reshape(perpPts1,[2 2])';
%     perpPts2 = reshape(perpPts2,[2 2])';
%     
%     perpRegion1 = segregateImage(perpPts1, testPt, size(currentMask{iView}));
%     perpRegion2 = segregateImage(perpPts2, testPt, size(currentMask{iView}));
%     
%     perpRegion = perpRegion1 & perpRegion2;
%     
%     dorsumRegionMask{iView} = segregateImage(validImageBorderPts, ...
%                                              pts_transformed(3,:), size(digitMasks{iView}));
%     
%     [digitsHull,~] = multiRegionConvexHullMask(digitMasks{iView});
%     dorsumRegionMask{iView} = dorsumRegionMask{iView} & ~digitsHull & perpRegion;
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function pdMask = initThresholdDorsum(HSVlimits, ...
                                      hsv, ...
                                      dorsumRegionMask, ...
                                      pdBlob)
%
% INPUTS:
%   HSVlimits - 2 x 6 array containing HSV thresholding limits for the
%       direct (first row) and mirror views (second row)
%   hsv - 2-element cell array containing the enhanced hsv image of the paw
%       within the bounding box for the direct view (index 1) and mirror
%       view (index 2)
%   digitMarkers - 5x2x3x2 array. First dimension is the digit ID, second
%       dimension is (x,y), third dimension is proximal,centroid,tip of
%       each digit, 4th dimension is the view (1 = direct, 2 = mirror)
%   dorsumRegionMask - cell array containing masks for where the paw dorsum
%       can be with respect to the digits (index 1 id direct view, index 2
%       is mirror view)
%   pdBlob - cell array of blob objects containing blob parameters for
%       the direct view (index 1) and mirror view (index 2)
%
% OUTPUTS:
%   pdMask - 1 x 2 cell array containing the mask for the direct
%       (center) and mirror views, respectively


    pdMask = cell(1,2);
    
    currentMask = cell(1,2);

    for iView = 2 : -1 : 1   % easier to start with the mirror view
        currentMask{iView} = false(size(hsv{iView},1),size(hsv{iView},2));
        
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
        
        % use the convex hull of the current mask, but make sure it doesn't
        % overlap with the digits
        
        % CHECK TO SEE THAT THE IDENTIFIED DORSUM REGIONS OVERLAP WELL?
        % CENTROIDS MATCH UP?
        
        if ~any(tempMask(:)); continue; end
        
        tempMask = bwconvhull(tempMask,'union');
%         [tempMask,~] = multiRegionConvexHullMask(tempMask);
        tempMask = tempMask & dorsumRegionMask{iView};
        pdMask{iView} = tempMask;
    end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function areBlobsAligned = checkEpipolarAlignment(viewMask, ...
                                                  F, ...
                                                  trackCheck, ...
                                                  dMirrorIdx, ...
                                                  mask_bbox, ...
                                                  imSize)
%
% INPUTS:
%   viewMask - 1 x numViews cell array containing

areBlobsAligned = true(1,size(viewMask{1},3));

for ii = 2 : 5
    
    s_center = regionprops(viewMask{2}(:,:,ii),'centroid');
    s_mirror = regionprops(viewMask{dMirrorIdx}(:,:,ii),'centroid');
    
    center_xy = [s_center.Centroid];
    center_xy = reshape(center_xy,2,[])';
    center_xy = bsxfun(@plus, center_xy, mask_bbox(2,1:2));
    
    mirror_xy = [s_mirror.Centroid];
    mirror_xy = reshape(mirror_xy,2,[])';
    mirror_xy = bsxfun(@plus, mirror_xy, mask_bbox(dMirrorIdx,1:2));
    
    if length(s_center) ~= length(s_mirror)
        % different numbers of blobs in the two views
        areBlobsAligned(ii) = false;
        return;
    end
    
    dist_to_epi = zeros(1,length(s_mirror));
    epiLine = epipolarLine(F,center_xy);
    epiPts = lineToBorderPoints(epiLine, imSize);

    for iCenterBlob = 1 : length(s_center)
        for iMirrorBlob = 1 : length(s_mirror)
            dist_to_epi(iMirrorBlob) = ...
                distanceToLine(epiPts(iCenterBlob,1:2),...
                               epiPts(iCenterBlob,3:4),...
                               mirror_xy(iMirrorBlob,:));
        end
        if all(dist_to_epi > trackCheck.maxEpiLineDist)
            areBlobsAligned(ii) = false;
            return;
        end
    end

end

end