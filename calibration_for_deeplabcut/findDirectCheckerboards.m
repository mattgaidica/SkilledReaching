function [directBoardPoints,foundValidPoints] = findDirectCheckerboards(img,directBorderMask,initDirBorderMask,anticipatedBoardSize)

%UNTITLED Summary of this function goes here
%   Detailed explanation goes here

% INPUTS
%   img - full calibration image
%   directBorderMask - 
%   anticipatedBoardSize - 2 x 1 vector containing the anticipated
%       checkerboard size INCLUDING the outer edge (recall that
%       detectCheckerboardPoints will find the interior points but returns
%       boardSize that includes the outer edge)
% OUTPUTS

if iscell(img)
    num_img = length(img);
else
    num_img = 1;
    img{1} = img;
end

if iscell(directBorderMask)
    numBoards = length(directBorderMask);
else
    numBoards = 1;
    directBorderMask{1} = directBorderMask;
end
% hullOverlapThresh = 0.8;
strelSize = 5;
minCornerStep = 0.01;
minCornerMetric = 0.15;   % algorithm default
maxDetectAttempts = 10;
minCheckerboardFract = prod(anticipatedBoardSize-2)/prod(anticipatedBoardSize) - 0.05;%0.25;
% assuming all checks are the same size, the ratio of the area of the
% detected board (which excludes the outer checks)

% gradientThresh = 0.1;
h = size(img{1},1);
w = size(img{1},2);
foundValidPoints = false(numBoards, num_img);
directBoardPoints = NaN(prod(anticipatedBoardSize-1), 2, numBoards, num_img);

for iImg = 1 : num_img
    
    if isa(img{iImg},'uint8')
        img{iImg} = double(img{iImg}) / 255;
    end
    im_eq = adapthisteq(rgb2gray(img{iImg}));
    im_hsv = rgb2hsv(img{iImg});
    hsv_eq = im_hsv;
    hsv_eq(:,:,3) = im_eq;
    rgb_eq = hsv2rgb(hsv_eq);
    
    for iBoard = 1 : numBoards

        initBoardMask = imfill(directBorderMask{iImg}(:,:,iBoard),'holes') & ~directBorderMask{iImg}(:,:,iBoard);
        curBoardMask = imfill(initBoardMask | initDirBorderMask(:,:,iBoard,iImg),'holes');
        curBoardMask = curBoardMask & ~initDirBorderMask(:,:,iBoard,iImg);
        curBoardMask = imclose(curBoardMask,strel('disk',strelSize));
        curBoardMask = imopen(curBoardMask,strel('disk',strelSize));
        
        curBoardMask = imerode(curBoardMask,strel('disk',5));

        numBoardMaskPixels = sum(curBoardMask(:));

%         curBoardImg = img{iImg} .* repmat(uint8(curBoardMask),1,1,3);
        curBoardImg = rgb_eq .* repmat(double(curBoardMask),1,1,3);

        numCheckDetectAttempts = 0;
        while ~foundValidPoints(iBoard,iImg) && (numCheckDetectAttempts <= maxDetectAttempts)
    %         [boardPoints,boardSize] = detectCheckerboardPoints(curBoardImg,...
    %             'mincornermetric',minCornerMetric);
            [boardPoints,boardSize] = detectCheckerboardPoints(curBoardImg,'mincornermetric',minCornerMetric);

            figure(4)
            imshow(img{iImg});
            hold on
            if ~isempty(boardPoints)
                scatter(boardPoints(:,1),boardPoints(:,2));
            end

            % check that these are valid image points
            % first, does boardSize match anticipatedBoardSize?
            if ~(all(anticipatedBoardSize == boardSize) || ...
                 all(anticipatedBoardSize == fliplr(boardSize)))
                % anticipatedBoardSize does NOT match boardSize

                % adjust so the algorithm is more or less sensitive as needed            
                if prod(boardSize) > prod(anticipatedBoardSize)
                    % detected too many points
                    minCornerMetric = minCornerMetric - minCornerStep;
                else
                    minCornerMetric = minCornerMetric + minCornerStep;
                end
                numCheckDetectAttempts = numCheckDetectAttempts + 1;
                continue;
            end

            % boardSize matches anticipatedBoardSize, so now figure out if
            % they're appropriately spaced/in about the right position relative
            % to the borders

            % find the convex hull of the identified checkerboard points
            cvHull = convhull(boardPoints(:,1),boardPoints(:,2));
            hullMask = poly2mask(boardPoints(cvHull,1),boardPoints(cvHull,2),h,w);

            % check that hullMask is contained entirely within curBoardMask
            testMask = curBoardMask & ~hullMask;
            testStat = regionprops(testMask,'eulernumber');

            % euler number should be 0, but could be > 0 if there's a
            % second tiny hole (noise) in the hull
            if testStat.EulerNumber > 0
                minCornerMetric = minCornerMetric - minCornerStep;
                numCheckDetectAttempts = numCheckDetectAttempts + 1;
                continue;
            end

            hullSize = sum(hullMask(:));

    %         smoothedHull = imclose(hullMask,strel('disk',strelSize));
    %         smoothedHull = imopen(smoothedHull,strel('disk',strelSize));
            % now check to see if the convex hull of the checkerboard points is
            % more or less evenly spaced from the inner edge of the border
    %         thickenedHull = thickenToEdge(smoothedHull, curBoardMask);

            % "thickenedHull" should closely match with curBoardMask if the
            % convex hull of checkerboard points is evenly spaced from the
            % inner edge of the border
    %         testMask = thickenedHull & curBoardMask;
    %         numOverlapPoints = sum(testMask(:));

            testRatio = hullSize / numBoardMaskPixels;

            if testRatio < minCheckerboardFract
                % try increasing mincornermetric - too many false positives?
                minCornerMetric = minCornerMetric + minCornerStep;
                numCheckDetectAttempts = numCheckDetectAttempts + 1;
                continue;
            end

            foundValidPoints(iBoard,iImg) = true;

        end

        if foundValidPoints(iBoard,iImg)
            directBoardPoints(:,:,iBoard,iImg) = boardPoints;
        end
    end

end

end

