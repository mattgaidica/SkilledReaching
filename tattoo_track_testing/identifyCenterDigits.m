function maskedPaw = identifyCenterDigits(centerImg, digitMirrorMask, fundmat, rat_metadata, varargin)
%
% usage
%
% INPUTS:
%   centerImg - rgb masked image of paw in the direct camera view. Seems to
%       work better if decorrstretched first to enhance color contrast
%   digitMirrorMask - 
%   fundmat - 
%   rat_metadata - needed to know whether to look to the left or right of
%       the dorsal aspect of the paw to exclude points that can't be digits
%
% VARARGS:
%
% OUTPUTS:
%   centerMask - m x n x 5 matrix, where each m x n matrix contains a mask
%       for a part of the paw. 1st row - dorsum of paw, 2nd through 5th
%       rows are each digit from index finger to pinky

decorrStretchMean  = [127.5 100.0 100.0     % to isolate dorsum of paw
                      127.5 100.0 127.5     % to isolate blue digits
                      127.5 100.0 127.5     % to isolate red digits
                      127.5 100.0 127.5     % to isolate green digits
                      127.5 100.0 127.5];   % to isolate red digits
decorrStretchSigma = [075 075 075       % to isolate dorsum of paw
                      075 075 075       % to isolate blue digits
                      075 075 075       % to isolate red digits
                      075 075 075       % to isolate green digits
                      075 075 075];     % to isolate red digits

% hsv_digitBounds = [0.25 0.20 0.00 0.30 0.20 0.50
%                    0.70 0.10 0.40 1.00 0.40 1.00
%                    0.00 0.10 0.35 0.70 0.40 1.00
%                    0.25 0.10 0.40 1.00 0.40 1.00
%                    0.00 0.10 0.60 1.00 0.40 1.00];
rgb_digitBounds = [0.01 0.50 0.01 0.80 0.01 0.50
                   0.00 0.20 0.00 0.20 0.80 1.00
                   0.80 1.00 0.00 0.50 0.00 0.50
                   0.00 0.50 0.80 1.00 0.00 0.50
                   0.80 1.00 0.00 0.50 0.00 0.50];
               
               
for iarg = 1 : 2 : nargin - 4
    switch lower(varargin{iarg})
        case 'digitbounds',
            rgb_digitBounds = varargin{iarg + 1};
        case 'decorrstretchmean',
            decorrStretchMean = varargin{iarg + 1};
        case 'decorrstretchsigma',
            decorrStretchSigma = varargin{iarg + 1};
    end
end

pawDorsumBlob = vision.BlobAnalysis;
pawDorsumBlob.AreaOutputPort = true;
pawDorsumBlob.CentroidOutputPort = true;
pawDorsumBlob.BoundingBoxOutputPort = true;
pawDorsumBlob.LabelMatrixOutputPort = true;
pawDorsumBlob.MinimumBlobArea = 0000;

digitBlob = vision.BlobAnalysis;
digitBlob.AreaOutputPort = true;
digitBlob.CentroidOutputPort = true;
digitBlob.BoundingBoxOutputPort = true;
digitBlob.ExtentOutputPort = true;
digitBlob.LabelMatrixOutputPort = true;
digitBlob.MinimumBlobArea = 50;
digitBlob.MaximumBlobArea = 1500;

pawMask = (rgb2gray(centerImg) > 0);
s = regionprops(pawMask,'area','centroid');
wholePawCentroid = s.Centroid;

% 1st row masks the dorsum of the paw
% next 4 rows mask the digits
maskedPaw = false(size(centerImg,1), size(centerImg,2), size(rgb_digitBounds,1));
SE = strel('disk',2);
rgb_enh = zeros(size(rgb_digitBounds,1), size(centerImg,1),size(centerImg,2),size(centerImg,3));
for ii = 1 : size(rgb_digitBounds, 1)
    
    % CREATE THE ENHANCED IMAGE DEPENDING ON ii BEFORE DOING ANYTHING ELSE
    rgb_enh(ii,:,:,:)  = enhanceColorImage(centerImg, ...
                                           decorrStretchMean(ii,:), ...
                                           decorrStretchSigma(ii,:), ...
                                           'mask',pawMask);
