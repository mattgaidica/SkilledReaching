function [ initBorderMask, borderMask ] = findColoredBorder( img_hsv, HSVlimits, ROIs, anticipatedBoardSize )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

% INPUTS
%   img_hsv
%   HSVlimits
%   ROIs
%
% OUTPUTS
%   imgMask - mask images - h x w x 6 stored in the following order:
%       1 - direct view red
%       2 - mirror view red
%       3 - direct view green
%       4 - mirror view green
%       5 - direct view blue
%       6 - mirror view blue

SEsize = 3;
SE = strel('disk',SEsize);
minCheckerboardArea = 5000;
maxCheckerboardArea = 20000;

diffThresh = 0.1;
threshStepSize = 0.01;

h = size(img_hsv,1);
w = size(img_hsv,2);
numMirrors = size(ROIs,1) - 1;

directMask = false(h,w);
directMask(ROIs(1,2):ROIs(1,2)+ROIs(1,4)-1, ROIs(1,1):ROIs(1,1)+ROIs(1,3)-1) = true;
directView_hsv = img_hsv .* repmat(double(directMask),1,1,3);

mirrorMasks = false(h,w,3);
mirrorView_hsv = zeros(h,w,3,3);
for iView = 1 : numMirrors
    mirrorMasks(ROIs(iView+1,2):ROIs(iView+1,2)+ROIs(iView+1,4)-1, ROIs(iView+1,1):ROIs(iView+1,1)+ROIs(iView+1,3)-1,iView) = true;
    mirrorView_hsv(:,:,:,iView) = img_hsv .* repmat(double(squeeze(mirrorMasks(:,:,iView))),1,1,3);
    mirrorOnlyMasks(:,:,iView) = mirrorMasks(:,:,iView);
    mirrorMasks(:,:,iView) = directMask | squeeze(mirrorMasks(:,:,iView));
end
    
% find seed regions
initSeedMasks = false(h,w,3);
initBorderMask = false(h,w,6);
denoisedMasks = false(h,w,3);
meanHSV = zeros(3,2,3);    % 3 colors by 2 regions by 3 values
stdHSV = zeros(3,2,3);

imgMask = false(h,w,6);
for iColor = 1 : 3
    initSeedMasks(:,:,iColor) = HSVthreshold(img_hsv, HSVlimits(iColor,:));
    initSeedMasks(:,:,iColor) = squeeze(initSeedMasks(:,:,iColor)) & squeeze(mirrorMasks(:,:,iColor));
    
%     figure(iColor+1)
%     imshow(squeeze(initSeedMasks(:,:,iColor)));
    
    % clean up the noise
    denoisedMasks(:,:,iColor) = imopen(squeeze(initSeedMasks(:,:,iColor)), SE);
    denoisedMasks(:,:,iColor) = imclose(squeeze(denoisedMasks(:,:,iColor)), SE);
    
    % find stats for colors inside the mask region
    mirrorBorderMask = squeeze(denoisedMasks(:,:,iColor)) & squeeze(mirrorOnlyMasks(:,:,iColor));
    directBorderMask = squeeze(denoisedMasks(:,:,iColor)) & directMask;
    initBorderMask(:,:,2*iColor-1) = directBorderMask;
    initBorderMask(:,:,2*iColor) = mirrorBorderMask;

    [meanHSV(iColor,1,:),stdHSV(iColor,1,:)] = calcHSVstats(img_hsv, directBorderMask);
    [meanHSV(iColor,2,:),stdHSV(iColor,2,:)] = calcHSVstats(img_hsv, mirrorBorderMask);
    
    % in each view, calculate distance in hsv space to the mean values in
    % the borders
    directView_hsvDist = calcHSVdist(directView_hsv, squeeze(meanHSV(iColor,1,:)));
    mirrorView_hsvDist = calcHSVdist(squeeze(mirrorView_hsv(:,:,:,iColor)), squeeze(meanHSV(iColor,2,:)));
    
    directViewGray = mean(directView_hsvDist(:,:,1:2),3);
    mirrorViewGray = mean(mirrorView_hsvDist(:,:,1:2),3);
