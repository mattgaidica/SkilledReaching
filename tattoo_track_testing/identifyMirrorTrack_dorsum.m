function maskedPaw = identifyMirrorTrack_dorsum(image, rat_metadata, varargin)
%
% usage
%
% function to find the location of the paw and digits in an image
% given their locations in a previous image
%
% INPUTS:
%   image - rgb masked image of paw in the relevant mirror. Seems to
%       work better if decorrstretched first to enhance color contrast
%   pawMask - black/white paw mask. easier to include this as an input than
%       extract from image; if decorrstretch has been performed,
%       backgound isn't necessarily zero
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
decorrStretchMean  = [100.0 127.5 100.0     % to isolate dorsum of paw
                      100.0 127.5 100.0     % to isolate blue digits
                      100.0 127.5 100.0     % to isolate red digits
                      127.5 100.0 127.5     % to isolate green digits
                      100.0 127.5 100.0];   % to isolate red digits
decorrStretchSigma = [025 025 025       % to isolate dorsum of paw
                      025 025 025       % to isolate blue digits
                      025 025 025       % to isolate red digits
                      025 025 025       % to isolate green digits
                      025 025 025];     % to isolate red digits
decorrStretchSigma = [050 050 050       % to isolate dorsum of paw
                      050 050 050       % to isolate blue digits
                      050 050 050       % to isolate red digits
                      050 050 050       % to isolate green digits
                      050 050 050];     % to isolate red digits

% hsv_digitBounds = [0.33 0.33 0.00 0.90 0.00 0.90
%                    0.67 0.16 0.90 1.00 0.80 1.00
%                    0.00 0.16 0.90 1.00 0.80 1.00
%                    0.33 0.16 0.90 1.00 0.90 1.00
%                    0.00 0.16 0.90 1.00 0.80 1.00];
rgb_digitBounds = [0.00 0.50 0.50 1.00 0.00 0.80
                   0.00 0.10 0.00 0.60 0.80 1.00
                   0.90 1.00 0.00 0.40 0.00 0.40
                   0.00 0.70 0.90 1.00 0.00 0.50
                   0.00 0.16 0.90 1.00 0.80 1.00];

for iarg = 1 : 2 : nargin - 2
    switch lower(varargin{iarg})
        case digitBounds,
            rgb_digitBounds = varargin{iarg + 1};
    end
end

pawDorsumBlob = vision.BlobAnalysis;
pawDorsumBlob.AreaOutputPort = true;
pawDorsumBlob.CentroidOutputPort = true;
pawDorsumBlob.BoundingBoxOutputPort = true;
pawDorsumBlob.ExtentOutputPort = true;
pawDorsumBlob.LabelMatrixOutputPort = true;
pawDorsumBlob.MinimumBlobArea = 1000;

digitBlob = vision.BlobAnalysis;
digitBlob.AreaOutputPort = true;
digitBlob.CentroidOutputPort = true;
digitBlob.BoundingBoxOutputPort = true;
digitBlob.ExtentOutputPort = true;
digitBlob.LabelMatrixOutputPort = true;
digitBlob.MinimumBlobArea = 50;
digitBlob.MaximumBlobArea = 1500;

pawMask = (rgb2gray(image) > 0);
s = regionprops(pawMask,'area','centroid');
wholePawCentroid = s.Centroid;
% wholePawArea     = s.Area;      % this might be useful to set minimum and maximum digit/paw dorsum sizes as a function of the total paw size

% 1st row masks the dorsum of the paw
% next 4 rows mask the digits

SE = strel('disk',2);
% digitCtr = zeros(size(rgb_digitBounds,1), 2);
rgb_enh = zeros(size(rgb_digitBounds,1), size(image,1),size(image,2),size(image,3));
for ii = 1 : size(rgb_digitBounds, 1)
    
    % CREATE THE ENHANCED IMAGE DEPENDING ON ii BEFORE DOING ANYTHING ELSE
    rgb_enh(ii,:,:,:)  = enhanceColorImage(image, ...
                                           decorrStretchMean(ii,:), ...
                                           decorrStretchSigma(ii,:), ...
                                           'mask',pawMask);
end
% mask out the purple and red digits first
idxMask = squeeze(rgb_enh(2,:,:,1)) >= rgb_digitBounds(2,1) & ...
          squeeze(rgb_enh(2,:,:,1)) <= rgb_digitBounds(2,2) & ...
          squeeze(rgb_enh(2,:,:,2)) >= rgb_digitBounds(2,3) & ...
          squeeze(rgb_enh(2,:,:,2)) <= rgb_digitBounds(2,4) & ...
          squeeze(rgb_enh(2,:,:,3)) >= rgb_digitBounds(2,5) & ...
          squeeze(rgb_enh(2,:,:,3)) <= rgb_digitBounds(2,6);
