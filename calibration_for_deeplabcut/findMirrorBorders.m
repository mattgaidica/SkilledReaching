function imgMask = findMirrorBorders(img, directBorderMask, HSVlimits, ROIs)

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
minSolidity = 0.8;

diffThresh = 0.1;
threshStepSize = 0.01;

h = size(img,1);
w = size(img,2);

initSeedMasks = false(h,w,3);
denoisedMasks = false(h,w,3);

% figure(1); imshow(img_stretch);

img_hsv = rgb2hsv(img_stretch);
imgMask = false(h,w,3);
for iMirror = 1 : 3
    mirrorMask = false(h,w);
    mirrorMask(ROIs(iMirror+1,2):ROIs(iMirror+1,2)+ROIs(iMirror+1,4)-1, ROIs(iMirror+1,1):ROIs(iMirror+1,1)+ROIs(iMirror+1,3)-1) = true;
    mirrorView_hsv = img_hsv .* repmat(double(mirrorMask),1,1,3);
    
    initSeedMasks(:,:,iMirror) = HSVthreshold(mirrorView_hsv, HSVlimits(iMirror,:)) & mirrorMask;
    
    denoisedMasks(:,:,iMirror) = imopen(squeeze(initSeedMasks(:,:,iMirror)), SE);
    denoisedMasks(:,:,iMirror) = imclose(squeeze(denoisedMasks(:,:,iMirror)), SE);
    
    mirrorBorderMask = squeeze(denoisedMasks(:,:,iMirror));
    [meanHSV(iMirror,1,:),stdHSV(iMirror,1,:)] = calcHSVstats(img_hsv, mirrorBorderMask);
    
    mirrorView_hsvDist = calcHSVdist(mirrorView_hsv, squeeze(meanHSV(iMirror,1,:)));
    
%     
    mirrorViewGray = mean(mirrorView_hsvDist(:,:,1:2),3);
%     mirrorViewGray = mirrorView_hsvDist(:,:,1);
    
    % iterate until we find a border region with a single hole 
    currentThresh = diffThresh;
    foundValidBorder = false;
    numIterations = 0;
    while ~foundValidBorder
        if numIterations == 0
            mirrorBorder = mirrorBorderMask;
        else
            mirrorBorder = mirrorViewGray < currentThresh;
        end
        % saturation and intensity have to be high to accept pixels
%         mirrorBorder = mirrorBorder & (mirrorView_hsv(:,:,2) > HSVlimits(iMirror,3)) & ...
%             (mirrorView_hsv(:,:,3) > HSVlimits(iMirror,5));
        mirrorBorder = imopen(mirrorBorder, SE);
        mirrorBorder = imclose(mirrorBorder, SE);
        
        L = bwlabel(mirrorBorder);
        if ~any(L(:))   % if nothing detected
            currentThresh = currentThresh + threshStepSize;
            continue;
        end
        
        % what if we have multiple potential borders and only one of them
        % is the right one?
        for iObj = 1 : max(L(:))
            regionstats = regionprops(L == iObj,'euler');
            if regionstats.EulerNumber == 0   % a candidate border - there is one hole
                mirrorBorder_filled = imfill(L == iObj,'holes');
                testImg = mirrorBorder_filled & ~(L == iObj);   % where the checkerboard should be
                teststats = regionprops(testImg,'area');
                A = teststats.Area;
                
                if A > minCheckerboardArea && A < maxCheckerboardArea
                    foundValidBorder = true;
                    mirrorBorder = (L == iObj);
                    break;
                end
            end
        end
        
        % what if we have the right border but there are multiple holes in
        % it?
        mirrorBorder_filled = imfill(mirrorBorder,'holes');
        testHoles = mirrorBorder_filled & ~mirrorBorder;
        L = bwlabel(testHoles);
        for iObj = 1 : max(L(:))
            teststats = regionprops(L == iObj,'area','solidity');
            A = teststats.Area;

            if A > minCheckerboardArea && A < maxCheckerboardArea && ...
                    teststats.Solidity > minSolidity
                foundValidBorder = true;
                mirrorBorder = mirrorBorder_filled & ~(L == iObj);
                break;
            end
        end
        currentThresh = currentThresh + threshStepSize;
        numIterations = numIterations + 1;

    end

    % smooth it
%     imgMask(:,:,iMirror) = imopen(mirrorBorder,strel('disk',3));
%     imgMask(:,:,iMirror) = imclose(imgMask(:,:,iMirror),strel('disk',3));
    imgMask(:,:,iMirror) = mirrorBorder;
    
end

end