function [fullMask] = trackNextStep_mirror_relRGB_20170208( image_ud, BGimg_ud, fundMat, greenBGmask, prevMask, boxRegions, pawPref,varargin)
% function [fullMask] = trackNextStep_mirror_relRGB_PCA( image_ud, fundMat, greenBGmask, prevMask, boxRegions, pawPref,PCAcoeff,PCAmean,PCAmean_nonPaw,PCAcovar,varargin)
%
% function to segment a video frame of a rat reaching (paw painted with
% green nail polish) into paw and non-paw portions in both the mirror and
% direct views
%
% INPUTS:
%   image_ud - current undistorted video frame
%   fundMat - fundamental matrix that transforms the direct view to the
%       mirror view containing the dorsum of the paw (i.e., left mirror for
%       a right-pawed rat and vice-versa)
%   BGimg_ud - undistorted background image from this video. This is useful if
%       there are any green blobs (e.g., nail polish that rubbed off the
%       paw) on the box, so they can be ignored during paw tracking
%   prevMask - 
%   boxRegions - 
%   pawPref - 

% extract height and width of the video frame
h = size(image_ud,1); w = size(image_ud,2);
% pawThresh = 0.5;
% nonPawThresh = 0.8;
% probDiffThresh = 0.1;
grDistThresh_res = [0.6,0.99];
grDistThresh_lib = [0.5,0.7];
BGdiff_thresh = 0.015;
relBGdiff_thresh = [0.05,0.0];

min_abs_grDiff = [0.1,0.02];
min_abs_gbDiff = [0.01,0.01];
                
imDiff = imabsdiff(BGimg_ud,image_ud);
imDiffMask = imDiff(:,:,1) < BGdiff_thresh & ...
             imDiff(:,:,2) < BGdiff_thresh & ...
             imDiff(:,:,3) < BGdiff_thresh;
imDiffMask = ~imDiffMask;

min_gb_diff = [0.05,0.1];
min_gr_diff = [0.05,0.1];   % NEED TO MODIFY THRESHOLDS TO GET JUST THE GREEN CORNER OF THE PAW...

min_internal_gr_diff = 0.1;
min_internal_gb_diff = 0.08;

imFiltWidth = 5;

maxFrontPanelSep = 15;
maxDistBehindFrontPanel = 30;
maxDistPerFrame = 20;
shelfThick = 50;

% frontPanelMask = imdilate(boxRegions.frontPanelMask,strel('disk',2)); 
frontPanelMask = boxRegions.frontPanelMask;
darkThresh = [0.1,0.1];    % pixels darker than this threshold in R, G, AND B should be discarded

intMask = boxRegions.intMask;
extMask = boxRegions.extMask;
belowShelfMask = boxRegions.belowShelfMask;
shelfMask = boxRegions.shelfMask;
floorMask = boxRegions.floorMask;
slotMask = boxRegions.slotMask;

for iarg = 1 : 2 : nargin - 7
    switch lower(varargin{iarg})
        case 'maxdistperframe'
            maxDistPerFrame = varargin{iarg + 1};
    end
end

% check to see if the paw was entirely outside the box, entirely inside the
% box, or partially in both in the last frame
testOut = prevMask{2} & extMask;
if any(testOut(:))
    prev_pawOut = true;
else
    prev_pawOut = false;
end
testIn = prevMask{2} & intMask;
if any(testIn(:))
    prev_pawIn = true;
else
    prev_pawIn = false;
end
testBelow = prevMask{1} & belowShelfMask;
if any(testBelow(:))
    pawBelow = true;
else
    pawBelow = false;
end
testAbove = prevMask{1} & (~belowShelfMask & ~shelfMask);
if any(testAbove(:))
    pawAbove = true;
else
    pawAbove = false;
end

prev_bbox = zeros(2,4);
cur_ROI = cell(1,2);
prev_mask_dilate_ROI = cell(1,2);
im_relRGB = cell(1,2);
drkmsk = cell(1,2);
dilated_bbox = zeros(2,4);
BGmask_ROI = cell(1,2);
BGdiff_mask_ROI = cell(1,2);
BG_relRGBdiff = cell(1,2);
BG_ROI = cell(1,2);
relBG_ROI = cell(1,2);

