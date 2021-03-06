function trackGreenPaw(video, BGimg_ud, sr_ratInfo, session_mp, triggerTime, initPawMask, boxCalibration, varargin)

h = video.Height;
w = video.Width;

maxFrontPanelSep = 20;
maxRedGreenDist = 20;
minRGDiff = 0.0;

decorrStretchMean = [0.5 0.5 0.5];
decorrStretchStd  = [0.25 0.25 0.25];

pawHSVrange = [0.33, 0.16, 0.6, 1.0, 0.6, 1.0   % pick out anything that's green and bright
               0.00, 0.16, 0.8, 1.0, 0.8, 1.0     % pick out only red and bright
               0.33, 0.16, 0.6, 1.0, 0.0, 1.0]; % pick out anything green (only to be used just behind the front panel in the mirror view

foregroundThresh = 25/255;

% blob parameters for direct view
pawBlob{1} = vision.BlobAnalysis;
pawBlob{1}.AreaOutputPort = true;
pawBlob{1}.CentroidOutputPort = true;
pawBlob{1}.BoundingBoxOutputPort = true;
pawBlob{1}.LabelMatrixOutputPort = true;
pawBlob{1}.MinimumBlobArea = 100;
pawBlob{1}.MaximumBlobArea = 10000;

% blob parameters for mirror view
pawBlob{2} = vision.BlobAnalysis;
pawBlob{2}.AreaOutputPort = true;
pawBlob{2}.CentroidOutputPort = true;
pawBlob{2}.BoundingBoxOutputPort = true;
pawBlob{2}.LabelMatrixOutputPort = true;
pawBlob{2}.MinimumBlobArea = 100;
pawBlob{2}.MaximumBlobArea = 10000;

% blob parameters for tight thresholding
restrictiveBlob = vision.BlobAnalysis;
restrictiveBlob.AreaOutputPort = true;
restrictiveBlob.CentroidOutputPort = true;
restrictiveBlob.BoundingBoxOutputPort = true;
% restrictiveBlob.ExtentOutputPort = true;
restrictiveBlob.LabelMatrixOutputPort = true;
restrictiveBlob.MinimumBlobArea = 5;
restrictiveBlob.MaximumBlobArea = 10000;

for iarg = 1 : 2 : nargin - 7
    switch lower(varargin{iarg})
        case 'pawgraylevels',
            pawGrayLevels = varargin{iarg + 1};
        case 'pixelcountthreshold',
            pixCountThresh = varargin{iarg + 1};
        case 'foregroundthresh',
            foregroundThresh = varargin{iarg + 1};
    end
end

if strcmpi(class(BGimg_ud),'uint8')
    BGimg_ud = double(BGimg_ud) / 255;
end

pawPref = lower(sr_ratInfo.pawPref);
if iscell(pawPref)
    pawPref = pawPref{1};
end

vidName = fullfile(video.Path, video.Name);
video = VideoReader(vidName);
video.CurrentTime = triggerTime;

srCal = boxCalibration.srCal;

switch pawPref
    case 'left',
        fundMat = srCal.F(:,:,2);
        P2 = srCal.P(:,:,2);
        boxFrontThick = -20;
    case 'right',
        fundMat = srCal.F(:,:,1);
        P2 = srCal.P(:,:,1);
        boxFrontThick = 20;
end
cameraParams = boxCalibration.cameraParams;

boxRegions = boxRegionsfromMatchedPoints(session_mp, [h,w]);

% edge_pts_fwd = trackGreenPaw_forward( video, BGimg_ud, fundMat, cameraParams, initPawMask,pawBlob, boxFrontThick, boxRegions, pawPref, ...
%                                      'foregroundthresh',foregroundThresh,...
%                                      'pawhsvrange',pawHSVrange,...
%                                      'maxredgreendist',maxRedGreenDist,...
%                                      'minrgdiff',minRGDiff);
% video.CurrentTime = triggerTime;
% image = readFrame(video);
% image_ud = undistortImage(image, cameraParams);
% figure(3)
% set(gcf,'name','start undistorted image');
% imshow(image_ud);
video.CurrentTime = triggerTime;
[points3d,points2d] = trackGreenPaw_reverse( video, BGimg_ud, fundMat, cameraParams, initPawMask,pawBlob, boxFrontThick, boxRegions, pawPref, P2, ...
                                     'foregroundthresh',foregroundThresh,...
                                     'pawhsvrange',pawHSVrange,...
                                     'maxredgreendist',maxRedGreenDist,...
                                     'minrgdiff',minRGDiff);
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [edge_pts] = trackGreenPaw_forward( video, ...
                                             BGimg_ud, ...
                                             fundMat, ...
                                             cameraParams, ...
                                             fullMask, ...
                                             pawBlob, ...
                                             boxFrontThick, ...
                                             boxRegions, ...
                                             pawPref, ...
                                             varargin)

frontPanelMask = boxRegions.frontPanelMask;
intMask = boxRegions.intMask;
extMask = boxRegions.extMask;
shelfMask = boxRegions.shelfMask;
belowShelfMask = boxRegions.belowShelfMask;

numFrames = floor((video.Duration - video.CurrentTime) * video.FrameRate);
edge_pts = cell(numFrames,2);

h = video.Height;
w = video.Width;

maxFrontPanelSep = 20;
maxRedGreenDist = 10;

maxDistPerFrame = 50;
% decorrStretchMean = [0.5 0.5 0.5];
% decorrStretchStd  = [0.25 0.25 0.25];
stretchTol = [0.0 1.0];
foregroundThresh = 45/255;

% blob parameters for tight thresholding
restrictiveBlob = vision.BlobAnalysis;
restrictiveBlob.AreaOutputPort = true;
restrictiveBlob.CentroidOutputPort = true;
restrictiveBlob.BoundingBoxOutputPort = true;
% restrictiveBlob.ExtentOutputPort = true;
restrictiveBlob.LabelMatrixOutputPort = true;
restrictiveBlob.MinimumBlobArea = 5;
restrictiveBlob.MaximumBlobArea = 10000;

% pawHSVrange = [0.33, 0.10, 0.9, 1.0, 0.9, 1.0
%                0.2, 0.3, 0.7, 1.0, 0.6, 1.0];

for iarg = 1 : 2 : nargin - 9
    switch lower(varargin{iarg})
        case 'pawgraylevels',
            pawGrayLevels = varargin{iarg + 1};
        case 'pixelcountthreshold',
            pixCountThresh = varargin{iarg + 1};
        case 'foregroundthresh',
            foregroundThresh = varargin{iarg + 1};
        case 'pawhsvrange',
            pawHSVrange = varargin{iarg + 1};
        case 'maxredgreendist',
            maxRedGreenDist = varargin{iarg + 1};
        case 'minrgdiff',
            minRGDiff = varargin{iarg + 1};
    end
end

prev_bbox = zeros(2,4);
for iView = 1 : 2
    s = regionprops(fullMask{iView},'boundingbox');
    prev_bbox(iView,:) = round(s.BoundingBox);
end

frameCount = 0;
points3d = cell(1,numFrames);
while video.CurrentTime < video.Duration
    frameCount = frameCount + 1;
    image = readFrame(video);
    image_ud = undistortImage(image, cameraParams);
    image_ud = double(image_ud) / 255;
    
    bbox = prev_bbox;
    bbox(:,1) = bbox(:,1) - maxDistPerFrame/2;
    bbox(:,2) = bbox(:,2) - maxDistPerFrame/2;
    bbox(:,3) = bbox(:,3) + maxDistPerFrame;
    bbox(:,4) = bbox(:,4) + maxDistPerFrame;
    if boxFrontThick > 0
        bbox(2,3) = bbox(2,3) + boxFrontThick;
    else
        bbox(2,1) = bbox(2,1) + boxFrontThick;
        bbox(2,3) = bbox(2,3) - boxFrontThick;
    end
    
    BGdiff = imabsdiff(image_ud, BGimg_ud);
%     im_decorr = decorrstretch(image_ud,'targetmean',decorrStretchMean,'targetsigma',decorrStretchStd);
%     im_decorr = decorrstretch(image_ud,'tol',stretchTol);

%     im_hsv = rgb2hsv(im_decorr);
%     im_thresh = HSVthreshold(im_hsv, pawHSVrange(1,:));
    im_masked = false(h,w);
    for iChannel = 1 : 3
        im_masked = im_masked | (BGdiff(:,:,iChannel) > foregroundThresh);
    end
    
    rgDiffMap = abs(image_ud(:,:,2) - image_ud(:,:,1));
    rgMask = rgDiffMap < minRGDiff;
    
    fullMask = cell(1,2);
    redMask = cell(1,2);
    greenMask = cell(1,2);
    any_greenMask = cell(1,2);
    imView = cell(1,2);
    decorr_fg = cell(1,2);
    decorr_hsv = cell(1,2);
    
    projMask = true(h,w);
    for iView = 2:-1:1
        viewMask = im_masked(bbox(iView,2):bbox(iView,2) + bbox(iView,4),...
                             bbox(iView,1):bbox(iView,1) + bbox(iView,3));
        rgViewMask = rgMask(bbox(iView,2):bbox(iView,2) + bbox(iView,4),...
                            bbox(iView,1):bbox(iView,1) + bbox(iView,3));
        
        imView{iView} = image_ud(bbox(iView,2):bbox(iView,2) + bbox(iView,4),...
                          bbox(iView,1):bbox(iView,1) + bbox(iView,3),:);
        decorr_fg{iView} = decorrstretch(imView{iView},'tol',stretchTol);
        decorr_hsv{iView} = rgb2hsv(decorr_fg{iView});
        
        if iView == 2    % check to see if there's any green on the other side of the front panel
            frontPanelView = frontPanelMask(bbox(iView,2):bbox(iView,2) + bbox(iView,4),...
                                            bbox(iView,1):bbox(iView,1) + bbox(iView,3));
            if any(frontPanelView(:))
                [fp_y,fp_x] = find(frontPanelView);
                behindPanelRegion = false(size(frontPanelView));
                beforePanelRegion = false(size(frontPanelView));
                switch pawPref
                    case 'left',
                        for iRow = 1 : size(frontPanelView,1)
                            rowIdx = find(fp_y == iRow);
                            min_x = min(fp_x(rowIdx));
                            max_x = max(fp_x(rowIdx));
                            behindPanelRegion(iRow,1:min_x) = true;
                            beforePanelRegion(iRow,max_x:end) = true;
                        end
                    case 'right',
                        for iRow = 1 : size(frontPanelView,1)
                            rowIdx = find(fp_y == iRow);
                            max_x = max(fp_x(rowIdx));
                            min_x = min(fp_x(rowIdx));
                            behindPanelRegion(iRow,max_x:end) = true;
                            beforePanelRegion(iRow,1:min_x) = true;
                        end
                end
%                 hsvView = im_hsv(bbox(iView,2):bbox(iView,2) + bbox(iView,4),...
%                                  bbox(iView,1):bbox(iView,1) + bbox(iView,3),:);
                viewMask = viewMask | behindPanelRegion;
%                 behindPanelMask = behindPanelRegion & HSVthreshold(decorr_hsv,pawHSVrange(3,:));
%                 mask = (mask | behindPanelMask);
                behindPanel_hsv = decorr_hsv{iView} .* repmat(double(behindPanelRegion),1,1,3);
                any_greenMask{iView} = HSVthreshold(behindPanel_hsv, pawHSVrange(3,:));
                
                % keep only objects close to the front panel
%                 frontPanelDilate = imdilate(frontPanelView,strel('square',maxFrontPanelSep));
%                 overlap_mask = frontPanelDilate & any_greenMask{iView};
%                 any_greenMask{iView} = imreconstruct(overlap_mask, any_greenMask{iView});
            end
        else
            any_greenMask{iView} = false(size(viewMask));
        end
        
        decorr_hsv{iView} = decorr_hsv{iView} .* repmat(double(viewMask),1,1,3);
        
        greenMask{iView} = HSVthreshold(decorr_hsv{iView}, pawHSVrange(1,:)) | any_greenMask{iView};
        redMask{iView} = HSVthreshold(decorr_hsv{iView}, pawHSVrange(2,:));

        [~,~,~,greenLabMat] = step(restrictiveBlob,greenMask{iView});
        greenMask{iView} = (greenLabMat > 0);
        [~,~,~,redLabMat] = step(restrictiveBlob,redMask{iView});
        redMask{iView} = (redLabMat > 0);
        
        overlap_mask = imdilate(greenMask{iView},strel('square',maxRedGreenDist)) & ...
                       redMask{iView};
        redMask{iView} = imreconstruct(overlap_mask, redMask{iView});
        
        tempMask = (greenMask{iView} | redMask{iView}) & ~rgViewMask;
        mask = processMask(tempMask, 2);
        
        fullMask{iView} = false(h,w);
        fullMask{iView}(bbox(iView,2):bbox(iView,2) + bbox(iView,4),...
                        bbox(iView,1):bbox(iView,1) + bbox(iView,3)) = mask;
                                        
    end
    
    % remaining blob projections have to overlap with something in the other view
    for iView = 1 : 2
        L = bwlabel(fullMask{iView});
        fullMask{iView} = false(size(fullMask{iView}));
        for iBlob = 1 : max(L(:))
            projMask = projMaskFromTangentLines((L==iBlob), fundMat, [1 1 w-1 h-1], [h,w]);
            overlapMask = projMask & fullMask{3-iView};
            if any(overlapMask(:))
                fullMask{iView} = (fullMask{iView} | (L==iBlob));
            end
        end
        fullMask{iView} = multiRegionConvexHullMask(fullMask{iView});
    end
            
    mirror_projMask = projMaskFromTangentLines(fullMask{2}, fundMat, [1 1 w-1 h-1], [h,w]);
    direct_projMask = projMaskFromTangentLines(fullMask{1}, fundMat, [1 1 w-1 h-1], [h,w]);

    mirror_proj_overlap = (fullMask{2} & direct_projMask);
    direct_proj_overlap = (fullMask{1} & mirror_projMask);

    fullMask{1} = imreconstruct(direct_proj_overlap, fullMask{1});
    fullMask{2} = imreconstruct(mirror_proj_overlap, fullMask{2});
    
    for iView = 1 : 2
        mask_outline = bwmorph(fullMask{iView},'remove');
        [y,x] = find(mask_outline);
        edge_pts{frameCount,iView} = [x,y];
    end
    
    figure(1);
    imshow(image_ud);
    hold on
    rectangle('position',bbox(1,:));
    rectangle('position',bbox(2,:));
    plot(edge_pts{frameCount,1}(:,1),edge_pts{frameCount,1}(:,2),'marker','.','linestyle','none')
    plot(edge_pts{frameCount,2}(:,1),edge_pts{frameCount,2}(:,2),'marker','.','linestyle','none')
    
%     figure(2);
%     imshow(fullMask{1} | fullMask{2})
    
    for iView = 1 : 2
        s = regionprops(fullMask{iView},'boundingbox');
        prev_bbox(iView,:) = round(s.BoundingBox);
    end

end

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [points3d,points2d] = trackGreenPaw_reverse( video, ...
                                             BGimg_ud, ...
                                             fundMat, ...
                                             cameraParams, ...
                                             fullMask, ...
                                             pawBlob, ...
                                             boxFrontThick, ...
                                             boxRegions, ...
                                             pawPref, ...
                                             P2,...
                                             varargin)

K = cameraParams.IntrinsicMatrix;

frontPanelMask = boxRegions.frontPanelMask;
intMask = boxRegions.intMask;
extMask = boxRegions.extMask;
shelfMask = boxRegions.shelfMask;
belowShelfMask = boxRegions.belowShelfMask;

numFrames = floor((video.CurrentTime) * video.FrameRate);

video.CurrentTime = video.CurrentTime + 1/video.FrameRate;

h = video.Height;
w = video.Width;
full_bbox = [1 1 w-1 h-1];
full_bbox(2,:) = full_bbox;

maxFrontPanelSep = 20;

maxDistPerFrame = 30;
% decorrStretchMean = [0.5 0.5 0.5];
% decorrStretchStd  = [0.25 0.25 0.25];
stretchTol = [0.0 1.0];
foregroundThresh = 45/255;

% blob parameters for tight thresholding
restrictiveBlob = vision.BlobAnalysis;
restrictiveBlob.AreaOutputPort = true;
restrictiveBlob.CentroidOutputPort = true;
restrictiveBlob.BoundingBoxOutputPort = true;
% restrictiveBlob.ExtentOutputPort = true;
restrictiveBlob.LabelMatrixOutputPort = true;
restrictiveBlob.MinimumBlobArea = 5;
restrictiveBlob.MaximumBlobArea = 10000;

% pawHSVrange = [0.33, 0.10, 0.9, 1.0, 0.9, 1.0
%                0.2, 0.3, 0.7, 1.0, 0.6, 1.0];

for iarg = 1 : 2 : nargin - 10
    switch lower(varargin{iarg})
        case 'pawgraylevels',
            pawGrayLevels = varargin{iarg + 1};
        case 'pixelcountthreshold',
            pixCountThresh = varargin{iarg + 1};
        case 'foregroundthresh',
            foregroundThresh = varargin{iarg + 1};
        case 'pawhsvrange',
            pawHSVrange = varargin{iarg + 1};
        case 'maxredgreendist',
            maxRedGreenDist = varargin{iarg + 1};
        case 'minrgdiff',
            minRGDiff = varargin{iarg + 1};
        case 'maxdistperframe',
            maxDistPerFrame = varargin{iarg + 1};
    end
end

orig_maxDistPerFrame = maxDistPerFrame;
frameCount = 1;

points3d = cell(1,numFrames);
points2d = cell(1,numFrames);
matched_points = matchMirrorMaskPoints(fullMask, fundMat);
points2d{frameCount} = matched_points;
% convert matched points to normalized coordinates
mp_norm = zeros(size(matched_points));
for iView = 1 : 2
    mp_norm(:,:,iView) = normalize_points(squeeze(matched_points(:,:,iView)), K);
end
[points3d{frameCount},~,~] = triangulate_DL(mp_norm(:,:,1),mp_norm(:,:,2),eye(4,3),P2);
center3d = zeros(numFrames,3);
center3d(frameCount,:) = mean(points3d{frameCount},1);

prev_image = readFrame(video);
prev_image_ud = undistortImage(prev_image, cameraParams);
prev_image_ud = double(prev_image_ud) / 255;

while video.CurrentTime < video.Duration
    video.CurrentTime = video.CurrentTime - 2/video.FrameRate;
    frameCount = frameCount + 1
    image = readFrame(video);
    image_ud = undistortImage(image, cameraParams);
    image_ud = double(image_ud) / 255;
    
    prevMask = fullMask;
    [fullMask,bbox] = trackNextStep(image_ud,BGimg_ud,fullMask,boxRegions,fundMat,pawPref,...
                             'foregroundthresh',foregroundThresh,...
                             'pawhsvrange',pawHSVrange,...
                             'maxredgreendist',maxRedGreenDist,...
                             'minrgdiff',minRGDiff,...
                             'resblob',restrictiveBlob,...
                             'stretchtol',stretchTol,...
                             'boxfrontthick',boxFrontThick,...
                             'maxdistperframe',maxDistPerFrame);
                       
	maxDistPerFrame = orig_maxDistPerFrame;
	% if the mask isn't visible in either view, start with the 3d points
	% from the previous n frames, and predict where the paw should be.
	% Then, project it into the missing view
    if ~any(fullMask{1}(:)) || ~any(fullMask{2}(:))
        if ~any(fullMask{1}(:)) && any(fullMask{2}(:))
            % object visible in side view but not direct view
            visibleView = 2;
            F = fundMat';
            hiddenView = 3 - visibleView;
            projMask = projMaskFromTangentLines(fullMask{visibleView},F, [1 1 w-1 h-1], [h,w]);
            fullMask{hiddenView} = projMask & prevMask{hiddenView};
            fullMask = estimateHiddenSilhouette(fullMask,full_bbox,fundMat,[h,w]);
            
            temp = bwconvhull(fullMask{visibleView});
            temp_ext = bwmorph(temp,'remove');
            [y,x] = find(temp_ext);
            points2d{frameCount} = NaN(length(y),2,2);
            points2d{frameCount}(:,1,visibleView) = x;
            points2d{frameCount}(:,2,visibleView) = y;
        elseif any(fullMask{1}(:)) && ~any(fullMask{2}(:))
            % object visible in direct view but not mirror view
            visibleView = 1;
            F = fundMat';
            hiddenView = 3 - visibleView;
            projMask = projMaskFromTangentLines(fullMask{visibleView},F, [1 1 w-1 h-1], [h,w]);
            fullMask{hiddenView} = projMask & prevMask{hiddenView};
            fullMask = estimateHiddenSilhouette(fullMask,full_bbox,fundMat,[h,w]);
            
            temp = bwconvhull(fullMask{visibleView});
            temp_ext = bwmorph(temp,'remove');
            [y,x] = find(temp_ext);
            points2d{frameCount} = NaN(length(y),2,2);
            points2d{frameCount}(:,1,visibleView) = x;
            points2d{frameCount}(:,2,visibleView) = y;
        else   % not visible in either view, expand region to look in next frame
            fullMask = prevMask;
            maxDistPerFrame = 2 * maxDistPerFrame;
        end
    else
        % only calculate 3d points if visible in both views
        matched_points = matchMirrorMaskPoints(fullMask, fundMat);
        points2d{frameCount} = matched_points;
        % convert matched points to normalized coordinates
        mp_norm = zeros(size(matched_points));
        for iView = 1 : 2
            mp_norm(:,:,iView) = normalize_points(squeeze(matched_points(:,:,iView)), K);
        end
        [points3d{frameCount},~,~] = triangulate_DL(mp_norm(:,:,1),mp_norm(:,:,2),eye(4,3),P2);
        center3d(frameCount,:) = mean(points3d{frameCount},1);
        
    end
                             
%     
%     orig_image_ud = image_ud;
%     image_ud = color_adapthisteq(orig_image_ud);
%     imhsv = rgb2hsv(image_ud);
%     imhsv(:,:,3) = adapthisteq(imhsv(:,:,3));
%     image_ud = hsv2rgb(imhsv);
    
%     bbox = prev_bbox;
%     bbox(:,1) = bbox(:,1) - maxDistPerFrame/2;
%     bbox(:,2) = bbox(:,2) - maxDistPerFrame/2;
%     bbox(:,3) = bbox(:,3) + maxDistPerFrame;
%     bbox(:,4) = bbox(:,4) + maxDistPerFrame;
%     
%     % if any of the previous mask is on the interior side of the front
%     % panel, don't add the width of the front panel to the search window
%     overlap_mask = fullMask{2} & intMask;
%     if ~any(overlap_mask(:))
%         if boxFrontThick > 0
%             bbox(2,3) = bbox(2,3) + boxFrontThick;
%         else
%             bbox(2,1) = bbox(2,1) + boxFrontThick;
%             bbox(2,3) = bbox(2,3) - boxFrontThick;
%         end
%     end
%     
%     BGdiff = imabsdiff(image_ud, BGimg_ud);
%     orig_image_ud = image_ud;
%     image_ud = color_adapthisteq(orig_image_ud);
% 
% %     im_decorr = decorrstretch(image_ud,'targetmean',decorrStretchMean,'targetsigma',decorrStretchStd);
%     im_decorr = decorrstretch(image_ud,'tol',stretchTol);
% 
% %     im_hsv = rgb2hsv(im_decorr);
% %     im_thresh = HSVthreshold(im_hsv, pawHSVrange(1,:));
%     im_masked = false(h,w);
%     for iChannel = 1 : 3
%         im_masked = im_masked | (BGdiff(:,:,iChannel) > foregroundThresh);
%     end
%     rgDiffMap = abs(image_ud(:,:,2) - image_ud(:,:,1));
%     rgMask = rgDiffMap < minRGDiff;
%     
%     fullMask = cell(1,2);
%     redMask = cell(1,2);
%     greenMask = cell(1,2);
%     any_greenMask = cell(1,2);
%     imView = cell(1,2);
%     decorr_fg = cell(1,2);
%     decorr_hsv = cell(1,2);
%     
%     projMask = true(h,w);
%     for iView = 2:-1:1
%         im_masked = projMask & im_masked;
%         if iView == 2    % check to see if there's any green on the other side of the front panel
%             viewMask = im_masked(bbox(iView,2):bbox(iView,2) + bbox(iView,4),...
%                                  bbox(iView,1):bbox(iView,1) + bbox(iView,3));
%             rgViewMask = rgMask(bbox(iView,2):bbox(iView,2) + bbox(iView,4),...
%                                 bbox(iView,1):bbox(iView,1) + bbox(iView,3));
% 
%             imView{iView} = image_ud(bbox(iView,2):bbox(iView,2) + bbox(iView,4),...
%                               bbox(iView,1):bbox(iView,1) + bbox(iView,3),:);
%             decorr_fg{iView} = decorrstretch(imView{iView},'tol',stretchTol);
%             decorr_hsv{iView} = rgb2hsv(decorr_fg{iView});
% 
%             frontPanelView = frontPanelMask(bbox(iView,2):bbox(iView,2) + bbox(iView,4),...
%                                             bbox(iView,1):bbox(iView,1) + bbox(iView,3));
%             behindPanelRegion = intMask(bbox(iView,2):bbox(iView,2) + bbox(iView,4),...
%                                         bbox(iView,1):bbox(iView,1) + bbox(iView,3));
%             beforePanelRegion = extMask(bbox(iView,2):bbox(iView,2) + bbox(iView,4),...
%                                         bbox(iView,1):bbox(iView,1) + bbox(iView,3));
% %             if any(frontPanelView(:))
% %                 [fp_y,fp_x] = find(frontPanelView);
%                 
% %                 behindPanelRegion = false(size(frontPanelView));
% %                 beforePanelRegion = false(size(frontPanelView));
% %                 switch pawPref
% %                     case 'left',
% %                         for iRow = 1 : size(frontPanelView,1)
% %                             rowIdx = find(fp_y == iRow);
% %                             min_x = min(fp_x(rowIdx));
% %                             max_x = max(fp_x(rowIdx));
% %                             behindPanelRegion(iRow,1:min_x) = true;
% %                             beforePanelRegion(iRow,max_x:end) = true;
% %                         end
% %                     case 'right',
% %                         for iRow = 1 : size(frontPanelView,1)
% %                             rowIdx = find(fp_y == iRow);
% %                             max_x = max(fp_x(rowIdx));
% %                             min_x = min(fp_x(rowIdx));
% %                             behindPanelRegion(iRow,max_x:end) = true;
% %                             beforePanelRegion(iRow,1:min_x) = true;
% %                         end
% %                 end
% %                 hsvView = im_hsv(bbox(iView,2):bbox(iView,2) + bbox(iView,4),...
% %                                  bbox(iView,1):bbox(iView,1) + bbox(iView,3),:);
%                 viewMask = viewMask | behindPanelRegion;
% %                 behindPanelMask = behindPanelRegion & HSVthreshold(decorr_hsv,pawHSVrange(3,:));
% %                 mask = (mask | behindPanelMask);
%                 behindPanel_hsv = decorr_hsv{iView} .* repmat(double(behindPanelRegion),1,1,3);
%                 any_greenMask{iView} = HSVthreshold(behindPanel_hsv, pawHSVrange(3,:));
%                 
%                 % keep only objects close to the front panel
% %                 frontPanelDilate = imdilate(frontPanelView,strel('square',maxFrontPanelSep));
% %                 overlap_mask = frontPanelDilate & any_greenMask{iView};
% %                 any_greenMask{iView} = imreconstruct(overlap_mask, any_greenMask{iView});
% %             else
% %                 any_greenMask{iView} = false(size(viewMask));
% %             end
%           
%         else    % direct view
%             overlap_mask = (intMask & fullMask{2});
%             if any(overlap_mask(:))    % if any of the paw is inside the box, make
%                                        % sure to check below the shelf for
%                                        % the paw (may be partially obscured
%                                        % by the shelf)
%                 projMask = projMaskFromTangentLines(fullMask{2},fundMat,[1 1 w-1 h-1],[h,w]);
%                 overlap_mask = (projMask & (belowShelfMask | shelfMask));
%                 if any(overlap_mask(:))    % part of mirror view projection overlaps the shelf and/or region below the shelf
%                                            % this means there is probably
%                                            % (certainly?) part of the paw
%                                            % obscured by the shelf, and we
%                                            % need to see if the paw is
%                                            % visible below the shelf
%                     tempMask = false(h,w);
%                     tempMask(bbox(1,2):bbox(1,2)+bbox(1,4),...
%                              bbox(1,1):bbox(1,1)+bbox(1,3)) = true;
%                     extended_bbox = [bbox(1,1),bbox(1,2),bbox(1,3),h-bbox(1,2)];   % extend direct view bounding box to the bottom of the image
%                     tempMask2 = false(h,w);
%                     tempMask2(extended_bbox(2):extended_bbox(2)+extended_bbox(4),...
%                               extended_bbox(1):extended_bbox(1)+extended_bbox(3)) = true;
%                     tempMask2 = tempMask2 & projMask;   % projection mask directly below bbox
%                     tempMask = tempMask | tempMask2;
%                     s = regionprops(tempMask,'boundingbox');
%                     bbox(1,:) = round(s.BoundingBox);
%                     bbox(1,4) = bbox(1,4) + 10;    % cushion in case mirror view was too restrictive
%                 end
%             end
%                         
%             viewMask = im_masked(bbox(iView,2):bbox(iView,2) + bbox(iView,4),...
%                                  bbox(iView,1):bbox(iView,1) + bbox(iView,3));
%             rgViewMask = rgMask(bbox(iView,2):bbox(iView,2) + bbox(iView,4),...
%                                 bbox(iView,1):bbox(iView,1) + bbox(iView,3));
% 
%             imView{iView} = image_ud(bbox(iView,2):bbox(iView,2) + bbox(iView,4),...
%                               bbox(iView,1):bbox(iView,1) + bbox(iView,3),:);
%             decorr_fg{iView} = decorrstretch(imView{iView},'tol',stretchTol);
%             decorr_hsv{iView} = rgb2hsv(decorr_fg{iView});
%             
%             belowShelfRegion = belowShelfMask(bbox(iView,2):bbox(iView,2) + bbox(iView,4),...
%                                               bbox(iView,1):bbox(iView,1) + bbox(iView,3));
% %             belowShelfRegion = belowShelfRegion & viewMask;
%             belowShelf_hsv = decorr_hsv{iView} .* repmat(double(belowShelfRegion),1,1,3);
%             any_greenMask{iView} = HSVthreshold(belowShelf_hsv, pawHSVrange(3,:));%false(bbox(1,4)+1,bbox(1,3)+1);
%         end
%         
%         decorr_hsv{iView} = decorr_hsv{iView} .* repmat(double(viewMask),1,1,3);
%         
%         greenMask{iView} = HSVthreshold(decorr_hsv{iView}, pawHSVrange(1,:)) | any_greenMask{iView};
%         redMask{iView} = HSVthreshold(decorr_hsv{iView}, pawHSVrange(2,:));
% 
%         [~,~,~,greenLabMat] = step(restrictiveBlob,greenMask{iView});
%         greenMask{iView} = (greenLabMat > 0);
%         [~,~,~,redLabMat] = step(restrictiveBlob,redMask{iView} );
%         redMask{iView} = (redLabMat > 0);
%         
%         overlap_mask = imdilate(greenMask{iView},strel('square',maxRedGreenDist)) & ...
%                        redMask{iView};
%         redMask{iView} = imreconstruct(overlap_mask, redMask{iView});
%         
%         tempMask = (greenMask{iView} | redMask{iView}) & ~rgViewMask;
%         mask = processMask(tempMask, 2);
%         fullMask{iView} = false(h,w);
%         fullMask{iView}(bbox(iView,2):bbox(iView,2) + bbox(iView,4),...
%                         bbox(iView,1):bbox(iView,1) + bbox(iView,3)) = mask;
%                   
%         projMask = false(h,w);
%         if iView == 2
%             labMat = bwlabel(fullMask{iView});
%             for ii = 1 : max(labMat(:))
%                 projMask = projMask | ...
%                     projMaskFromTangentLines((labMat==ii), fundMat, [1 1 w-1 h-1], [h,w]);
%             end
%         end
%         fullMask{iView} = bwconvhull(fullMask{iView},'union');
%     end
%     
%     % remaining blob projections have to overlap with something in the other view
% %     for iView = 1 : 2
% %         L = bwlabel(fullMask{iView});
% %         fullMask{iView} = false(size(fullMask{iView}));
% %         for iBlob = 1 : max(L(:))
% %             projMask = projMaskFromTangentLines((L==iBlob), fundMat, [1 1 w-1 h-1], [h,w]);
% %             overlapMask = projMask & fullMask{3-iView};
% %             if any(overlapMask(:))
% %                 fullMask{iView} = (fullMask{iView} | (L==iBlob));
% %             end
% %         end
% %         fullMask{iView} = multiRegionConvexHullMask(fullMask{iView});
% %     end
%             
%     % get rid of any blobs so far out of range that the projections from
%     % either view don't intersect them. But, include pats of the mask that
%     % are outside the projection.
%     mirror_projMask = projMaskFromTangentLines(fullMask{2}, fundMat, [1 1 w-1 h-1], [h,w]);
%     direct_projMask = projMaskFromTangentLines(fullMask{1}, fundMat, [1 1 w-1 h-1], [h,w]);
% 
%     mirror_proj_overlap = (fullMask{2} & direct_projMask);
%     direct_proj_overlap = (fullMask{1} & mirror_projMask);
% 
%     fullMask{1} = imreconstruct(direct_proj_overlap, fullMask{1});
%     fullMask{2} = imreconstruct(mirror_proj_overlap, fullMask{2});
% 
%     fullMask = estimateHiddenSilhouette(fullMask,full_bbox,fundMat,[h,w]);



    for iView = 1 : 2
        mask_outline = bwmorph(fullMask{iView},'remove');
        [y,x] = find(mask_outline);
        edge_pts{frameCount,iView} = [x,y];
    end
    
    figure(1);
    imshow(image_ud);
    hold on
    rectangle('position',bbox(1,:));
    rectangle('position',bbox(2,:));
    plot(edge_pts{frameCount,1}(:,1),edge_pts{frameCount,1}(:,2),'marker','.','linestyle','none')
    plot(edge_pts{frameCount,2}(:,1),edge_pts{frameCount,2}(:,2),'marker','.','linestyle','none')
    
    
%     figure(2);imshow(imabsdiff(prev_image_ud,image_ud));
    prev_image_ud = image_ud;
    
%     for iView = 1 : 2
%         s = regionprops(fullMask{iView},'boundingbox');
%         prev_bbox(iView,:) = round(s.BoundingBox);
%     end
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% function tracks = initGreenPawTracks()
%     % create an empty array of tracks
%     tracks = struct(...
%         'id', {}, ...
%         'bbox', {}, ...
%         'color', {}, ...
%         'digitmask1', {}, ...
%         'digitmask2', {}, ...
%         'digitmask3', {}, ...
%         'prevmask1', {}, ...
%         'prevmask2', {}, ...
%         'prevmask3', {}, ...
%         'meanHSV', {}, ...
%         'stdHSV', {}, ...
%         'markers3D', {}, ...
%         'prev_markers3D', {}, ...
%         'currentDigitMarkers', {}, ...
%         'previousDigitMarkers', {}, ...
%         'age', {}, ...
%         'isvisible', {}, ...
%         'markersCalculated', {}, ...
%         'totalVisibleCount', {}, ...
%         'consecutiveInvisibleCount', {});
% end