end

% digitCtr = zeros(size(rgb_digitBounds,1), 2);
% first mask out the index finger
idxMask = squeeze(rgb_enh(2,:,:,1)) >= rgb_digitBounds(2,1) & ...
          squeeze(rgb_enh(2,:,:,1)) <= rgb_digitBounds(2,2) & ...
          squeeze(rgb_enh(2,:,:,2)) >= rgb_digitBounds(2,3) & ...
          squeeze(rgb_enh(2,:,:,2)) <= rgb_digitBounds(2,4) & ...
          squeeze(rgb_enh(2,:,:,3)) >= rgb_digitBounds(2,5) & ...
          squeeze(rgb_enh(2,:,:,3)) <= rgb_digitBounds(2,6);
% reject points that aren't within the projection of the index finger from
% the mirror
idxProjectionMask = pawProjectionMask(squeeze(digitMirrorMask(:,:,2)), fundmat, size(pawMask));
idxMask = idxMask & idxProjectionMask;

idxMask = bwdist(idxMask) < 2;
idxMask = imopen(idxMask, SE);
idxMask = imclose(idxMask, SE);
idxMask = imfill(idxMask, 'holes');
[idx_a,~,~,~,idxLabMask] = step(digitBlob, idxMask);
% take the largest blob
validIdx = find(idx_a == max(idx_a));
idxMask = (idxLabMask == validIdx);
[~,idx_c,~,~,~] = step(digitBlob, idxMask);
% digitCtr = zeros(size(rgb_digitBounds,1), 2);
% first mask out the index finger
middleMask = squeeze(rgb_enh(3,:,:,1)) >= rgb_digitBounds(3,1) & ...
             squeeze(rgb_enh(3,:,:,1)) <= rgb_digitBounds(3,2) & ...
             squeeze(rgb_enh(3,:,:,2)) >= rgb_digitBounds(3,3) & ...
             squeeze(rgb_enh(3,:,:,2)) <= rgb_digitBounds(3,4) & ...
             squeeze(rgb_enh(3,:,:,3)) >= rgb_digitBounds(3,5) & ...
             squeeze(rgb_enh(3,:,:,3)) <= rgb_digitBounds(3,6);
% reject points that aren't within the projection of the middle finger from
% the mirror
middleProjectionMask = pawProjectionMask(squeeze(digitMirrorMask(:,:,3)), fundmat, size(pawMask));
middleMask = middleMask & middleProjectionMask;

middleMask = bwdist(middleMask) < 2;
middleMask = imopen(middleMask, SE);
middleMask = imclose(middleMask, SE);
middleMask = imfill(middleMask, 'holes');
[mid_a,~,~,~,middleLabMask] = step(digitBlob, middleMask);
% take the largest blob
validIdx = find(mid_a == max(mid_a));
middleMask = (middleLabMask == validIdx);

pinkyMask = squeeze(rgb_enh(5,:,:,1)) >= rgb_digitBounds(5,1) & ...
            squeeze(rgb_enh(5,:,:,1)) <= rgb_digitBounds(5,2) & ...
            squeeze(rgb_enh(5,:,:,2)) >= rgb_digitBounds(5,3) & ...
            squeeze(rgb_enh(5,:,:,2)) <= rgb_digitBounds(5,4) & ...
            squeeze(rgb_enh(5,:,:,3)) >= rgb_digitBounds(5,5) & ...
            squeeze(rgb_enh(5,:,:,3)) <= rgb_digitBounds(5,6);
% reject points that aren't within the projection of the pinky finger from
% the mirror
pinkyProjectionMask = pawProjectionMask(squeeze(digitMirrorMask(:,:,5)), fundmat, size(pawMask));
pinkyMask = pinkyMask & pinkyProjectionMask;

