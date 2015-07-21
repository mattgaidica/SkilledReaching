function maskedPaw = identifyMirrorDigits_dorsum_20150717(video, frameNum, BGimg, rat_metadata, boxMarkers, varargin)
%
% usage
%
% function to find the initial location of the paw and digits in an image
% with a clear view of the paw in the mirrors
%
% INPUTS:
%   image - rgb image
%   pawMask - mask of the paw in the appropriate mirror (logical matrix)
%   rat_metadata - needed to know whether to look to the left or right of
%       the dorsal aspect of the paw to exclude points that can't be digits
%
% VARARGS:
%
% OUTPUTS:
%   maskedPaw - m x n x 5 matrix, where each m x n matrix contains a mask
%       for a part of the paw. 1st row - dorsum of paw, 2nd through 5th
%       rows are each digit from index finger to pinky

% NEED TO ADJUST THE VALUES TO ENHANCE THE DESIRED PAW BITS
% decorrStretchMean  = [100.0 127.5 100.0     % to isolate dorsum of paw
%                       100.0 127.5 100.0     % to isolate blue digits
%                       100.0 127.5 100.0     % to isolate red digits
%                       127.5 100.0 127.5     % to isolate green digits
%                       100.0 127.5 100.0];   % to isolate red digits
% 
% decorrStretchSigma = [050 050 050       % to isolate dorsum of paw
%                       050 050 050       % to isolate blue digits
%                       050 050 050       % to isolate red digits
%                       050 050 050       % to isolate green digits
%                       050 050 050];     % to isolate red digits

decorrStretchMean  = cell(1,3);
decorrStretchSigma = cell(1,3);
decorrStretchMean{1}  = [100.0 150.0 100.0     % to isolate dorsum of paw
                         100.0 150.0 100.0     % to isolate blue digits
                         150.0 100.0 100.0     % to isolate red digits
                         127.5 100.0 127.5     % to isolate green digits
                         150.0 100.0 150.0];   % to isolate red digits

decorrStretchSigma{1} = [050 075 050       % to isolate dorsum of paw
                         050 075 050       % to isolate blue digits
                         050 025 025       % to isolate red digits
                         050 050 050       % to isolate green digits
                         050 025 025];     % to isolate red digits
                  
decorrStretchMean{2}  = [100.0 150.0 100.0     % to isolate dorsum of paw
                         100.0 150.0 100.0     % to isolate blue digits
                         150.0 100.0 100.0     % to isolate red digits
                         127.5 100.0 127.5     % to isolate green digits
                         150.0 100.0 150.0];   % to isolate red digits

decorrStretchSigma{2} = [050 075 050       % to isolate dorsum of paw
                         050 075 050       % to isolate blue digits
                         050 025 025       % to isolate red digits
                         050 050 050       % to isolate green digits
                         050 025 025];     % to isolate red digits
                     
decorrStretchMean{3}  = [100.0 150.0 100.0     % to isolate dorsum of paw
                         100.0 150.0 100.0     % to isolate blue digits
                         150.0 100.0 100.0     % to isolate red digits
                         127.5 100.0 127.5     % to isolate green digits
                         150.0 100.0 150.0];   % to isolate red digits

decorrStretchSigma{3} = [050 075 050       % to isolate dorsum of paw
                         050 075 050       % to isolate blue digits
                         050 025 025       % to isolate red digits
                         050 050 050       % to isolate green digits
                         050 025 025];     % to isolate red digits
                     
for ii = 1 : 3
    decorrStretchMean{ii} = decorrStretchMean{ii} / 255;
    decorrStretchSigma{ii} = decorrStretchSigma{ii} / 255;
end

diff_threshold = 45 / 255;
% hsv_digitBounds = [0.33 0.33 0.00 0.90 0.00 0.90
%                    0.67 0.16 0.90 1.00 0.80 1.00
%                    0.00 0.16 0.90 1.00 0.80 1.00
%                    0.33 0.16 0.90 1.00 0.90 1.00
%                    0.00 0.16 0.90 1.00 0.80 1.00];
% rgb_digitBounds = [0.00 0.50 0.50 1.00 0.00 0.80
%                    0.00 0.10 0.00 0.60 0.80 1.00
%                    0.90 1.00 0.00 0.40 0.00 0.40
%                    0.00 0.70 0.90 1.00 0.00 0.50
%                    0.00 0.16 0.90 1.00 0.80 1.00];