% PCA_im = cell(1,2);
for ii = 2 : -1 : 1
    temp = regionprops(bwconvhull(prevMask{ii},'union'),'BoundingBox');
    prev_bbox(ii,:) = round(temp.BoundingBox);
    dilated_bbox(ii,1:2) = [max(prev_bbox(ii,1)-maxDistPerFrame, 1),...
                            max(prev_bbox(ii,2)-maxDistPerFrame, 1)];
    dilated_bbox(ii,3:4) = [min(prev_bbox(ii,3)+(2*maxDistPerFrame),w-dilated_bbox(ii,1)),...
                            min(prev_bbox(ii,4)+(2*maxDistPerFrame),h-dilated_bbox(ii,2))];
                      
% 	if ii == 1
%         dilated_bbox(ii,1) = dilated_bbox(ii,1) - 100;
%         dilated_bbox(ii,3) = dilated_bbox(ii,3) + 150;
%     end
    if ii == 2   
        
        if strcmpi(pawPref,'left')
            SE = [ones(1,maxDistBehindFrontPanel),zeros(1,maxDistBehindFrontPanel)];
        else
            SE = [zeros(1,maxDistBehindFrontPanel),ones(1,maxDistBehindFrontPanel)];
        end
        behindPanelMask = imdilate(frontPanelMask,SE) & ~frontPanelMask;
        
        prevMask_dilate = imdilate(prevMask{2},strel('disk',maxDistPerFrame));
        
        frontPanelTest = (prevMask_dilate & frontPanelMask);
        if any(frontPanelTest(:))
            if prev_pawIn == false 
                if strcmpi(pawPref,'left')
                    % extend the bounding box backward by maxFrontPanelSep
                    dilated_bbox(2,1) = max(dilated_bbox(2,1) - maxFrontPanelSep, 1);
                    dilated_bbox(2,3) = min(dilated_bbox(2,3) + maxFrontPanelSep, w-dilated_bbox(2,1));

                    % extend prevMask_dilate back by maxFrontPanelSep
                    SE = [ones(1,maxFrontPanelSep+maxDistPerFrame),zeros(1,maxFrontPanelSep+maxDistPerFrame)];

                    temp_prevMask_dilate = imdilate(prevMask{2}, SE);
                    prevMask_dilate = prevMask_dilate | temp_prevMask_dilate;
%                     prevMask_dilate = imdilate(prevMask_dilate, SE);
                else
                    % extend the bounding box forward by maxFrontPanelSep
                    dilated_bbox(2,3) = min(dilated_bbox(2,3) + maxFrontPanelSep, w-dilated_bbox(2,1));

                    % extend prevMask_dilate forward by maxFrontPanelSep
                    SE = [zeros(1,maxFrontPanelSep+maxDistPerFrame),ones(1,maxFrontPanelSep+maxDistPerFrame)];

                    temp_prevMask_dilate = imdilate(prevMask{2}, SE);
                    prevMask_dilate = prevMask_dilate | temp_prevMask_dilate;
%                     prevMask_dilate = imdilate(prevMask_dilate, SE);
                end
            end
            if prev_pawOut == false
                if strcmpi(pawPref,'left')
                    % extend the bounding box forward by maxFrontPanelSep
                    dilated_bbox(2,3) = min(dilated_bbox(2,3) + maxFrontPanelSep, w-dilated_bbox(2,1));

                    % extend prevMask_dilate forward by maxFrontPanelSep
                    SE = [zeros(1,maxFrontPanelSep+maxDistPerFrame),ones(1,maxFrontPanelSep+maxDistPerFrame)];

                    temp_prevMask_dilate = imdilate(prevMask{2}, SE);
                    prevMask_dilate = prevMask_dilate | temp_prevMask_dilate;
%                     prevMask_dilate = imdilate(prevMask_dilate, SE);
                else
                    % extend the bounding box backward by maxFrontPanelSep
                    dilated_bbox(2,1) = max(dilated_bbox(2,1) - maxFrontPanelSep, 1);
                    dilated_bbox(2,3) = min(dilated_bbox(2,3) + maxFrontPanelSep, w-dilated_bbox(2,1));

                    % extend prevMask_dilate back by maxFrontPanelSep
                    SE = [ones(1,maxFrontPanelSep+maxDistPerFrame),zeros(1,maxFrontPanelSep+maxDistPerFrame)];

                    temp_prevMask_dilate = imdilate(prevMask{2}, SE);
                    prevMask_dilate = prevMask_dilate | temp_prevMask_dilate;
