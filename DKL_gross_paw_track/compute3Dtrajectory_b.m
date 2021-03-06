function [points3d,new_points2d] = compute3Dtrajectory_b(video, points2d, track_metadata, pawPref, boxRegions )

numFrames = size(points2d, 2);

points3d = cell(numFrames,1);
new_points2d = points2d;

timeList = zeros(video.FrameRate * video.Duration,1);
isFrameCalculated = false(size(points2d,2),1);
timeDirection = 'forward';
[points3d,new_points2d,timeList,isFrameCalculated] = compute_3Dtrajectory_loop(video, new_points2d, points3d, track_metadata, pawPref, boxRegions, timeDirection,timeList,isFrameCalculated);

timeDirection = 'reverse';
[points3d,new_points2d,timeList,isFrameCalculated] = compute_3Dtrajectory_loop(video, new_points2d, points3d, track_metadata, pawPref, boxRegions, timeDirection,timeList,isFrameCalculated);

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [points3d,new_points2d,timeList,isFrameCalculated] = compute_3Dtrajectory_loop(video, new_points2d, points3d, track_metadata, pawPref, boxRegions, timeDirection,timeList,isFrameCalculated)

zeroTol = 1e-10;
fps = video.FrameRate;
video.CurrentTime = track_metadata.triggerTime;

boxCalibration = track_metadata.boxCalibration;
cameraParams = boxCalibration.cameraParams;

switch pawPref
    case 'left'
        F = squeeze(boxCalibration.srCal.F(:,:,2));
    case 'right'
        F = squeeze(boxCalibration.srCal.F(:,:,1));
end
old_points2d = new_points2d;

if strcmpi(timeDirection,'reverse')
    numFrames = round((video.CurrentTime) * fps);
    frameCount = numFrames;
else
    numFrames = round((video.Duration - video.CurrentTime) * fps);
    frameCount = 0;
end
totalFrames = round(video.Duration * fps);

prevFrame = 0;
while video.CurrentTime < video.Duration && video.CurrentTime >= 0
    
    if strcmpi(timeDirection,'reverse') && prevFrame == 0
        % this is the first step, load the current image and make it the
        % previous image
        prev_image = readFrame(video);
        img_ud = undistortImage(prev_image, cameraParams);
        img_ud = double(img_ud) / 255;
    end
    if strcmpi(timeDirection,'reverse')
        frameCount = frameCount - 1;
        if frameCount == 0
            break;
        end
        video.CurrentTime = frameCount / fps;
    else
        frameCount = frameCount + 1;
    end
    currentFrame = round((video.CurrentTime) * fps);
    timeList(currentFrame) = video.CurrentTime;
    fprintf('frame number %d, current frame %d\n',frameCount, currentFrame);
    
    image = readFrame(video);
    if strcmpi(timeDirection,'reverse')
        prevFrame = currentFrame;
        if abs(video.CurrentTime - timeList(prevFrame)) > zeroTol    % a frame was skipped
            % if going backwards, went one too many frames back, so just
            % read the next frame
            image = readFrame(video);
        end
    end
    
    if prevFrame > 0 && strcmpi(timeDirection,'forward') && ...
       abs(video.CurrentTime - timeList(prevFrame) - 2/fps) > zeroTol && ...
       video.CurrentTime - timeList(prevFrame) - 2/fps < 0
            % if going forwards, this means the CurrentTime didn't advance
            % by 1/fps on the last read (not sure why this occasionally
            % happens - some sort of rounding error)
            timeList(currentFrame) = video.CurrentTime;
    else           
        timeList(currentFrame) = video.CurrentTime - 1/fps;
    end

    if prevFrame > 0
        prev_img_ud = img_ud;
    else
        prev_img_ud = zeros(video.Height, video.Width, 3);
    end
    
    img_ud = undistortImage(image, cameraParams);
    img_ud = double(img_ud) / 255;
    
    if ~isFrameCalculated(currentFrame)
        [points3d{currentFrame},new_points2d,isFrameCalculated] = computeNext3Dpoints( new_points2d, points3d, currentFrame, prevFrame, video, img_ud, prev_img_ud, boxCalibration, pawPref, boxRegions, timeDirection, isFrameCalculated );
        
    % code below is for visualization purposes during debugging
        old_2d{1} = old_points2d{1,currentFrame};
        old_2d{2} = old_points2d{2,currentFrame};
        new_2d{1} = new_points2d{1,currentFrame};
        new_2d{2} = new_points2d{2,currentFrame};
        showNewTracking(img_ud,old_2d,new_2d,F);
        plot3Dpoints(points3d{currentFrame});

        prevFrame = currentFrame;
    end
    


end