pinkyMask = bwdist(pinkyMask) < 2;
pinkyMask = imopen(pinkyMask, SE);
pinkyMask = imclose(pinkyMask, SE);
pinkyMask = imfill(pinkyMask, 'holes');
[mid_a,~,~,~,pinkyLabMask] = step(digitBlob, pinkyMask);
% take the largest blob
validIdx = find(mid_a == max(mid_a));
pinkyMask = (pinkyLabMask == validIdx);  
       
ringMask = squeeze(rgb_enh(4,:,:,1)) >= rgb_digitBounds(4,1) & ...
           squeeze(rgb_enh(4,:,:,1)) <= rgb_digitBounds(4,2) & ...
           squeeze(rgb_enh(4,:,:,2)) >= rgb_digitBounds(4,3) & ...
           squeeze(rgb_enh(4,:,:,2)) <= rgb_digitBounds(4,4) & ...
           squeeze(rgb_enh(4,:,:,3)) >= rgb_digitBounds(4,5) & ...
           squeeze(rgb_enh(4,:,:,3)) <= rgb_digitBounds(4,6);
% reject points that aren't within the projection of the ring finger from
% the mirror
ringProjectionMask = pawProjectionMask(squeeze(digitMirrorMask(:,:,4)), fundmat, size(pawMask));
ringMask = ringMask & ringProjectionMask;

ringMask = bwdist(ringMask) < 2;
ringMask = imopen(ringMask, SE);
ringMask = imclose(ringMask, SE);
ringMask = imfill(ringMask, 'holes');
[mid_a,~,~,~,ringLabMask] = step(digitBlob, ringMask);
% take the largest blob
validIdx = find(mid_a == max(mid_a));
ringMask = (ringLabMask == validIdx);  

% now have all the fingers
SE = strel('disk',3);
[idx_A,~,~,~,idxLabMask] = step(digitBlob, imerode(idxMask, SE));
if isempty(idx_A)    % in case we destroy the blob by eroding it
    idx_erode = idxMask;
else
    validIdx = find(idx_A == max(idx_A));
    idx_erode = (idxLabMask == validIdx);
end

[middle_A,~,~,~,middleLabMask] = step(digitBlob, imerode(middleMask, SE));
if isempty(middle_A)    % in case we destroy the blob by eroding it
    middle_erode = middleMask;
else
    validIdx = find(middle_A == max(middle_A));
    middle_erode = (middleLabMask == validIdx);
end

[ring_A,~,~,~,ringLabMask] = step(digitBlob, imerode(ringMask, SE));
if isempty(ring_A)    % in case we destroy the blob by eroding it
    ring_erode = ringMask;
else
    validIdx = find(ring_A == max(ring_A));
    ring_erode = (ringLabMask == validIdx);
end

[pinky_A,~,~,~,pinkyLabMask] = step(digitBlob, imerode(pinkyMask, SE));
pinky_erode = (pinkyLabMask == validIdx);
if isempty(pinky_A)    % in case we destroy the blob by eroding it
    pinky_erode = pinkyMask;
else
    validIdx = find(pinky_A == max(pinky_A));
    pinky_erode = (pinkyLabMask == validIdx);
end

[L,P] = imseggeodesic(squeeze(rgb_enh(2,:,:,:)), idx_erode, middle_erode,ring_erode);
[L2, P2] = imseggeodesic(squeeze(rgb_enh(2,:,:,:)), middle_erode,ring_erode, pinky_erode);
maskedPaw = false(size(centerImg,1), size(centerImg,2), size(rgb_digitBounds,1));
maskedPaw(:,:,2) = (P(:,:,1) > 0.9) & pawMask;
maskedPaw(:,:,3) = (P(:,:,2) > 0.9) & pawMask;
maskedPaw(:,:,4) = (P2(:,:,2) > 0.9) & pawMask;
maskedPaw(:,:,5) = (P2(:,:,3) > 0.9) & pawMask;
for ii = 2 : size(maskedPaw,3)

    [A,~,~,~,labMask] = step(digitBlob, squeeze(maskedPaw(:,:,ii)));
    maxAreaIdx = find(A == max(A));
    maskedPaw(:,:,ii) = (labMask == maxAreaIdx);

    maskedPaw(:,:,ii) = imfill(squeeze(maskedPaw(:,:,ii)),'holes');
