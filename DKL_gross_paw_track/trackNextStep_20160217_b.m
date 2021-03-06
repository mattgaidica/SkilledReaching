function [fullMask,bbox] = trackNextStep_20160217( image_ud, BGimg_ud, prevMasks, boxRegions, fundMat, pawPref, varargin)

h = size(image_ud,1); w = size(image_ud,2);

maxFrontPanelSep = 20;
maxDistPerFrame = 20;
threshFrameExpansion = 30;

stretchTol = [0.0 1.0];
foregroundThresh = 45/255;

frontPanelMask = boxRegions.frontPanelMask;
intMask = boxRegions.intMask;
% extMask = boxRegions.extMask;
shelfMask = boxRegions.shelfMask;
belowShelfMask = boxRegions.belowShelfMask;
floorMask = boxRegions.floorMask;

boxFrontThick = 20;
maskDilate = 15;

full_bbox = [1 1 w-1 h-1];
full_bbox(2,:) = full_bbox;

% blob parameters for tight thresholding
restrictiveBlob = vision.BlobAnalysis;
restrictiveBlob.AreaOutputPort = true;
restrictiveBlob.CentroidOutputPort = true;
restrictiveBlob.BoundingBoxOutputPort = true;
restrictiveBlob.LabelMatrixOutputPort = true;
restrictiveBlob.MinimumBlobArea = 5;
restrictiveBlob.MaximumBlobArea = 10000;

for iarg = 1 : 2 : nargin - 6
    switch lower(varargin{iarg})
%         case 'pawgraylevels',
%             pawGrayLevels = varargin{iarg + 1};
%         case 'pixelcountthreshold',
%             pixCountThresh = varargin{iarg + 1};
        case 'foregroundthresh',
            foregroundThresh = varargin{iarg + 1};
        case 'pawhsvrange',
            pawHSVrange = varargin{iarg + 1};
%         case 'maxredgreendist',
%             maxRedGreenDist = varargin{iarg + 1};
%         case 'minrgdiff',
%             minRGDiff = varargin{iarg + 1};
        case 'resblob',
            restrictiveBlob = varargin{iarg + 1};
        case 'stretchtol',
            stretchTol = varargin{iarg + 1};
        case 'boxfrontthick',
            boxFrontThick = varargin{iarg + 1};
        case 'maxdistperframe',
            maxDistPerFrame = varargin{iarg + 1};
    end
end

bbox = zeros(2,4);
prevMask_dilate = cell(1,2);
for iView = 1 : 2
    prevMask_dilate{iView} = imdilate(prevMasks{iView},strel('disk',maxDistPerFrame));
    s = regionprops(prevMask_dilate{iView},'boundingbox');
    bbox(iView,:) = round(s.BoundingBox);
end

bbox(:,1) = bbox(:,1) - threshFrameExpansion/2;
bbox(:,2) = bbox(:,2) - threshFrameExpansion/2;
bbox(:,3) = bbox(:,3) + threshFrameExpansion;
bbox(:,4) = bbox(:,4) + threshFrameExpansion;

% if any of the previous mask is on the interior side of the front
% panel, don't add the width of the front panel to the search window
overlap_mask = prevMask_dilate{2} & frontPanelMask;
if any(overlap_mask(:))
    if strcmpi(pawPref,'right')
        bbox(2,3) = bbox(2,3) + boxFrontThick;
    else
        bbox(2,1) = bbox(2,1) + boxFrontThick;
        bbox(2,3) = bbox(2,3) - boxFrontThick;
    end
end
bbox(bbox<=0) = 1;

BGdiff = imabsdiff(image_ud, BGimg_ud);

im_masked = false(h,w);
for iChannel = 1 : 3
    im_masked = im_masked | (BGdiff(:,:,iChannel) > foregroundThresh);
end
orig_im_mask = im_masked;
im_masked = processMask(orig_im_mask, 2);

fullMask = cell(1,2);
greenMask = cell(1,2);
imView = cell(1,2);
decorr_fg = cell(1,2);
decorr_hsv = cell(1,2);
viewMask = cell(1,2);
lib_greenMask = cell(1,2);
res_greenMask{iView} = cell(1,2);