% rgb_digitBounds = [0.00 0.50 0.00 0.10 0.00 0.10
%                    0.00 0.10 0.00 0.60 0.80 1.00
%                    0.90 1.00 0.00 0.40 0.00 0.40
%                    0.00 0.70 0.90 1.00 0.00 0.50
%                    0.00 0.16 0.90 1.00 0.80 1.00];

mirrorPawBlob = vision.BlobAnalysis;
mirrorPawBlob.AreaOutputPort = true;
mirrorPawBlob.CentroidOutputPort = true;
mirrorPawBlob.BoundingBoxOutputPort = true;
mirrorPawBlob.ExtentOutputPort = true;
mirrorPawBlob.LabelMatrixOutputPort = true;
mirrorPawBlob.MinimumBlobArea = 3000;
mirrorPawBlob.MaximumBlobArea = 30000;

mirrorPawBlob = vision.BlobAnalysis;
mirrorPawBlob.AreaOutputPort = true;
mirrorPawBlob.CentroidOutputPort = true;
mirrorPawBlob.BoundingBoxOutputPort = true;
mirrorPawBlob.ExtentOutputPort = true;
mirrorPawBlob.LabelMatrixOutputPort = true;
mirrorPawBlob.MinimumBlobArea = 3000;
mirrorPawBlob.MaximumBlobArea = 30000;

digitBlob = vision.BlobAnalysis;
digitBlob.AreaOutputPort = true;
digitBlob.CentroidOutputPort = true;
digitBlob.BoundingBoxOutputPort = true;
digitBlob.ExtentOutputPort = true;
digitBlob.LabelMatrixOutputPort = true;
digitBlob.MinimumBlobArea = 50;
digitBlob.MaximumBlobArea = 30000;

colorList = {'darkgreen','blue','red','green','red'};
satLimits = [0.50000    1.00
             0.60000    1.00
             0.60000    1.00
             0.80000    1.00
             0.80000    1.00];
max_Value = 0.15;
hueLimits = [0.00, 0.16;
             0.33, 0.16;
             0.66, 0.16
             0.33  0.16];
h = video.Height;
w = video.Width;

F = boxMarkers.F;
register_ROI = boxMarkers.register_ROI;

pawPref = lower(rat_metadata.pawPref);
if iscell(pawPref)
    pawPref = pawPref{1};
end

for iarg = 1 : 2 : nargin - 5
    switch lower(varargin{iarg})
        case 'diffthreshold',
            diff_threshold = varargin{iarg + 1};
        case 'digitbounds',
            rgb_digitBounds = varargin{iarg + 1};
        case 'decorrstretchmean',
            decorrStretchMean = varargin{iarg + 1};
        case 'decorrstretchsigma',
            decorrStretchSigma = varargin{iarg + 1};
    end
end

% create a mask for the box front in the left and right mirrors
boxFrontMask = poly2mask(boxMarkers.frontPanel_x(1,:), ...
                         boxMarkers.frontPanel_y(1,:), ...
                         h, w);
boxFrontMask = boxFrontMask | poly2mask(boxMarkers.frontPanel_x(2,:), ...
                                        boxMarkers.frontPanel_y(2,:), ...
                                        h, w);
                                        
vidName = fullfile(video.Path, video.Name);
video = VideoReader(vidName);
frameTime = ((frameNum-1) / video.FrameRate);    % need to subtract one because readFrame reads the NEXT frame, not the current frame
video.CurrentTime = frameTime;

switch pawPref
    case 'left',
        dMirrorIdx = 3;   % index of mirror with dorsal view of paw
        pMirrorIdx = 1;   % index of mirror with palmar view of paw
    case 'right',
        dMirrorIdx = 1;   % index of mirror with dorsal view of paw
        pMirrorIdx = 3;   % index of mirror with palmar view of paw
end
    
digitMissing = true;

[mirror_shelf_mask, center_region_mask] = reach_region_mask(boxMarkers, [h,w]);