%                     prevMask_dilate = imdilate(prevMask_dilate, SE);
                end
            end
        end
        behindPanelMask = prevMask_dilate & behindPanelMask;
        behindPanelMask = behindPanelMask(dilated_bbox(ii,2):dilated_bbox(ii,2)+dilated_bbox(ii,4),dilated_bbox(ii,1):dilated_bbox(ii,1)+dilated_bbox(ii,3));
    else
        prevMask_dilate = imdilate(prevMask{1},strel('disk',maxDistPerFrame));
        shelfTest = (prevMask_dilate & shelfMask);
        if any(shelfTest(:)) && (pawIn == true)  % check that part of the paw is currently inside the box on the last frame. Note this is set on the first loop iteration.
            if pawAbove == false
                % extend the bounding box up
                dilated_bbox(1,2) = max(dilated_bbox(1,2) - shelfThick, 1);
                dilated_bbox(1,4) = min(dilated_bbox(1,4) + shelfThick, h);
                
                % extend prevMask_dilate up
                SE = [ones(shelfThick,1);zeros(shelfThick,1)];
                prevMask_dilate = imdilate(prevMask_dilate, SE);
            end
            if pawBelow == false
                % extend the bounding box down
                dilated_bbox(1,4) = min(dilated_bbox(1,4) + shelfThick, h);
                
                % extend prevMask_dilate down
                SE = [zeros(shelfThick,1);ones(shelfThick,1)];
                prevMask_dilate = imdilate(prevMask_dilate, SE);
            end
        end
        if pawAbove == true
            % make sure bounding box at least includes the width of the
            % slot
            slotOutline = regionprops(imdilate(slotMask,strel('disk',5)),'boundingbox');
            slot_bbox = round(slotOutline.BoundingBox);
            bbox_right = dilated_bbox(1,1) + dilated_bbox(1,3);
            dilated_bbox(1,1) = min(dilated_bbox(1,1),slot_bbox(1));
            bbox_right = max(bbox_right, slot_bbox(1) + slot_bbox(3));
            dilated_bbox(1,3) = bbox_right - dilated_bbox(1,1);
        end    
             
    end
    

    cur_ROI{ii} = image_ud(dilated_bbox(ii,2):dilated_bbox(ii,2)+dilated_bbox(ii,4),dilated_bbox(ii,1):dilated_bbox(ii,1)+dilated_bbox(ii,3),:);
    cur_ROI{ii} = imboxfilt(cur_ROI{ii},imFiltWidth);
    BGdiff_mask_ROI{ii} = imDiffMask(dilated_bbox(ii,2):dilated_bbox(ii,2)+dilated_bbox(ii,4),dilated_bbox(ii,1):dilated_bbox(ii,1)+dilated_bbox(ii,3));
    prev_mask_dilate_ROI{ii} = prevMask_dilate(dilated_bbox(ii,2):dilated_bbox(ii,2)+dilated_bbox(ii,4),dilated_bbox(ii,1):dilated_bbox(ii,1)+dilated_bbox(ii,3));
    im_relRGB{ii} = relativeRGB(cur_ROI{ii});
    BG_ROI{ii} = BGimg_ud(dilated_bbox(ii,2):dilated_bbox(ii,2)+dilated_bbox(ii,4),dilated_bbox(ii,1):dilated_bbox(ii,1)+dilated_bbox(ii,3),:);
    BG_ROI{ii} = imboxfilt(BG_ROI{ii},imFiltWidth);
    relBG_ROI{ii} = relativeRGB(BG_ROI{ii});
    BGmask_ROI{ii} = greenBGmask(dilated_bbox(ii,2):dilated_bbox(ii,2)+dilated_bbox(ii,4),dilated_bbox(ii,1):dilated_bbox(ii,1)+dilated_bbox(ii,3));
    BG_relRGBdiff{ii} = imabsdiff(im_relRGB{ii},relBG_ROI{ii});
    frontPanelMask_ROI = frontPanelMask(dilated_bbox(ii,2):dilated_bbox(ii,2)+dilated_bbox(ii,4),dilated_bbox(ii,1):dilated_bbox(ii,1)+dilated_bbox(ii,3));
    shelfMask_ROI = shelfMask(dilated_bbox(ii,2):dilated_bbox(ii,2)+dilated_bbox(ii,4),dilated_bbox(ii,1):dilated_bbox(ii,1)+dilated_bbox(ii,3));
    
    r = im_relRGB{ii}(:,:,1);
    g = im_relRGB{ii}(:,:,2);
    b = im_relRGB{ii}(:,:,3);
    
    BG_r = relBG_ROI{ii}(:,:,1);
    BG_g = relBG_ROI{ii}(:,:,2);
    BG_b = relBG_ROI{ii}(:,:,3);
    
    abs_grdiff = cur_ROI{ii}(:,:,2) - cur_ROI{ii}(:,:,1);
    abs_gbdiff = cur_ROI{ii}(:,:,2) - cur_ROI{ii}(:,:,3);
    
    abs_grdiffMask = abs_grdiff > min_abs_grDiff(ii);
    abs_gbdiffMask = abs_gbdiff > min_abs_gbDiff(ii);
    
    gr_diff = g - r;
    gb_diff = g - b;
    
    BG_gr_diff = BG_g - BG_r;
    BG_gb_diff = BG_g - BG_b;
    
    grMask = gr_diff > min_gr_diff(ii);
    gbMask = gb_diff > min_gb_diff(ii);
    
    gr_diff_clipped = gr_diff;
    gb_diff_clipped = gb_diff;
    gr_diff_clipped(gr_diff < 0) = 0;
    gb_diff_clipped(gb_diff < 0) = 0;
    
    BG_gr_diff_clipped = BG_gr_diff;
    BG_gb_diff_clipped = BG_gb_diff;
    BG_gr_diff_clipped(BG_gr_diff < 0) = 0;
    BG_BG_gb_diff_clipped(BG_gb_diff < 0) = 0;
    
    drkmsk{ii} = true(size(BGmask_ROI{ii}));
    for jj = 1 : 3
        drkmsk{ii} = drkmsk{ii} & cur_ROI{ii}(:,:,jj) < darkThresh(ii);
    end
    
    grDist = sqrt(gr_diff_clipped.^2 + gb_diff_clipped.^2);
    BG_grDist = sqrt(BG_gr_diff_clipped.^2 + BG_gb_diff_clipped.^2);
    if ii == 2
        grDist = grDist .* double(~(drkmsk{ii} & ~behindPanelMask));
    else
        grDist = grDist .* double(~drkmsk{ii});
    end
    grDist_adj = imadjust(grDist);
    BG_grDist_adj = imadjust(BG_grDist);
    

    
    if ii == 2
        intMask = intMask(dilated_bbox(ii,2):dilated_bbox(ii,2)+dilated_bbox(ii,4),dilated_bbox(ii,1):dilated_bbox(ii,1)+dilated_bbox(ii,3));
        extMask = extMask(dilated_bbox(ii,2):dilated_bbox(ii,2)+dilated_bbox(ii,4),dilated_bbox(ii,1):dilated_bbox(ii,1)+dilated_bbox(ii,3));
        
        prevMask_int = prev_mask_dilate_ROI{ii} & intMask;
        
        int_grMask = gr_diff > min_internal_gr_diff;
        int_gbMask = gb_diff > min_internal_gb_diff;
        intPawTest = int_grMask & int_gbMask & intMask & ~drkmsk{ii};
        if any(frontPanelMask_ROI(:)) && any(intPawTest(:))  % the front panel is included in the image, and there are candidate green points inside the box.
                                                             % Therefore, the paw may be both inside and outside the box.
            int_grDist = grDist .* double(intMask & ~(drkmsk{2} & ~behindPanelMask));
            int_grDist_adj = imadjust(int_grDist);
            grDist_adj(intMask) = int_grDist_adj(intMask);
        end
    end
    
    tempMask_res = (grDist_adj > grDistThresh_res(ii)) & grMask & gbMask & abs_grdiffMask; %& BGdiff_mask_ROI{ii};
    tempMask_lib = (grDist_adj > grDistThresh_lib(ii)) & grMask & gbMask & abs_grdiffMask;% & BGdiff_mask_ROI{ii};