projMask = true(h,w);
projMask_dilate = cell(1,2);
for iView = 2:-1:1
	im_masked = projMask & im_masked;
    
    if iView == 2
        temp = prevMask_dilate{2} & frontPanelMask;
        if any(temp(:))   % make sure to look both in front of and behind the front panel if the previous blob was near it
            panelMaskEdge = imdilate(frontPanelMask, strel('disk',maxFrontPanelSep));
            projMask_dilate{iView} = projMaskFromTangentLines(prevMask_dilate{1}, fundMat, [1 1 w-1 h-1], [h,w]);
            prevMask_dilate{2} = (prevMask_dilate{2} | panelMaskEdge) & projMask_dilate{iView};
        end
    end
    if iView == 1
        temp = prevMask_dilate{1} & shelfMask;
        temp2 = intMask & fullMask{2};
        if any(temp(:)) && any(temp2(:))  % make sure to look both above and below the shelf if the previous blob was near it
            shelfEdge = imdilate(shelfMask, strel('disk',maxFrontPanelSep));
            projMask_dilate{iView} = projMaskFromTangentLines(prevMask_dilate{2}, fundMat', [1 1 w-1 h-1], [h,w]);
            prevMask_dilate{1} = (prevMask_dilate{1} | shelfEdge) & projMask_dilate{iView};
        end
    end
    
    im_masked = im_masked & (prevMask_dilate{1} | prevMask_dilate{2});
    temp = im_masked & projMask;
    viewMask{iView} = temp(bbox(iView,2):bbox(iView,2) + bbox(iView,4),...
                                bbox(iView,1):bbox(iView,1) + bbox(iView,3));
    imView{iView} = image_ud(bbox(iView,2):bbox(iView,2) + bbox(iView,4),...
                             bbox(iView,1):bbox(iView,1) + bbox(iView,3),:);
    decorr_fg{iView} = decorrstretch(imView{iView},'tol',stretchTol);
    decorr_hsv{iView} = rgb2hsv(decorr_fg{iView});
    lib_greenMask{iView} = HSVthreshold(decorr_hsv{iView}, pawHSVrange(3,:));
    res_greenMask{iView} = HSVthreshold(decorr_hsv{iView}, pawHSVrange(1,:));
    
    if iView == 2
        % look just behind the front panel for green pixels
        temp = imdilate(frontPanelMask,strel('disk',maxFrontPanelSep));
        temp = temp & intMask;
        res_behindPanelMask = HSVthreshold(decorr_hsv{iView}, pawHSVrange(2,:));
        if isempty(projMask_dilate{iView})
            projMask_dilate{iView} = true(size(temp));
        end
        behindPanelMask = temp & projMask_dilate{iView};
        behindPanelMask = behindPanelMask(bbox(iView,2):bbox(iView,2) + bbox(iView,4),...
                                          bbox(iView,1):bbox(iView,1) + bbox(iView,3));
        res_behindPanelMask = res_behindPanelMask & behindPanelMask;
        viewMask{iView} = viewMask{iView} | behindPanelMask;
        res_greenMask{iView} = res_greenMask{iView} | res_behindPanelMask;
%         res_greenMask{iView} = res_greenMask{iView} | (lib_greenMask{iView} & behindPanelMask);
    end
        
    temp = processMask(lib_greenMask{iView},2);
    res_greenMask{iView} = imerode(res_greenMask{iView},strel('disk',1));
    greenMask{iView} = imreconstruct(res_greenMask{iView}, temp);

    mask = greenMask{iView} & viewMask{iView};    % allow green area to extend outside background diff mask, but only if they overlap
    mask = imreconstruct(mask,greenMask{iView});

    mask = processMask(mask, 2);
    fullMask{iView} = false(h,w);
    fullMask{iView}(bbox(iView,2):bbox(iView,2) + bbox(iView,4),...
                    bbox(iView,1):bbox(iView,1) + bbox(iView,3)) = mask;
   
    if iView == 2 && any(fullMask{2}(:))
        projMask = projMaskFromTangentLines(fullMask{2}, fundMat, [1 1 w-1 h-1], [h,w]);
    end
    fullMask{iView} = bwconvhull(fullMask{iView},'union');
end
        
% get rid of any blobs so far out of range that the projections from
% either view don't intersect them. But, include parts of the mask that
% are outside the projection.
proj_overlap = cell(1,2);
for iView = 1 : 2
    if any(fullMask{iView})
        projMask = projMaskFromTangentLines(fullMask{iView}, fundMat, [1 1 w-1 h-1], [h,w]);
        proj_overlap{iView} = (fullMask{3-iView} & projMask);
    else
        proj_overlap{iView} = fullMask{3-iView};
    end
end

for iView = 1 : 2
    fullMask{iView} = imreconstruct(proj_overlap{3-iView},fullMask{iView});
end

fullMask = estimateHiddenSilhouette(fullMask,full_bbox,fundMat,[h,w]);

% eliminate the floor
fullMask{1} = fullMask{1} & ~floorMask;
direct_projMask = projMaskFromTangentLines(fullMask{1}, fundMat, [1 1 w-1 h-1], [h,w]);
fullMask{2} = fullMask{2} & direct_projMask;