%     figure(iColor+4)
%     directThresh = directView_hsvDist(:,:,1) < diffThresh;
%     mirrorThresh = mirrorView_hsvDist(:,:,1) < diffThresh;
    
    % iterate until we find a border region with a single hole 
    currentThresh = diffThresh;
    foundValidBorder = false;
    while ~foundValidBorder
        directBorder = directViewGray < currentThresh;
        directBorder = imopen(directBorder, SE);
        directBorder = imclose(directBorder, SE);
        
        L = bwlabel(directBorder);
        if ~any(L(:))   % if nothing detected
            currentThresh = currentThresh + threshStepSize;
            continue;
        end
        
        for iObj = 1 : max(L(:))
            regionstats = regionprops(L == iObj,'euler');
            if regionstats.EulerNumber == 0   % a candidate border - there is one hole
                directBorder_filled = imfill(directBorder,'holes');
                testImg = directBorder_filled & ~directBorder;   % where the checkerboard should be
                teststats = regionprops(testImg,'area');
                A = teststats.Area;
                
                if A > minCheckerboardArea && A < maxCheckerboardArea
                    foundValidBorder = true;
                    directBorder = (L == iObj);
                    break;
                end
            end
        end
        currentThresh = currentThresh + threshStepSize;

    end
    [border,white_checks,black_checks] = cleanUpBorder(img_hsv, squeeze(initBorderMask(:,:,2*iColor-1)), directBorder, anticipatedBoardSize);
        
        
    % iterate until we find a border region with a single hole 
    currentThresh = diffThresh;
    foundValidBorder = false;
    while ~foundValidBorder
        mirrorBorder = mirrorViewGray < currentThresh;
        mirrorBorder = imopen(mirrorBorder, SE);
        mirrorBorder = imclose(mirrorBorder, SE);
        
        L = bwlabel(mirrorBorder);
        if ~any(L(:))   % if nothing detected
            currentThresh = currentThresh + threshStepSize;
            continue;
        end
        
        for iObj = 1 : max(L(:))
            regionstats = regionprops(L == iObj,'euler');
            if regionstats.EulerNumber == 0   % a candidate border - there is one hole
                mirrorBorder_filled = imfill(mirrorBorder,'holes');
                testImg = mirrorBorder_filled & ~mirrorBorder;   % where the checkerboard should be
                teststats = regionprops(testImg,'area');
                A = teststats.Area;
                
                if A > minCheckerboardArea && A < maxCheckerboardArea
                    foundValidBorder = true;
                    mirrorBorder = (L == iObj);
                    break;
                end
            end
        end
        currentThresh = currentThresh + threshStepSize;

    end
    % now clean up the edges
    [border,white_checks,black_checks] = cleanUpBorder(img_hsv, squeeze(initBorderMask(:,:,2*iColor)), mirrorBorder, anticipatedBoardSize);

end


end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [border,white_checks,black_checks] = cleanUpBorder(img_hsv, initBorderMask, borderMask, anticipatedBoardSize, varargin)
closeSize = 50;
openSize = 5;
maxMorphOperator = max(closeSize, openSize);
minCheckArea = 200;

for iarg = 1 : 2 : nargin - 4
    switch lower(varargin{iarg})
        case 'mincheckarea'
            minCheckArea = varargin{iarg + 1};
    end
end

% h = size(img_hsv,1);
% w = size(img_hsv,2);

q = regionprops(borderMask,'boundingbox');
ROI = floor(q.BoundingBox);

borderMask = borderMask(ROI(2):ROI(2)+ROI(4),ROI(1):ROI(1)+ROI(3));
fullBorder = imfill(borderMask,'holes');
borderInterior = fullBorder & ~borderMask;
initBorderMask = initBorderMask(ROI(2):ROI(2)+ROI(4),ROI(1):ROI(1)+ROI(3));
% pad tempMask so morphological operations don't create edge effects
paddedTempMask = false(size(borderInterior) + 2*(maxMorphOperator+5));
paddedTempMask(maxMorphOperator+5:maxMorphOperator+4+size(borderInterior,1),...
               maxMorphOperator+5:maxMorphOperator+4+size(borderInterior,2)) = borderInterior;