idxMask = bwdist(idxMask) < 2;
idxMask = imopen(idxMask, SE);
idxMask = imclose(idxMask, SE);
idxMask = imfill(idxMask, 'holes');
[~,idx_c,~,~,idxLabMask] = step(digitBlob, idxMask);
% index finger must be to the right of the whole paw centroid
if strcmpi(rat_metadata.pawPref,'right')    % back of paw in the left mirror
    % looking in the left mirror for the digits
    validIdx = find(idx_c(:,1) > wholePawCentroid(1));
else
    % looking in the right mirror for the digits
    validIdx = find(idx_c(:,1) < wholePawCentroid(1));
end
idxMask = false(size(idxMask));
for ii = 1 : length(validIdx)
    idxMask = idxMask | (idxLabMask == validIdx(ii));
end
[idx_A,~,~,~,idxLabMask] = step(digitBlob, idxMask);
validIdx = find(idx_A == max(idx_A));
idxMask = (idxLabMask == validIdx);
[~,idx_c,~,~,~] = step(digitBlob, idxMask);

mpMask  = squeeze(rgb_enh(3,:,:,1)) >= rgb_digitBounds(3,1) & ...
          squeeze(rgb_enh(3,:,:,1)) <= rgb_digitBounds(3,2) & ...
          squeeze(rgb_enh(3,:,:,2)) >= rgb_digitBounds(3,3) & ...
          squeeze(rgb_enh(3,:,:,2)) <= rgb_digitBounds(3,4) & ...
          squeeze(rgb_enh(3,:,:,3)) >= rgb_digitBounds(3,5) & ...
          squeeze(rgb_enh(3,:,:,3)) <= rgb_digitBounds(3,6);
mpMask = bwdist(mpMask) < 2;
mpMask = imopen(mpMask, SE);
mpMask = imclose(mpMask, SE);
mpMask = imfill(mpMask, 'holes');
[~,mp_c,~,~,mpLabMask] = step(digitBlob, mpMask);
% fingers must be to the right of the whole paw centroid
if strcmpi(rat_metadata.pawPref,'right')    % back of paw in the left mirror
    % looking in the left mirror for the digits
    validIdx = find(mp_c(:,1) > wholePawCentroid(1));
else
    % looking in the right mirror for the digits
    validIdx = find(mp_c(:,1) < wholePawCentroid(1));
end
mpMask = false(size(mpMask));
for ii = 1 : length(validIdx)
    mpMask = mpMask | (mpLabMask == validIdx(ii));
end
[mp_A,~,~,~,mpLabMask] = step(digitBlob, mpMask);
% take the two largest remaining blobs as the middle and pinky digits
[~, sortIdx] = sort(mp_A);
sortIdx = sortIdx(end-1:end);
mpMask = false(size(mpMask));
for ii = 1 : 2
    mpMask = mpMask | (mpLabMask == sortIdx(ii));
end
% identify the pinky as the centroid farthest from the index finger
[~,mp_c,~,~,mpLabMask] = step(digitBlob, mpMask);
[~, nnidx] = findNearestNeighbor(idx_c, mp_c, 1);
pinkyMask = (mpLabMask > 0 & mpLabMask ~= nnidx);
middleMask = (mpLabMask == nnidx);
middle_c = mp_c(nnidx,:);

% now identify the dorsum of the paw as everything on the opposite side of
% a line connecting the base of the index finger and pinky compared to the
% digit centroids
% start by creating the convex hull mask for all the digits together
digitMasks = false(size(mpMask,1),size(mpMask,2));
digitMasks(:,:,1) = mpMask;
digitMasks(:,:,2) = idxMask;
[digitHullMask,digitHullPoints] = multiRegionConvexHullMask(digitMasks);

% make the paw dorsum mask overly inclusive, then subtract out the mask
% that contains the digits
pdMask  = squeeze(rgb_enh(1,:,:,1)) >= rgb_digitBounds(1,1) & ...
          squeeze(rgb_enh(1,:,:,1)) <= rgb_digitBounds(1,2) & ...
          squeeze(rgb_enh(1,:,:,2)) >= rgb_digitBounds(1,3) & ...
          squeeze(rgb_enh(1,:,:,2)) <= rgb_digitBounds(1,4) & ...
          squeeze(rgb_enh(1,:,:,3)) >= rgb_digitBounds(1,5) & ...
          squeeze(rgb_enh(1,:,:,3)) <= rgb_digitBounds(1,6);
      
