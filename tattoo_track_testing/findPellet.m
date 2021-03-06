function pelletMasks = findPellet(BGimg_ud, boxCalibration, varargin)
%
% INPUTS:
%   BGimg_ud - undistorted background image
%   boxCalibration - boxCalibration structure that includes the boxMarkers
%       and fundamental matrix
%
% OUTPUTS:
%   pelletMasks - 

maxEccentricity = 0.90;

for iarg = 1 : 2 : nargin - 2
    switch lower(varargin{iarg})
        case 'maxeccentricity',
            maxEccentricity = varargin{iarg + 1};
    end
end

pelletBlob = cell(1,2);
pelletBlob{1} = vision.BlobAnalysis;
pelletBlob{1}.AreaOutputPort = true;
pelletBlob{1}.CentroidOutputPort = true;
pelletBlob{1}.BoundingBoxOutputPort = true;
pelletBlob{1}.ExtentOutputPort = true;
pelletBlob{1}.LabelMatrixOutputPort = true;
pelletBlob{1}.MinimumBlobArea = 150;
pelletBlob{1}.MaximumBlobArea = 600;

pelletBlob{2} = vision.BlobAnalysis;
pelletBlob{2}.AreaOutputPort = true;
pelletBlob{2}.CentroidOutputPort = true;
pelletBlob{2}.BoundingBoxOutputPort = true;
pelletBlob{2}.ExtentOutputPort = true;
pelletBlob{2}.LabelMatrixOutputPort = true;
pelletBlob{2}.MinimumBlobArea = 300;
pelletBlob{2}.MaximumBlobArea = 700;

pelletBlob{3} = pelletBlob{1};

boxMarkers = boxCalibration.boxMarkers;
F = boxCalibration.F;

h = size(BGimg_ud,1);
w = size(BGimg_ud,2);

[~, center_region_mask] = reach_region_mask(boxMarkers, [h,w]);
leftRegion = false(h,w);
rightRegion = false(h,w);
frontPanelMask = false(h,w);

leftRegion(:,1:round(w/2)) = true;
leftRegion = leftRegion & ~center_region_mask;
rightRegion(:,round(w/2):end) = true;
rightRegion = rightRegion & ~center_region_mask;


pelletMasks = cell(1,3);

pellet_hsvThresh = zeros(3,6);
pellet_hsvThresh(1,:) = [0.5,0.5,0.0001,0.09,0.4,1.0];    % left mirror
pellet_hsvThresh(2,:) = [0.5,0.5,0.0001,0.09,0.8,1.0];    % direct view
pellet_hsvThresh(3,:) = [0.5,0.5,0.0001,0.09,0.4,1.0];    % right mirror

S = whos('BGimg_ud');
if strcmpi(S.class,'uint8')
    BGimg_ud = double(BGimg_ud) / 255;
end
BGhsv = rgb2hsv(BGimg_ud);

for iView = 1 : 3
    pelletMasks{iView} = HSVthreshold(BGhsv, pellet_hsvThresh(iView,:));
end
pelletMasks{2} = pelletMasks{2} & center_region_mask;
pelletMasks{1} = pelletMasks{1} & leftRegion;
pelletMasks{3} = pelletMasks{3} & rightRegion;

% start with center view
SE = strel('disk',2);
tempMask = imopen(pelletMasks{2}, SE);
tempMask = imclose(tempMask, SE);
tempMask = imfill(tempMask, 'holes');

[~,~,~,pelletEcc,labMat] = step(pelletBlob{2}, tempMask);
for jj = 1 : length(pelletEcc)
    if pelletEcc(jj) > maxEccentricity
        labMat(labMat == jj) = 0;
    end
end
tempMask = labMat > 0;
pelletMasks{2} = tempMask;

leftProjMask = calcProjMask(pelletMasks{2}, F.left, [1,1], [h,w]);
rightProjMask = calcProjMask(pelletMasks{2}, F.right, [1,1], [h,w]);

% now do the left
tempMask = leftProjMask & pelletMasks{1};
SE = strel('disk',2);
tempMask = imopen(tempMask, SE);
tempMask = imclose(tempMask, SE);
tempMask = imfill(tempMask, 'holes');

[~,~,~,pelletEcc,labMat] = step(pelletBlob{1}, tempMask);
for jj = 1 : length(pelletEcc)
    if pelletEcc(jj) > maxEccentricity
        labMat(labMat == jj) = 0;
    end
end
tempMask = labMat > 0;
pelletMasks{1} = tempMask;

% now do the right
tempMask = rightProjMask & pelletMasks{3};
SE = strel('disk',2);
tempMask = imopen(tempMask, SE);
tempMask = imclose(tempMask, SE);
tempMask = imfill(tempMask, 'holes');

[~,~,~,pelletEcc,labMat] = step(pelletBlob{3}, tempMask);
for jj = 1 : length(pelletEcc)
    if pelletEcc(jj) > maxEccentricity
        labMat(labMat == jj) = 0;
    end
end
tempMask = labMat > 0;
pelletMasks{3} = tempMask;

end