%     tempMask_res = (grDist_adj > grDistThresh_res(ii)) & gbMask & BGdiff_mask_ROI{ii};
%     tempMask_lib = (grDist_adj > grDistThresh_lib(ii)) & gbMask & BGdiff_mask_ROI{ii};

    tempMask = imreconstruct(tempMask_res,tempMask_lib);
%     tempMask = tempMask & abs_grdiffMask & abs_gbdiffMask;
    
%     if ii == 1
%         tempMask = tempMask & ~shelfMask_ROI;
%     end
    
%     tempMask = tempMask & grMask & gbMask;   % make sure that any large differences between green and red/blue are not driven by just one color channel
    

    if ii == 2
        tempMask_int = tempMask & intMask;
        tempMask_ext = tempMask & extMask;
        extMask_border = bwmorph(tempMask_ext,'remove');
        if any(tempMask_ext(:)) && any(tempMask_int(:))
            [y,~] = find(extMask_border);
            min_y = min(y);
            max_y = max(y);
            extMask_proj = false(size(tempMask_int));
            extMask_proj(min_y:max_y,1:end) = true;
            behindPanelMask = behindPanelMask & extMask_proj;
        end
        current_drkmsk = drkmsk{2};% & ~behindPanelMask;
    else
        current_drkmsk = drkmsk{ii};
    end
    tempMask = tempMask & ~current_drkmsk;
    if ii == 2
        tempMask = tempMask & ~BGmask_ROI{ii};
    end