end

centerDigitMask = maskedPaw(:,:,2) | maskedPaw(:,:,3) | maskedPaw(:,:,4) | maskedPaw(:,:,5);
[centerDigitHullMask, centerDigitHullPoints] = multiRegionConvexHullMask(centerDigitMask);
% mask out the digits and repeat the decorrelation stretch
% pd_enh  = enhanceColorImage(centerImg, ...
%                             decorrStretchMean(1,:), ...
%                             decorrStretchSigma(1,:), ...
%                             'mask',pawMask&~centerDigitHullMask);
pdMask = squeeze(rgb_enh(1,:,:,1)) >= rgb_digitBounds(1,1) & ...
         squeeze(rgb_enh(1,:,:,1)) <= rgb_digitBounds(1,2) & ...
         squeeze(rgb_enh(1,:,:,2)) >= rgb_digitBounds(1,3) & ...
         squeeze(rgb_enh(1,:,:,2)) <= rgb_digitBounds(1,4) & ...
         squeeze(rgb_enh(1,:,:,3)) >= rgb_digitBounds(1,5) & ...
         squeeze(rgb_enh(1,:,:,3)) <= rgb_digitBounds(1,6);
% reject points that aren't within the projection of the paw dorsum from
% the mirror
pdProjectionMask = pawProjectionMask(squeeze(digitMirrorMask(:,:,1)), fundmat, size(pawMask));
pdMask = pdMask & pdProjectionMask;
pdMask = pdMask & ~centerDigitHullMask;
pdMask = bwdist(pdMask) < 2;
pdMask = imopen(pdMask, SE);
pdMask = imclose(pdMask, SE);
pdMask = imfill(pdMask, 'holes');
[pd_a,~,~,pdLabMask] = step(pawDorsumBlob, pdMask);
maxAreaIdx = find(pd_a == max(pd_a));
pdMask = (pdLabMask == maxAreaIdx);
s = regionprops(pdMask,'Centroid');
pdCentroid = s(1).Centroid;

% find the two closest points in the digit region hull to the paw dorsum
% centroid as currently calculated. We are trying to get rid of any parts
% of the paw dorsum mask that really are part of the digit region; at this
% point, there may still be digit points around the edges included in the
% dorsum of the paw.

% find the hull point for the index finger closest to the paw dorsum
% centroid
s_idx = regionprops(squeeze(maskedPaw(:,:,2)), 'ConvexHull');
[~,idx_nnidx] = findNearestNeighbor(pdCentroid, s_idx(1).ConvexHull, 1);
idx_base = s_idx(1).ConvexHull(idx_nnidx,:);
% find the hull point for the pinky closest to the paw dorsum centroid
s_pinky = regionprops(squeeze(maskedPaw(:,:,5)), 'ConvexHull');
[~,pinky_nnidx] = findNearestNeighbor(pdCentroid, s_pinky(1).ConvexHull, 1);
pinky_base = s_pinky(1).ConvexHull(pinky_nnidx,:);
% now find the hull points for the entire "digits" region closest to the
% hull points for the individual digits that are closest to the paw dorsum
% centroid. This ensures that when we draw a line separating the "digits"
% and "paw dorsum" regions, we take one point from the index finger and one
% point from the pinky finger.
nnHull = zeros(2,2);
[~,nnidx] = findNearestNeighbor(idx_base, centerDigitHullPoints);
nnHull(1,:) = centerDigitHullPoints(nnidx,:);
[~,nnidx] = findNearestNeighbor(pinky_base, centerDigitHullPoints);
nnHull(2,:) = centerDigitHullPoints(nnidx,:);

