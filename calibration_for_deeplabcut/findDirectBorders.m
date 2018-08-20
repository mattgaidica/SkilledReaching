function [ imgMask ] = findDirectBorders( img, HSVlimits, ROIs )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

% INPUTS

% OUTPUTS
%   imgMask - mask images - h x w x 6 stored in the following order:
%       1 - direct view red
%       2 - direct view green
%       3 - direct view blue

if isa(img,'uint8')
    img = double(img) / 255;
end
im_eq = adapthisteq(rgb2gray(img));
im_hsv = rgb2hsv(img);
hsv_eq = im_hsv;
hsv_eq(:,:,3) = im_eq;
rgb_eq = hsv2rgb(hsv_eq);

img_stretch = decorrstretch(rgb_eq);

SEsize = 3;
SE = strel('disk',SEsize);
minCheckerboardArea = 5000;
maxCheckerboardArea = 20000;

diffThresh = 0.1;
threshStepSize = 0.01;

h = size(img,1);
w = size(img,2);



% figure(1); imshow(img_stretch);

img_hsv = rgb2hsv(img_stretch);

directMask = false(h,w);
directMask(ROIs(1,2):ROIs(1,2)+ROIs(1,4)-1, ROIs(1,1):ROIs(1,1)+ROIs(1,3)-1) = true;
directView_hsv = img_hsv .* repmat(double(directMask),1,1,3);

% mirrorMasks = false(h,w,3);
% mirrorView_hsv = zeros(h,w,3,3);
% for iView = 1 : numMirrors
%     mirrorMasks(ROIs(iView+1,2):ROIs(iView+1,2)+ROIs(iView+1,4)-1, ROIs(iView+1,1):ROIs(iView+1,1)+ROIs(iView+1,3)-1,iView) = true;
%     mirrorView_hsv(:,:,:,iView) = img_hsv .* repmat(double(squeeze(mirrorMasks(:,:,iView))),1,1,3);
%     mirrorMasks(:,:,iView) = directMask | squeeze(mirrorMasks(:,:,iView));
% end
    
% find seed regions
initSeedMasks = false(h,w,3);
denoisedMasks = false(h,w,3);
meanHSV = zeros(3,2,3);    % 3 colors by 2 regions by 3 values
stdHSV = zeros(3,2,3);

imgMask = false(h,w,3);
for iColor = 1 : 3
    initSeedMasks(:,:,iColor) = HSVthreshold(img_hsv, HSVlimits(iColor,:)) & directMask;
%     initSeedMasks(:,:,iColor) = squeeze(initSeedMasks(:,:,iColor)) & squeeze(mirrorMasks(:,:,iColor));
    
%     figure(iColor+1)
%     imshow(squeeze(initSeedMasks(:,:,iColor)));
    
    % clean up the noise
    denoisedMasks(:,:,iColor) = imopen(squeeze(initSeedMasks(:,:,iColor)), SE);
    denoisedMasks(:,:,iColor) = imclose(squeeze(denoisedMasks(:,:,iColor)), SE);
    
    % find stats for colors inside the mask region
%     mirrorBorderMask = squeeze(denoisedMasks(:,:,iColor)) & squeeze(mirrorMasks(:,:,iColor));
    directBorderMask = squeeze(denoisedMasks(:,:,iColor));
    [meanHSV(iColor,1,:),stdHSV(iColor,1,:)] = calcHSVstats(img_hsv, directBorderMask);
%     [meanHSV(iColor,2,:),stdHSV(iColor,2,:)] = calcHSVstats(img_hsv, mirrorBorderMask);
    
    % in each view, calculate distance in hsv space to the mean values in
    % the borders
    directView_hsvDist = calcHSVdist(directView_hsv, squeeze(meanHSV(iColor,1,:)));
%     mirrorView_hsvDist = calcHSVdist(squeeze(mirrorView_hsv(:,:,:,iColor)), squeeze(meanHSV(iColor,2,:)));
    
    directViewGray = mean(directView_hsvDist(:,:,1:2),3);
%     mirrorViewGray = mean(mirrorView_hsvDist(:,:,1:2),3);
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
    % smooth it
%     imgMask(:,:,iColor) = imopen(directBorder,strel('disk',3));
%     imgMask(:,:,iColor) = imclose(imgMask(:,:,iColor),strel('disk',3));
    imgMask(:,:,iColor) = directBorder;
        
end


end

    
