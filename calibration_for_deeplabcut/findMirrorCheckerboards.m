function mirrorChecks = findMirrorCheckerboards(img, directBorderMask, directBorderChecks, mirror_hsvThresh, anticipatedBoardSize, ROIs)

minCornerStep = 0.01;
minCornerMetric = 0.15;   % algorithm default
maxDetectAttempts = 10;
minCheckerboardFract = prod(anticipatedBoardSize-2)/prod(anticipatedBoardSize) - 0.05;

SEsize = 3;
SE = strel('disk',SEsize);
minCheckerboardArea = 5000;
maxCheckerboardArea = 20000;

h = size(img,1);
w = size(img,2);

img_stretch = decorrstretch(img);
% figure(1); imshow(img_stretch);
img_hsv = rgb2hsv(img_stretch);

numBoards = size(directBorderMask,3);

initSeedMasks = false(h,w,3);
denoisedMasks = false(h,w,3);
meanHSV = zeros(3,2,3);    % 3 colors by 2 regions by 3 values
stdHSV = zeros(3,2,3);

imgMask = false(h,w,3);

for iBoard = 1 : numBoards

    mirrorMask = false(h,w);
    mirrorMask(ROIs(iBoard+1,2):ROIs(iBoard+1,2)+ROIs(iBoard+1,4)-1, ...
               ROIs(iBoard+1,1):ROIs(iBoard+1,1)+ROIs(iBoard+1,3)-1) = true;
    mirrorView_hsv = img_hsv .* repmat(double(mirrorMask),1,1,3);
    
    initSeedMasks(:,:,iBoard) = HSVthreshold(img_hsv, mirror_hsvThresh(iBoard,:)) & mirrorMask;
    denoisedMasks(:,:,iBoard) = imopen(squeeze(initSeedMasks(:,:,iBoard)), SE);
    denoisedMasks(:,:,iBoard) = imclose(squeeze(denoisedMasks(:,:,iBoard)), SE);
    
    mirrorBorderMask = squeeze(denoisedMasks(:,:,iBoard));
    [meanHSV(iBoard,1,:),stdHSV(iBoard,1,:)] = calcHSVstats(img_hsv, mirrorBorderMask);
    
    mirrorView_hsvDist = calcHSVdist(mirrorView_hsv, squeeze(meanHSV(iBoard,1,:)));
    
    mirrorViewGray = mean(mirrorView_hsvDist(:,:,1:2),3);
    
end


end