%     tempMask = tempMask & prev_mask_dilate_ROI{ii};
%     
    tempMask = processMask(tempMask,'sesize',2);
    
    if ii == 2
        tempMask_ext = tempMask & extMask;
        
        tempMask_ext_dilate = imdilate(tempMask_ext, strel('disk',5));
        frontPanelTest = tempMask_ext_dilate & frontPanelMask_ROI;
        if any(tempMask_ext(:)) && ~any(frontPanelTest(:)) && ~any(prevMask_int(:))    % if part of the paw is external to the box AND far enough away from the front panel that there shouldn't be any part on the inside
            tempMask_int = false(size(tempMask));
        else
            tempMask_int = tempMask & intMask;
        end
        extMask_border = bwmorph(tempMask_ext,'remove');
        if any(tempMask_ext(:)) && any(tempMask_int(:))   % make sure internal mask bits aren't wildly misaligned with the paw detected outside the box
            [y,~] = find(extMask_border);
            min_y = min(y);
            max_y = max(y);
            extMask_proj = false(size(tempMask_int));
            extMask_proj(min_y:max_y,1:end) = true;
            behindPanelMask = behindPanelMask & extMask_proj;
            current_drkmsk = drkmsk{2} & ~behindPanelMask;
            
            relBGdiffMask = BG_relRGBdiff{ii} > relBGdiff_thresh(ii);
            relBGdiffMask = relBGdiffMask(:,:,1) | relBGdiffMask(:,:,2) | relBGdiffMask(:,:,3);
            intMask_overlap = imdilate(extMask_proj,strel('disk',10)) & tempMask_int & ~current_drkmsk & relBGdiffMask;
%             intMask_overlap = processMask(intMask_overlap,'sesize',1);
            newMask_int = imreconstruct(intMask_overlap, tempMask_int);

            tempMask = tempMask_ext | newMask_int;
        else
            tempMask = tempMask_ext | tempMask_int;
        end
    else
        relBGdiffMask = BG_relRGBdiff{ii} > relBGdiff_thresh(ii);
        relBGdiffMask = relBGdiffMask(:,:,1) | relBGdiffMask(:,:,2) | relBGdiffMask(:,:,3);
        
        tempMask = tempMask & relBGdiffMask;
    end

    if ii == 2
        testIn = intMask & tempMask;
        pawIn = false;
        if any(testIn(:))
            pawIn = true;
        end
        tempMask = tempMask & ~frontPanelMask_ROI;
    end
    
    newMask{ii} = false(h,w);
    newMask{ii}(dilated_bbox(ii,2):dilated_bbox(ii,2)+dilated_bbox(ii,4),dilated_bbox(ii,1):dilated_bbox(ii,1)+dilated_bbox(ii,3)) = tempMask;
    newMask{ii} = newMask{ii} & ~floorMask;
end

fullMask = newMask;
% if any(newMask{1}(:)) && any(newMask{2}(:))
%     fullMask = maskProjectionBlobs(newMask,[1,1,w-1,h-1;1,1,w-1,h-1],fundMat,[h,w]);
% end