numObjects = size(decorrStretchMean, 1);
while digitMissing
    image = readFrame(video);
    image = double(image) / 255;
    BG_diff = imabsdiff(BGimg,image);

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

    % keep only the largest mirror mask blobs
    leftMask = false(h,w);
    leftMask(:,1:round(w/2)) = true;
    leftMirrorMask = mirrorMask & leftMask;
    rightMirrorMask = mirrorMask & ~leftMask;
    [left_A,~,~,~,leftLabMat] = step(mirrorPawBlob, leftMirrorMask);
    idx = find(left_A == max(left_A));
    leftMirrorPawMask = (leftLabMat == idx);

    [right_A,~,~,~,rightLabMat] = step(mirrorPawBlob, rightMirrorMask);
    idx = find(right_A == max(right_A));
    rightMirrorPawMask = (rightLabMat == idx);

    mirrorMask = leftMirrorPawMask | rightMirrorPawMask;
    
    leftMask_ROI = leftMirrorPawMask(register_ROI(1,2):register_ROI(1,2) + register_ROI(1,4),...
                                     register_ROI(1,1):register_ROI(1,1) + register_ROI(1,3));
    leftMask_ROI = fliplr(leftMask_ROI);   % flip because mirror inverts the image

    rightMask_ROI = rightMirrorPawMask(register_ROI(3,2):register_ROI(3,2) + register_ROI(3,4),...
                                       register_ROI(3,1):register_ROI(3,1) + register_ROI(3,3));
    leftProjMask  = pawProjectionMask(leftMask_ROI, F.left, [register_ROI(2,4),register_ROI(2,3)]+1);
    rightProjMask = pawProjectionMask(rightMask_ROI, F.right, [register_ROI(2,4),register_ROI(2,3)]+1);

    projMask = false(h,w);
    projMask(register_ROI(2,2):register_ROI(2,2) + register_ROI(2,4),...
             register_ROI(2,1):register_ROI(2,1) + register_ROI(2,3)) = (leftProjMask & rightProjMask);
    projMask = imdilate(projMask,strel('disk',10));
    
    centerMask = projMask & BG_mask & center_region_mask;
    centerMask = bwdist(centerMask) < 2;
    centerMask = imopen(centerMask, SE);
    centerMask = imclose(centerMask,SE);
    centerMask = imfill(centerMask,'holes');
    
    % find a region that includes bright green
    rgb_enh = enhanceColorImage(image, ...
                                decorrStretchMean{2}(4,:), ...
                                decorrStretchSigma{2}(4,:), ...
                                'mask',centerMask);
	tempMask = HSVthreshold(rgb2hsv(rgb_enh), ...
                            [hueLimits(4,:), satLimits(4,:), 0.000001, 1.0]);                    
	tempMask = tempMask & centerMask;
    s = regionprops(tempMask,'area');
    labMat = bwlabel(tempMask);
    A = [s.Area];
    idx = find(A == max(A));
    tempMask = (labMat == idx);   % make sure there's only one green blob so imreconstruct doesn't get confused
    
    centerMask = imreconstruct(tempMask, centerMask);
    
    BG_mask = mirrorMask | centerMask;
    