end    % function compute_3Dtrajectory_loop

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [frame_points3D,new_points2d,isFrameCalculated] = computeNext3Dpoints( new_points2d, points3d, currentFrame, prevFrame, video, img_ud, prev_img_ud, boxCalibration, pawPref, boxRegions, timeDirection, isFrameCalculated )
%
% INPUTS:
%   points2d - all of the paw points identified in all frames: 2 x n cell
%       array where n is the number of frames
%
% OUTPUTS:
%

switch pawPref
    case 'right'
        F = squeeze(boxCalibration.srCal.F(:,:,1));
    case 'left'
        F = squeeze(boxCalibration.srCal.F(:,:,2));
end
h = size(img_ud,1); w = size(img_ud,2);

frame_points2d = cell(1,2);
% frame_points2d{1} =  new_points2d{1,currentFrame};
% frame_points2d{2} =  new_points2d{2,currentFrame};

% use knowledge of where the 3D points were from the previous frame, where
% the paw was identified in the current frame/view (if at all), the current
% frame image, and where the paw was identified in adjacent frames to
% estimate where it is now

% 3 possibilities:
%   1. the paw is visible in both views. In this case, 
%
%   2. the paw is only visible in one view.

%   3. the paw is visible in neither view

bboxes = zeros(2,4);
bboxes(1,:) = [1,1,h-1,w-1];
bboxes(2,:) = bboxes(1,:);
if ~isempty(new_points2d{1, currentFrame}) && ~isempty(new_points2d{2, currentFrame})
    % paw is visible in both views
    % now, figure out if the masks line up via epipolar geometry
    new_points2d = masks2d_from_both_views( new_points2d, points3d, currentFrame, prevFrame, img_ud, prev_img_ud, boxCalibration, pawPref, boxRegions );
    isFrameCalculated(currentFrame) = true;
elseif isempty(new_points2d{1, currentFrame}) && isempty(new_points2d{2, currentFrame})
    % paw isn't visible in either view - assume we're done
    isFrameCalculated(currentFrame) = true;
else
    [new_points2d,isFrameCalculated] = masks2d_from_one_view( new_points2d, points3d, currentFrame, prevFrame, video, boxCalibration, pawPref, boxRegions, timeDirection, isFrameCalculated );
end
    
pawMask = cell(1,2);
tanPts = zeros(2,2,2);   % x,y,view

[~,epipole] = isEpipoleInImage(F,[h,w]);

ext_pts = cell(1,2);
for iView = 1 : 2
    try
        cvx_hull_idx = convhull(new_points2d{iView,currentFrame});
    catch
        keyboard
    end
    pawMask{iView} = poly2mask(new_points2d{iView,currentFrame}(cvx_hull_idx,1),new_points2d{iView,currentFrame}(cvx_hull_idx,2),h,w);
    pawMask{iView} = bwconvhull(pawMask{iView},'union');

    extMask = bwmorph(pawMask{iView},'remove');
    [y,x] = find(extMask);
    s = regionprops(extMask,'centroid');
    ext_pts{iView} = sortClockWise(s.Centroid,[x,y]);
    [tanPts(:,:,iView), ~] = findTangentToBlob(pawMask{iView}, epipole);
end

[frame_points3D,~] = bordersTo3D_bothDirs(ext_pts, boxCalibration, bboxes, tanPts, [h,w]);

end    % function

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function new_2dpoints = masks2d_from_both_views( points2d, points3d, currentFrame, prevFrame, img_ud, prev_img_ud, boxCalibration, pawPref, boxRegions )
    
h = size(img_ud,1);w = size(img_ud,2);
orig_mask_dilate = 40;
% find instances where the epipolar tangent lines  
tanPts = zeros(2,2,2);   % x,y,view
tanLines = zeros(2,3,2);   % x,y,view
borderpts = zeros(2,4,2);
pawMask = cell(1,2);
ext_pts = cell(1,2);

new_2dpoints = points2d;

frame_points2d = cell(1,2);
frame_points2d{1} =  points2d{1,currentFrame};
frame_points2d{2} =  points2d{2,currentFrame};

if prevFrame > 0
    prev_points2d = cell(1,2);
    prev_points2d{1} = points2d{1,prevFrame};
    prev_points2d{2} = points2d{2,prevFrame};
end

switch lower(pawPref)
    case 'right'
        F = squeeze(boxCalibration.srCal.F(:,:,1));
    case 'left'
        F = squeeze(boxCalibration.srCal.F(:,:,2));
end
            
[~,epipole] = isEpipoleInImage(F,[h,w]);

projMask = cell(1,2);
prev_pawMask = cell(1,2);
for iView = 1 : 2
    
    if prevFrame > 0
        prev_hull_idx = convhull(prev_points2d{iView});
        prev_pawMask{iView} = poly2mask(prev_points2d{iView}(prev_hull_idx,1),prev_points2d{iView}(prev_hull_idx,2),h,w);
        prev_pawMask{iView} = bwconvhull(prev_pawMask{iView},'union');
    else
        prev_pawMask{iView} = false(h,w);
    end
    
    cvx_hull_idx = convhull(frame_points2d{iView});
    pawMask{iView} = poly2mask(frame_points2d{iView}(cvx_hull_idx,1),frame_points2d{iView}(cvx_hull_idx,2),h,w);
    pawMask{iView} = bwconvhull(pawMask{iView},'union');
    