pdMask = pdMask & ~digitHullMask;    % make 
pdMask = bwdist(pdMask) < 2;
pdMask = imopen(pdMask, SE);
pdMask = imclose(pdMask, SE);
pdMask = imfill(pdMask, 'holes');
[pd_a,~,~,~,pdLabMask] = step(pawDorsumBlob, pdMask);
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
s_idx = regionprops(idxMask, 'ConvexHull');
[~,idx_nnidx] = findNearestNeighbor(pdCentroid, s_idx(1).ConvexHull, 1);
idx_base = s_idx(1).ConvexHull(idx_nnidx,:);
% find the hull point for the pinky closest to the paw dorsum centroid
[~,pinkyHullPoints] = multiRegionConvexHullMask(pinkyMask);
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
digitRegionMask = segregateImage(nnHull, idx_c, size(pdMask));
digitRegionMask = digitRegionMask | ...
                  idxMask | ...
                  middleMask | ...
                  pinkyMask;
pdMask = pdMask & ~digitRegionMask;

% now should have index finger, middle finger, pinky, and dorsum of paw
% masked out. Now just need the ring finger
ringMask = squeeze(rgb_enh(4,:,:,1)) >= rgb_digitBounds(4,1) & ...
           squeeze(rgb_enh(4,:,:,1)) <= rgb_digitBounds(4,2) & ...
           squeeze(rgb_enh(4,:,:,2)) >= rgb_digitBounds(4,3) & ...
           squeeze(rgb_enh(4,:,:,2)) <= rgb_digitBounds(4,4) & ...
           squeeze(rgb_enh(4,:,:,3)) >= rgb_digitBounds(4,5) & ...
           squeeze(rgb_enh(4,:,:,3)) <= rgb_digitBounds(4,6);
ringMask = bwdist(ringMask) < 2;
ringMask = imopen(ringMask, SE);
ringMask = imclose(ringMask, SE);
ringMask = imfill(ringMask, 'holes');
ringMask = ringMask & digitRegionMask;    % only take points in the same area as the other digits
[~, ring_c, ~, ~, ringLabMask] = step(digitBlob, ringMask);
[~, nnidx] = findNearestNeighbor(middle_c, ring_c, 1);
ringMask = (ringLabMask == nnidx);

% % get centroids for each region
% [~,pd_centroid,~,~,~]  = step(digitBlob, pdMask);
% [~,idx_centroid,~,~,~]  = step(digitBlob, idxMask);
% [~,mid_centroid,~,~,~]  = step(digitBlob, middleMask);
% [~,ring_centroid,~,~,~] = step(digitBlob, ringMask);
% [~,pinky_centroid,~,~,~] = step(digitBlob, pinkyMask);

% create masks using only the center points
% imshow(image)
% hold on
% plot(idx_centroid(1),idx_centroid(2),'marker','*')
% plot(mid_centroid(1),mid_centroid(2),'marker','*')
% plot(ring_centroid(1),ring_centroid(2),'marker','*')
% now have all the fingers
SE = strel('disk',3);
[pd_A,~,~,~,pdLabMask] = step(pawDorsumBlob, imerode(pdMask, SE));
if isempty(pd_A)    % in case we destroy the blob by eroding it
    pd_erode = pdMask;
else
    validIdx = find(pd_A == max(pd_A));
    pd_erode = (pdLabMask == validIdx);
end

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
if isempty(pinky_A)    % in case we destroy the blob by eroding it
    pinky_erode = pinkyMask;
else
    validIdx = find(pinky_A == max(pinky_A));
    pinky_erode = (pinkyLabMask == validIdx);
end


[L,P] = imseggeodesic(image, idx_erode, middle_erode, ring_erode);
[L2, P2] = imseggeodesic(image, pd_erode, pinky_erode, middle_erode);

% [L,P] = imseggeodesic(image, imerode(idxMask, SE), imerode(middleMask, SE), imerode(ringMask, SE));
% [L2,P2] = imseggeodesic(image, imerode(pdMask, SE), imerode(pinkyMask, SE));
% [L,P] = imseggeodesic(image, imerode(idxMask, SE), imerode(middleMask, SE), imerode(ringMask, SE));
% [L2,P2] = imseggeodesic(image, imerode(pdMask, SE), imerode(pinkyMask, SE));
maskedPaw = false(size(image,1), size(image,2), size(rgb_digitBounds,1));
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
        maskedPaw(:,:,ii) = (labMask == maxAreaIdx);
    end
    maskedPaw(:,:,ii) = imfill(squeeze(maskedPaw(:,:,ii)),'holes');
end