paddedTempMask = imclose(paddedTempMask,strel('disk',closeSize));  % get rid of bumps in the border
paddedTempMask = imopen(paddedTempMask,strel('disk',openSize));
tempMask = paddedTempMask(maxMorphOperator+5:maxMorphOperator+4+size(borderInterior,1),...
                          maxMorphOperator+5:maxMorphOperator+4+size(borderInterior,2));

% now find the statistics for the interior and border regions
cvHull = bwconvhull(tempMask);
% newBorder = borderMask & ~cvHull;

ROI_hsv = img_hsv(ROI(2):ROI(2)+ROI(4),ROI(1):ROI(1)+ROI(3),:);
img_rgb = hsv2rgb(ROI_hsv);
img_gray = rgb2gray(img_rgb);
img_r = squeeze(img_rgb(:,:,1)); img_r = img_r(:);
img_g = squeeze(img_rgb(:,:,2)); img_g = img_g(:);
img_b = squeeze(img_rgb(:,:,3)); img_b = img_b(:);

testGray = img_gray .* double(cvHull);
checkThresh = graythresh(testGray);

checks_white = testGray > checkThresh;
[isolated_checks_white, ~, ~] = isolateCheckerboardSquares(checks_white,anticipatedBoardSize,'minarea',minCheckArea);

checks_black = testGray < checkThresh & testGray > 0;
[isolated_checks_black, ~, ~] = isolateCheckerboardSquares(checks_black,anticipatedBoardSize,'minarea',minCheckArea);

meanRGB = cell(1,3);
% white checks
meanRGB{1}(1) = mean(img_r(isolated_checks_white(:)));
meanRGB{1}(2) = mean(img_g(isolated_checks_white(:)));
meanRGB{1}(3) = mean(img_b(isolated_checks_white(:)));

% black checks
meanRGB{2}(1) = mean(img_r(isolated_checks_black(:)));
meanRGB{2}(2) = mean(img_g(isolated_checks_black(:)));
meanRGB{2}(3) = mean(img_b(isolated_checks_black(:)));


% border
meanRGB{3}(1) = mean(img_r(initBorderMask(:)));
meanRGB{3}(2) = mean(img_g(initBorderMask(:)));
meanRGB{3}(3) = mean(img_b(initBorderMask(:)));

distMaps = zeros(size(img_rgb,1), size(img_rgb,2),3);
for iFeature = 1 : 3
    distMaps(:,:,iFeature) = sqrt((img_rgb(:,:,1) - meanRGB{iFeature}(1)).^2 + ...
                              (img_rgb(:,:,2) - meanRGB{iFeature}(2)).^2 + ...
                              (img_rgb(:,:,3) - meanRGB{iFeature}(3)).^2);
	
end
[~,minIndices] = min(distMaps,[],3);

border = minIndices == 3;
white_checks = minIndices == 1;
black_checks = minIndices == 2;

border = border & borderMask;
white_checks = white_checks & fullBorder;
black_checks = black_checks & fullBorder;

white_check_interior_overlap = white_checks & borderInterior;
black_check_interior_overlap = black_checks & borderInterior;

white_checks = imreconstruct(white_check_interior_overlap, white_checks);
black_checks = imreconstruct(black_check_interior_overlap, black_checks);

white_checks = isolateCheckerboardSquares(white_checks,anticipatedBoardSize,'minarea',minCheckArea);
black_checks = isolateCheckerboardSquares(black_checks,anticipatedBoardSize,'minarea',minCheckArea);
% now loop through border pixels 

% isolated_checks_white = isolated_checks_white | eroded_checks_white;

% [meanBorderHSV,~] = calcHSVstats(img_hsv, initBorderMask);
% [meanWhiteCheckHSV,~] = calcHSVstats
% [meanBlackCheckHSV,~] = calcHSVstats



end