%     pawDorsumBlob = vision.BlobAnalysis;
%     pawDorsumBlob.AreaOutputPort = true;
%     pawDorsumBlob.CentroidOutputPort = true;
%     pawDorsumBlob.BoundingBoxOutputPort = true;
%     pawDorsumBlob.ExtentOutputPort = true;
%     pawDorsumBlob.LabelMatrixOutputPort = true;
%     pawDorsumBlob.MinimumBlobArea = 100;

    masked_hsv_enh = cell(1,3);
    region_img = cell(1,3);
    for iView = 1 : 3
        masked_hsv_enh{iView} = zeros(numObjects,...
                                      register_ROI(iView,4) + 1, ...
                                      register_ROI(iView,3) + 1,3);
        region_img = image(register_ROI(iView,2):register_ROI(iView,2) + register_ROI(iView,4), ...
                           register_ROI(iView,1):register_ROI(iView,1) + register_ROI(iView,3), :);
                                  
        mask = BG_mask(register_ROI(iView,2):register_ROI(iView,2) + register_ROI(iView,4), ...
                       register_ROI(iView,1):register_ROI(iView,1) + register_ROI(iView,3));
        rgbMask = double(repmat(mask,1,1,3));
        for ii = 1 : numObjects
            % CREATE THE ENHANCED IMAGE DEPENDING ON ii BEFORE DOING ANYTHING ELSE
            
            
            
            % WORKING HERE - FIGURE OUT WHAT THE OPTIMUM DECORRSTRETCH
            % PARAMETERS ARE IN EACH VIEW
            rgb_enh = enhanceColorImage(region_img, ...
                                        decorrStretchMean{iView}(ii,:), ...
                                        decorrStretchSigma{iView}(ii,:), ...
                                        'mask',mask);
                                    figure(1);imshow(rgb_enh);figure(2);imshow(rgb2hsv(rgb_enh));
            masked_hsv_enh{iView}(ii,:,:,:) = rgb2hsv(rgbMask .* rgb_enh);
        end
    end

    dMask = false(h,w,numObjects);
    SE = strel('disk',2);

    numSameColorObjects = zeros(numObjects, 1);
    isDigitVisible = true(numObjects,3);
    for ii = 2 : numObjects    % CONSIDER PUTTING A CHECK HERE THAT IF ALL DIGITS AREN'T FOUND, TRY ANOTHER IMAGE
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

        if any(sameColIdx < ii)   % if mask already computed for a color, use the previous mask
            lastColIdx = max(sameColIdx(sameColIdx < ii));
            tempMask = dMask(:,:,lastColIdx);
        else
            tempMask = HSVthreshold(squeeze(masked_hsv_enh(ii,:,:,:)), ...
                                    [hueLimits(colorIdx,:), satLimits(ii,:), 0.000001, 1.0]);
            tempMask = tempMask & (projMask | mirrorMask);

            if ii == 2
                % eliminate any identified blue regions that overlap with blue
                % beads
                tempMask = tempMask & ~squeeze(boxMarkers.beadMasks(:,:,3));
            end

            tempMask = imopen(tempMask, SE);
            tempMask = imclose(tempMask, SE);
            tempMask = imfill(tempMask, 'holes');

            for jj = 1 : 3    % take only the largest n blobs from each region, where n is the number of blobs that should have the same color
                regionMask = tempMask(register_ROI(jj,2):register_ROI(jj,2) + register_ROI(jj,4),...
                                      register_ROI(jj,1):register_ROI(jj,1) + register_ROI(jj,3));

                [A,~,~,~,labMat] = step(digitBlob, regionMask);
                if ~isempty(A)
                    [~,idx] = sort(A, 'descend');
                    regionMask = false(size(regionMask));
                    if (length(idx) < numSameColorObjects(ii)) && (jj ~= pMirrorIdx)
                        % all the digits weren't identified
                        isDigitVisible(ii,jj) = false;  % didn't find the ii'th digit in the jj'th view
                        break;
                    end
                    for kk = 1 : min(numSameColorObjects(ii), length(idx))
                        regionMask = regionMask | (labMat == idx(kk));
                    end
                    tempMask(register_ROI(jj,2):register_ROI(jj,2) + register_ROI(jj,4),...
                             register_ROI(jj,1):register_ROI(jj,1) + register_ROI(jj,3)) = regionMask;
                end
            end

        end

        if any(~isDigitVisible(:))   % one of the digits isn't visible in one of the views
            break
        end

        overlapMask = dMask(:,:,ii-1) & tempMask;
        dMask(:,:,ii-1) = dMask(:,:,ii-1) & ~overlapMask;
        tempMask = tempMask & ~overlapMask;

        dMask(:,:,ii) = tempMask;

    end
    % WORKING HERE - LOOP THROUGH EACH VIEW AND IDENTIFY WHICH DIGIT
    % CORRESPONDS TO WHICH BLOB
    if any(~isDigitVisible(:))   % one of the digits isn't visible in one of the views
        break   % go back and try the next video frame
    end

    fullDigitMask = cell(1,3);   % mask for all objects (digits) found in each view
    viewMask = cell(1,3);        % mask for each individual object (digit) found in each view

    for iView = 1 : 3
        fullDigitMask{iView} = false(register_ROI(iView,4)+1, ...
                                     register_ROI(iView,3)+1);
        viewMask{iView} = false(register_ROI(iView,4)+1, ...
                                register_ROI(iView,3)+1, numObjects);
        
        for ii = 2 : numObjects
            tempMask = imerode(dMask(:,:,ii),strel('disk',1));
            tempMask = tempMask(register_ROI(iView,2) : register_ROI(iView,2) + register_ROI(iView,4), ...
                                register_ROI(iView,1) : register_ROI(iView,1) + register_ROI(iView,3));

            if iView ~= 2
                tempMask = fliplr(tempMask);
            end
            fullDigitMask{iView} = fullDigitMask{iView} | tempMask;
            viewMask{iView}(:,:,ii) = tempMask;
        end

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
                s = regionprops(viewMask{iView}(:,:,jj));
                cd_centroids = [s.Centroid];    % current digit centroids
                cd_centroids = reshape(sd_centroids,2,[])';   % now an m x 2 array where each row is another centroid
                
                s = regionprops(viewMask{iView}(:,:,jj-1));
                pd_centroid = [s.Centroid];    % previous digit centroids

                centroids = [pd_centroid; cd_centroids];
                [~,~,nnidx] = nearestNeighbor(centroids);
                
                regionMarker = false(size(fullDigitMask{iView}));
                regionMarker(centroids(nnidx(1),2), centroids(nnidx(1),1)) = true;
                
                viewMask{iView}(:,:,jj) = imreconstruct(regionMarker, viewMask{iView}(:,:,jj));
            end
        end    % for jj = 3 : numObjects

    end    % for iView...
    
    