% ringMask = (ringLabMask == nnidx);
% for ii = 1 : size(hsv_digitBounds, 1)
%     tempMask = squeeze(rgb_enh(ii,:,:,1)) >= rgb_digitBounds(ii,1) & ...
%                squeeze(rgb_enh(ii,:,:,1)) <= rgb_digitBounds(ii,2) & ...
%                squeeze(rgb_enh(ii,:,:,2)) >= rgb_digitBounds(ii,3) & ...
%                squeeze(rgb_enh(ii,:,:,2)) <= rgb_digitBounds(ii,4) & ...
%                squeeze(rgb_enh(ii,:,:,3)) >= rgb_digitBounds(ii,5) & ...
%                squeeze(rgb_enh(ii,:,:,3)) <= rgb_digitBounds(ii,6);
%            % WORKING HERE - WHAT HAPPENS IF WE PULL OUT THE PURPLE AND RED
%            % DIGITS FIRST, SINCE THEY SHOW UP PRETTY ROBUSTLY?
%            
%            
% %     tempMask = double(HSVthreshold(hsv_image, hsv_digitBounds(ii,:)));
%     tempMask = tempMask & (rgb2gray(image) > 0);
%     tempMask = bwdist(tempMask) < 2;
%     tempMask = imopen(tempMask, SE);
%     if ii ~= 3 && ii ~=5    % this can put the two red digits in contact and screw up the analysis
%         tempMask = imclose(tempMask, SE);
%     end
%     tempMask = imfill(tempMask, 'holes');
%     if ii == 1    % masking out the dorsum of the paw
%         % keep only the largest region
%         [paw_a, ~, ~, ~, pawLabMat] = step(pawDorsumBlob,tempMask);
%         maxRegionIdx = find(paw_a == max(paw_a));
%         tempMask = (pawLabMat == maxRegionIdx);
%         % fill in the convex hull
%         s = regionprops(tempMask,'boundingbox','conveximage');
%         x_w = size(s.ConvexImage,1);
%         y_w = size(s.ConvexImage,2);
%         x_maskBorders = round([s.BoundingBox(2),s.BoundingBox(2)+x_w-1]);
%         y_maskBorders = round([s.BoundingBox(1),s.BoundingBox(1)+y_w-1]);
%         tempMask2 = false(size(tempMask));
%         tempMask2(x_maskBorders(1):x_maskBorders(2),y_maskBorders(1):y_maskBorders(2)) = s.ConvexImage;
%         [~, digitCtr(ii,:), ~, ~, paw_labMat] = step(pawDorsumBlob,tempMask2);
%         tempMask = (paw_labMat > 0);
%     else
%         % use the coordinates of the dorsum of the paw to help identify
%         % which digit is which. needed because orange and red look so much
%         % alike
%         % first, exclude any points labeled as the dorsal aspect of the paw
%         % from the digits
%         tempMask = logical(tempMask .* ~squeeze(digitMask(:,:,1)));
%         [~, digit_c, ~, ~, digitLabMat] = step(digitBlob, tempMask);
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
%         [~, digit_c, ~, ~, digitLabMat] = step(digitBlob, tempMask);
%         tempMask = (digitLabMat > 0);
%         % incorporate an extent condition for digits here?
%         
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
%             [~, digit_c, ~, ~, digitLabMat] = step(digitBlob, tempMask);
%             % now, take the blob closest to the previous digit
%             digitDist = zeros(size(digit_c,1),2);
%             digitDist(:,1) = digitCtr(ii-1,1) - digit_c(:,1);
%             digitDist(:,2) = digitCtr(ii-1,2) - digit_c(:,2);
%             digitDistances = sum(digitDist.^2,2);
%             minDistIdx = find(digitDistances == min(digitDistances));
%             tempMask = (digitLabMat == minDistIdx);
%             [~, digit_c, ~, ~, ~] = step(digitBlob, tempMask);
%         elseif size(digit_c,1) > 1
%             % take the centroid closest to the dorsum of the paw if this is
%             % the first digit identified
%             x_dist = digit_c(:,1) - digitCtr(1,1);
%             y_dist = digit_c(:,2) - digitCtr(1,2);
%             dist_from_paw = x_dist.^2 + y_dist.^2;
%             minDistIdx = find(dist_from_paw == min(dist_from_paw));
%             tempMask = (digitLabMat == minDistIdx);
%             [~, digit_c, ~, ~, ~] = step(digitBlob, tempMask);
%             % NOTE, NOT SURE IF THIS WILL BE ROBUST - COULD GET BLOBS
%             % CLOSER TO THE PAW CENTROID THAN THE DIGITS - DL 20150609
%         end    % if ii > 2
%         digitCtr(ii,:) = digit_c;
%     end
%         
%     digitMask(:,:,ii) = tempMask;
% end


% find the centroids of the digits

end