% now draw a line between the base of the pinky and index finger;
% everything on the same side of that line as the paw dorsum centroid is
% part of the paw dorsum; everything on the same side as the digit
% centroids is part of the digit region
% to separate these regions, create a mask that separates the image into
% two regions, and has true values on the same side as the index finger
% centroid
digitRegionMask = segregateImage(nnHull, idx_c, size(pdMask));
digitRegionMask = digitRegionMask | ...
                  maskedPaw(:,:,2) | ...
                  maskedPaw(:,:,3) | ...
                  maskedPaw(:,:,4) | ...
                  maskedPaw(:,:,5);
pdMask = pdMask & ~digitRegionMask;
[pd_A,~,~,pdLabMask] = step(pawDorsumBlob, imerode(pdMask, SE));
if isempty(pd_A)    % in case we destroy the blob by eroding it
    pd_erode = pinkyMask;
else
    validIdx = find(pd_A == max(pd_A));
    pd_erode = (pdLabMask == validIdx);
end

[~,P] = imseggeodesic(squeeze(rgb_enh(2,:,:,:)), pd_erode, middle_erode,ring_erode);
maskedPaw(:,:,1) = (P(:,:,1) > 0.9) & pawMask & ~digitRegionMask;

end
% 
% for ii = 1 : size(hsv_digitBounds, 1)
%     % calculate the boundaries of the projection from the mirror into the
%     % direct camera view
%     [mirrorMaskRows,mirrorMaskCols] = find(squeeze(digitMirrorMask(:,:,ii)));
%     mirrorBotIdx = find(mirrorMaskRows == max(mirrorMaskRows),1);
%     mirrorTopIdx = find(mirrorMaskRows == min(mirrorMaskRows),1);
%     mirrorPawBottom = [mirrorMaskCols(mirrorBotIdx), mirrorMaskRows(mirrorBotIdx)];
%     mirrorPawTop    = [mirrorMaskCols(mirrorTopIdx), mirrorMaskRows(mirrorTopIdx)];
%     
%     borderLines = epipolarLine(fundmat, [mirrorPawTop;mirrorPawBottom]);
%     
%     % create a mask with true values between the epipolar lines
%     x = 1:size(centerImg,2);
%     epipolarRegions = zeros(size(centerImg,1),size(centerImg,2),2);
%     for jj = 1 : 2
%         for kk = 1 : size(centerImg, 1)
%             epipolarRegions(kk, :, jj) = x * borderLines(jj,1) + kk * borderLines(jj,2);
%         end
%         epipolarRegions(:,:,jj) = epipolarRegions(:,:,jj) + borderLines(jj,3);
%     end
%     if strcmpi(rat_metadata.pawPref,'right')       % haven't thought through why the signs change for the
%                                                    % region of interest depending on whether mapping the left
%                                                    % or right mirror to the direct view, but this seems to
%                                                    % work
%         projectionMask = (epipolarRegions(:,:,1) < 0) & (epipolarRegions(:,:,2) > 0);
%     else
%         projectionMask = (epipolarRegions(:,:,1) > 0) & (epipolarRegions(:,:,2) < 0);
%     end
%     
%     tempMask = double(HSVthreshold(hsv_centerImg, hsv_digitBounds(ii,:)));
%     tempMask = bwdist(tempMask) < 2;
%     tempMask = imopen(tempMask, SE);
%     tempMask = imclose(tempMask, SE);
%     tempMask = imfill(tempMask, 'holes');
%     
%     % only accept regions within the projection of the mirror paw dorsum /
%     % digit into the direct camera view. make sure to keep elements of
%     % blobs that lie both within and outside the projection area
%     [~,~,~,paw_labMat] = step(pawDorsumBlob, tempMask);
%     tempMask2 = paw_labMat .* uint8(projectionMask);
%     validRegionList = unique(tempMask2);
%     validRegions = validRegionList(validRegionList > 0);
%     tempMask = false(size(centerImg,1),size(centerImg,2));
%     for jj = 1 : length(validRegions)
%         tempMask = tempMask | (paw_labMat == validRegions(jj));
%     end
%     
%     % THINK ABOUT WHETHER IT'S WORTH FINDING DIGIT
%     % CANDIDATES BEFORE EXTRACTING THE PAW PROPER. THIS MAY ALSO BE USEFUL
%     % IN THE MIRROR ALGORITHM
%     if ii == 1    % masking out the dorsum of the paw
%         % keep only the largest region
%         [paw_a, ~, ~, pawLabMat] = step(pawDorsumBlob,tempMask);
%         maxRegionIdx = find(paw_a == max(paw_a));
%         tempMask = (pawLabMat == maxRegionIdx);
%         [~, digitCtr(ii,:), ~, ~] = step(pawDorsumBlob,tempMask);
%     else
%         % use the coordinates of the dorsum of the paw to help identify
%         % which digit is which. needed because orange and red look so much
%         % alike
%         % first, exclude any points labeled as the dorsal aspect of the paw
%         % from the digits
%         tempMask = logical(tempMask .* ~squeeze(centerMask(:,:,1)));
%         [~, digit_c, ~, digitLabMat] = step(digitBlob, tempMask);
%         % first, eliminate blobs that are on the wrong side of the paw
%         % centroid (to the left if looking in the left mirror, to the right
%         % if looking in the right mirror).
%         if strcmpi(rat_metadata.pawPref,'right')    % back of paw in the left mirror
%             % looking in the left mirror for the digits
%             digitIdx = find(digit_c(:,1) < digitCtr(1));
%         else
%             % looking in the right mirror for the digits
%             digitIdx = find(digit_c(:,1) > digitCtr(1));
%         end
%         if ~isempty(digitIdx)
%             for jj = 1 : length(digitIdx)
%                 digitLabMat(digitLabMat == digitIdx(jj)) = 0;
%             end
%             tempMask = (digitLabMat > 0);
%         end
%         [~, digit_c, ~, digitLabMat] = step(digitBlob, tempMask);
%         % now, take the blob that is closest to the previous digit & below
%         % it. Can't do this for the first digit
%         if ii > 2
%             % get rid of any blobs whose centroid is above the previous
%             % digit centroid
%             digitIdx = find(digit_c(:,2) < digitCtr(ii-1,2));
%             if ~isempty(digitIdx)
%                 for jj = 1 : length(digitIdx)
%                     digitLabMat(digitLabMat == digitIdx(jj)) = 0;
%                 end
%                 tempMask = (digitLabMat > 0);
%             end
%             [~, digit_c, ~, digitLabMat] = step(digitBlob, tempMask);
%             % now, take the blob closest to the previous digit
%             digitDist = zeros(size(digit_c,1),2);
%             digitDist(:,1) = digitCtr(ii-1,1) - digit_c(:,1);
%             digitDist(:,2) = digitCtr(ii-1,2) - digit_c(:,2);
%             digitDistances = sum(digitDist.^2,2);
%             minDistIdx = find(digitDistances == min(digitDistances));
%             tempMask = (digitLabMat == minDistIdx);
%             [~, digit_c, ~, ~] = step(digitBlob, tempMask);
%         elseif size(digit_c,1) > 1
%             % take the centroid closest to the dorsum of the paw if this is
%             % the first digit identified
%             x_dist = digit_c(:,1) - digitCtr(1,1);
%             y_dist = digit_c(:,2) - digitCtr(1,2);
%             dist_from_paw = x_dist.^2 + y_dist.^2;
%             minDistIdx = find(dist_from_paw == min(dist_from_paw));
%             tempMask = (digitLabMat == minDistIdx);
%             [~, digit_c, ~, ~] = step(digitBlob, tempMask);
%             % NOTE, NOT SURE IF THIS WILL BE ROBUST - COULD GET BLOBS
%             % CLOSER TO THE PAW CENTROID THAN THE DIGITS - DL 20150609
%         end    % if ii > 2
%         digitCtr(ii,:) = digit_c;
%     end
%         
%     centerMask(:,:,ii) = tempMask;
% end
% 
% 
% % find the centroids of the digits
% 
% end