end

% is the paw entirely outside the box or entirely below the shelf? If so,
% don't need to worry about shelf occlusions
% testMask_int = pawMask{2} & boxRegions.intMask;
% testMask_below = (projMask{2} & imdilate(pawMask{1},strel('disk',orig_mask_dilate))) & ... the intersection of the projection mask with the dilated direct paw mask;
%                  ~boxRegions.belowShelfMask;  % are the paw & the projection from the mirror mask entirely below the shelf? There will be true elements in testMask_below if the paw might overlap with the shelf
% is any of the paw inside the box likely to be behind the shelf?

[greenMask,redMask,fullMask] = findGreen_and_red_paw_regions(img_ud, pawMask, prev_pawMask, boxCalibration, pawPref, boxRegions);
for iView = 1 : 2
    edgeMask = bwmorph(fullMask{iView},'remove');
    [y,x] = find(edgeMask);
    new_2dpoints{iView,currentFrame} = [x,y];
end

end    % function masks2d_from_both_views

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [new_2dpoints,isFrameCalculated] = masks2d_from_one_view( points2d, points3d, currentFrame, prevFrame, video, boxCalibration, pawPref, boxRegions, timeDirection, isFrameCalculated )
    
h = video.Height;w = video.Width;
% orig_mask_dilate = 40;
% find instances where the epipolar tangent lines  
% tanPts = zeros(2,2,2);   % x,y,view
% tanLines = zeros(2,3,2);   % x,y,view
% borderpts = zeros(2,4,2);
pawMask = cell(1,2);
% ext_pts = cell(1,2);

new_2dpoints = points2d;

if prevFrame > 0
    prev_points2d = cell(1,2);
    prev_points2d{1} = points2d{1,prevFrame};
    prev_points2d{2} = points2d{2,prevFrame};
end

switch lower(pawPref)
    case 'right'
        F = squeeze(boxCalibration.srCal.F(:,:,1));
    case 'left'
        F = squeeze(boxCalibration.srCal.F(:,:,2));
end
            
% [~,epipole] = isEpipoleInImage(F,[h,w]);
% 
% projMask = cell(1,2);
prev_pawMask = cell(1,2);

if strcmpi(timeDirection,'forward')
    frameStep = 1;
else
    frameStep = -1;
end
testFrame = currentFrame;
while (isempty(points2d{1,testFrame}) || isempty(points2d{2,testFrame})) || testFrame == 0 || testFrame == size(points2d,2)
    testFrame = testFrame + frameStep;
end

if testFrame == 0 || testFrame == size(points2d,2)     % we're at either the end or beginning of the video, no point in doing the calculations - not at an interesting part of the video
    if frameStep == 1
        isFrameCalculated(currentFrame : testFrame) = true;
    else
        isFrameCalculated(1 : currentFrame) = true;
    end
    return;
end

frame_points2d = cell(1,2);
frame_points2d{1} =  points2d{1,testFrame};
frame_points2d{2} =  points2d{2,testFrame};

video.CurrentTime = testFrame / video.FrameRate;
img = readFrame(video);
img_ud = undistortImage(img, boxCalibration.cameraParams);
img_ud = double(img_ud) / 255;

for iView = 1 : 2

    prev_pawMask{iView} = false(h,w);

    cvx_hull_idx = convhull(frame_points2d{iView});

    pawMask{iView} = poly2mask(frame_points2d{iView}(cvx_hull_idx,1),frame_points2d{iView}(cvx_hull_idx,2),h,w);
    pawMask{iView} = bwconvhull(pawMask{iView},'union');

end

% now find the paw in the next frame in which it was found in both
% views
[greenMask,redMask,fullMask] = findGreen_and_red_paw_regions(img_ud, pawMask, prev_pawMask, boxCalibration, pawPref, boxRegions);

for iView = 1 : 2
    edgeMask = bwmorph(fullMask{iView},'remove');
    [y,x] = find(edgeMask);
    new_2dpoints{iView,testFrame} = [x,y];
end
isFrameCalculated(testFrame) = true;

% now fill in the blanks between the last frame for which we have a
% calculation and testFrame
start2Dpts = cell(1,2);
end2Dpts = cell(1,2);

numFrames_to_interpolate = abs(currentFrame - testFrame);
startLeft = zeros(1,2);
startRight = zeros(1,2);
startTop = zeros(1,2);
startBot = zeros(1,2);