end    % while digitMissing
            


%         for ii = 2 : numObjects
%             s = regionprops(squeeze(viewMask{iView}(:,:,ii)),'centroid');
%             sd_centroids = [s.Centroid];
%             sd_centroids = reshape(sd_centroids,2,[])';   % now an m x 2 array where each row is another centroid
% 
%             
% 
%         end
%     
%     end
    % % sort centroids from top to bottom
    % [~, idx] = sort(centroids(:,2));
    % centroids = round(centroids(idx,:));
    % 
    % for ii = 1 : numObjects - 1
    %     regionMarker = false(h,w);
    %     regionMarker(centroids(ii,2),centroids(ii,1)) = true;
    %     dMask(:,:,ii+1) = imreconstruct(regionMarker, fullDigitMask);
    % end

    % now identify the dorsum of the paw as everything on the opposite side of
    % a line connecting the base of the index finger and pinky compared to the
    % digit centroids
    % start by creating the convex hull mask for all the digits together

    % [digitHullMask,digitHullPoints] = multiRegionConvexHullMask(fullDigitMask);
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
    pdMask = HSVthreshold(squeeze(masked_hsv_enh(1,:,:,:)), ...
                          [hueLimits(colorIdx,:), satLimits(1,:), 0.000001, 1.0]);   % with the current (201507) tattoo regimen, best mask for paw dorsum is the grayscale

    pdMask = pdMask & (projMask | mirrorMask);
    SE = strel('disk',2);

    pdMask = pdMask & ~digitHullMask;    % make 
    pdMask = bwdist(pdMask) < 2;
    pdMask = imopen(pdMask, SE);
    pdMask = imclose(pdMask, SE);
    pdMask = imfill(pdMask, 'holes');

    s = regionprops(pdMask, 'area');
    pdLabel = bwlabel(pdMask);
    A = [s.Area];
    maxAreaIdx = find(A == max(A));
    pdMask = (pdLabel == maxAreaIdx);
    s = regionprops(pdMask,'Centroid');
    pdCentroid = s(1).Centroid;
    % find the two closest points in the digit region hull to the paw dorsum
    % centroid as currently calculated. We are trying to get rid of any parts
    % of the paw dorsum mask that really are part of the digit region; at this
    % point, there may still be digit points around the edges included in the
    % dorsum of the paw.

    % find the hull point for the index finger closest to the paw dorsum
    % centroid
    s_idx = regionprops(squeeze(dMask(:,:,2)), 'ConvexHull');
    [~,idx_nnidx] = findNearestNeighbor(pdCentroid, s_idx(1).ConvexHull, 1);
    idx_base = s_idx(1).ConvexHull(idx_nnidx,:);
    % find the hull point for the pinky closest to the paw dorsum centroid
    [~,pinkyHullPoints] = multiRegionConvexHullMask(squeeze(dMask(:,:,5)));
    [~,pinky_nnidx] = findNearestNeighbor(pdCentroid, pinkyHullPoints, 1);
    pinky_base = pinkyHullPoints(pinky_nnidx,:);
    % now find the hull points for the entire "digits" region closest to the
    % hull points for the individual digits that are closest to the paw dorsum
    % centroid. This ensures that when we draw a line separating the "digits"
    % and "paw dorsum" regions, we take one point from the index finger and one
    % point from the pinky finger.
    nnHull = zeros(2,2);
    [~,nnidx] = findNearestNeighbor(idx_base, digitHullPoints);
    nnHull(1,:) = digitHullPoints(nnidx,:);
    [~,nnidx] = findNearestNeighbor(pinky_base, digitHullPoints);
    nnHull(2,:) = digitHullPoints(nnidx,:);

    % now draw a line between the base of the pinky and index finger;
    % everything on the same side of that line as the paw dorsum centroid is
    % part of the paw dorsum; everything on the same side as the digit
    % centroids is part of the digit region
    % to separate these regions, create a mask that separates the image into
    % two regions, and has true values on the same side as the index finger
    % centroid
    s = regionprops(dMask(:,:,2),'centroid');
    digitRegionMask = segregateImage(nnHull, s.Centroid, [h, w]);
    digitRegionMask = digitRegionMask | ...
                      dMask(:,:,2) | ...
                      dMask(:,:,3) | ...
                      dMask(:,:,4) | ...
                      dMask(:,:,5);
    pdMask = pdMask & ~digitRegionMask;

    dMask(:,:,1) = pdMask;

    % now have all the fingers and the dorsum of the paw
    % make sure none of the blobs overlap; the digit blobs already have been
    % separated from each other
    for ii = 2 : numObjects
        overlapMask = dMask(:,:,ii) & pdMask;
        dMask(:,:,ii) = dMask(:,:,ii) & ~overlapMask;
        pdMask = pdMask & ~overlapMask;
    end
    pdMask = imerode(pdMask, strel('disk',1));
    dMask(:,:,1) = pdMask;

    [~,P] = imseggeodesic(image, dMask(:,:,2), dMask(:,:,3), dMask(:,:,4));
    [~, P2] = imseggeodesic(image, dMask(:,:,1), dMask(:,:,5), dMask(:,:,4));

    maskedPaw = false(h, w, numObjects);
    maskedPaw(:,:,1) = (P2(:,:,1) > 0.9) & pawMask & ~digitRegionMask;
    maskedPaw(:,:,2) = (P(:,:,1) > 0.9) & pawMask;
    maskedPaw(:,:,3) = (P(:,:,2) > 0.9) & pawMask;
    maskedPaw(:,:,4) = (P(:,:,3) > 0.9) & pawMask;
    maskedPaw(:,:,5) = (P2(:,:,2) > 0.9) & pawMask;

    [pd_a,~,~,~,pdLabMask] = step(pawDorsumBlob, squeeze(maskedPaw(:,:,1)));
    maxAreaIdx = find(pd_a == max(pd_a));
    maskedPaw(:,:,1) = (pdLabMask == maxAreaIdx);

    for ii = 1 : size(maskedPaw,3)
        if ii > 1
            [A,~,~,~,labMask] = step(digitBlob, squeeze(maskedPaw(:,:,ii)));
            maxAreaIdx = find(A == max(A));
            maskedPaw(:,:,ii) = (labMask == maxAreaIdx);    % WORKING HERE...
        end
        maskedPaw(:,:,ii) = imfill(squeeze(maskedPaw(:,:,ii)),'holes');
        maskedPaw(:,:,ii) = maskedPaw(:,:,ii) & ~boxFrontMask;
    end


    end