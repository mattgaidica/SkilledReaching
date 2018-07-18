function [ imgMask ] = findDirectBorders( img, HSVlimits, ROIs )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here

% INPUTS

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

h = size(img,1);
w = size(img,2);

img_stretch = decorrstretch(img);

<<<<<<< HEAD
figure(1); imshow(img_stretch);

=======
>>>>>>> 363fc4784b2116b41dc66594009feea8f6b6fff5
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
    imgMask(:,:,iColor) = imopen(directBorder,strel('disk',3));
    imgMask(:,:,iColor) = imclose(imgMask(:,:,iColor),strel('disk',3));
    imgMask(:,:,iColor) = directBorder;
        
end


end


    % iterate until we find a border region with a single hole 
%     currentThresh = diffThresh;
%     foundValidBorder = false;
%     while ~foundValidBorder
%         mirrorBorder = mirrorViewGray < currentThresh;
%         mirrorBorder = imopen(mirrorBorder, SE);
%         mirrorBorder = imclose(mirrorBorder, SE);
%         
%         L = bwlabel(mirrorBorder);
%         if ~any(L(:))   % if nothing detected
%             currentThresh = currentThresh + threshStepSize;
%             continue;
%         end
%         
%         for iObj = 1 : max(L(:))
%             regionstats = regionprops(L == iObj,'euler');
%             if regionstats.EulerNumber == 0   % a candidate border - there is one hole
%                 mirrorBorder_filled = imfill(mirrorBorder,'holes');
%                 testImg = mirrorBorder_filled & ~mirrorBorder;   % where the checkerboard should be
%                 teststats = regionprops(testImg,'area');
%                 A = teststats.Area;
%                 
%                 if A > minCheckerboardArea && A < maxCheckerboardArea
%                     foundValidBorder = true;
%                     mirrorBorder = (L == iObj);
%                     break;
%                 end
%             end
%         end
%         currentThresh = currentThresh + threshStepSize;
% 
%     end
%     imgMask(:,:,2*iColor) = mirrorBorder;
% 
% end



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% function newMasks = cleanUpBorder(img, oldBorder)
% 
% newMasks = false(size(oldBorder));
% img_hsv = rgb2hsv(img);
% 
% for iMask = 1 : size(oldBorder, 6)
%     
%     
%     
%     
% end    % end for iMask...
% 
% 
% 
% end
    