endLeft = zeros(1,2);
endRight = zeros(1,2);
endTop = zeros(1,2);
endBot = zeros(1,2);
for iView = 1 : 2
    start2Dpts{iView} = new_2dpoints{iView,currentFrame - frameStep};
    end2Dpts{iView} = new_2dpoints{iView,testFrame};
    
    startLeft(iView) = min(start2Dpts{iView}(:,1));
    startRight(iView) = max(start2Dpts{iView}(:,1));
    startTop(iView) = min(start2Dpts{iView}(:,2));
    startBot(iView) = max(start2Dpts{iView}(:,2));
    
    endLeft(iView) = min(end2Dpts{iView}(:,1));
    endRight(iView) = max(end2Dpts{iView}(:,1));
    endTop(iView) = min(end2Dpts{iView}(:,2));
    endBot(iView) = max(end2Dpts{iView}(:,2));
end
prev_points2d = cell(1,2);
frame_points2d = cell(1,2);
for iFrame = currentFrame : frameStep : testFrame - frameStep
    
    video.CurrentTime = iFrame / video.FrameRate;
    img = readFrame(video);
    img_ud = undistortImage(img, boxCalibration.cameraParams);
    img_ud = double(img_ud) / 255;
    for iView = 1 : 2
        
        prev_points2d{iView} = new_2dpoints{iView,iFrame - frameStep};
    
        % is there already a mask in this view? If so, don't change it for
        % now
        if any(new_2dpoints{iView,iFrame})
            frame_points2d{iView} = new_2dpoints{iView,iFrame};
        else
            
            newLeft = round(startLeft(iView) + (endLeft(iView) - startLeft(iView)) / (numFrames_to_interpolate + 1));
            newRight = round(startRight(iView) + (endRight(iView) - startRight(iView)) / (numFrames_to_interpolate + 1));
            newTop = round(startTop(iView) + (endTop(iView) - startTop(iView)) / (numFrames_to_interpolate + 1));
            newBot = round(startBot(iView) + (endBot(iView) - startBot(iView)) / (numFrames_to_interpolate + 1));
            
            frame_points2d{iView} = [newLeft,newTop;
                                     newRight,newTop;
                                     newRight,newBot;
                                     newLeft,newBot];
        end
        prev_hull_idx = convhull(prev_points2d{iView});
        prev_pawMask{iView} = poly2mask(prev_points2d{iView}(prev_hull_idx,1),prev_points2d{iView}(prev_hull_idx,2),h,w);
        prev_pawMask{iView} = bwconvhull(prev_pawMask{iView},'union');
        
        cvx_hull_idx = convhull(frame_points2d{iView});
        pawMask{iView} = poly2mask(frame_points2d{iView}(cvx_hull_idx,1),frame_points2d{iView}(cvx_hull_idx,2),h,w);
        pawMask{iView} = bwconvhull(pawMask{iView},'union');
    end
    for iView = 1 : 2
        if ~any(new_2dpoints{iView,iFrame})    % make sure we don't make the interpolated view bigger than the projection of the other view in the same frame
            otherProjMask = projMaskFromTangentLines(pawMask{3-iView},F,[1,1,h-1,w-1],[h,w]);
            pawMask{iView} = pawMask{iView} & otherProjMask;
        end
    end 
                 
    [greenMask,redMask,fullMask] = findGreen_and_red_paw_regions(img_ud, pawMask, prev_pawMask, boxCalibration, pawPref, boxRegions);
    isFrameCalculated(iFrame) = true;
    for iView = 1 : 2
        edgeMask = bwmorph(fullMask{iView},'remove');
        [y,x] = find(edgeMask);
        new_2dpoints{iView,iFrame} = [x,y];
    end
end

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


function epiMask = mask_along_epiLine( epiLine, pawMask, varargin )
pawDilate = 50;
max_dist_from_line = 1;

for iarg = 1 : 2 : nargin - 2
    switch lower(varargin{iarg})
        case 'pawdilate'
            pawDilate = varargin{iarg + 1};
        case 'maxdistfromline'
            max_dist_from_line = varargin{iarg + 1};
    end
end

searchMask = imdilate(pawMask,strel('disk',pawDilate));
[y_pawMask,x_pawMask] = find(searchMask);

% find points close to the epipolarLine
testValues = epiLine(1) * x_pawMask + epiLine(2) * y_pawMask + epiLine(3);
epi_pts_idx = find(abs(testValues) < max_dist_from_line);

epiMask = false(size(pawMask));

for ii = 1 : length(epi_pts_idx) 
    epiMask(y_pawMask(epi_pts_idx(ii)),x_pawMask(epi_pts_idx(ii))) = true;
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function tf = pointInRegion(testPt, regionMask)

testMask = false(size(regionMask));
testMask(testPt) = true;

testMask = testMask & regionMask;

tf = any(testMask(:));

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
