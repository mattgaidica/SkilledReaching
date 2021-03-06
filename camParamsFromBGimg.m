function [F,cParams] = camParamsFromBGimg(BGimg, boxMarkers, varargin)
%
% usage: 
%
% INPUTS:
%   BGimg - the background image averaged from the first ~50 frames of each
%       video
%   boxMarkers - structure with the following fields:
%        .register_ROI - 3 x 4 matrix.
%                   1st row - boundaries of left mirror region of interest
%                   2nd row - boundaries of center region of interest
%                   3rd row - boundaries of right mirror region of interest

% measure registration points from each perspective. Coordinates are with
% respect to the full video frame (that is, from the top left corner). To
% get coordinates in a segment of the image, subtract the location of the
% left/top edge of the subset

% note, this is hard-coded from the session R0030_20140430a. Will need
% other registration points for different sessions

pointsPerRow = 4;    % for the checkerboard detection
cb_spacing = 8;   % mm

for iarg = 1 : 2 : nargin - 2
    switch lower(varargin{iarg})
        case 'pointsperrow',
            pointsPerRow = varargin{iarg + 1};
    end
end

S = whos('BGimg');
if strcmpi(S.class,'uint8')
    BGimg = double(BGimg) / 255;
end

cParams = cell(1,3);
cParams_old = cell(1,3);

register_ROI = boxMarkers.register_ROI;
imWidth = size(BGimg, 2);

left_mirror_points  = zeros(22,2);    % markers in the left mirror
right_mirror_points = zeros(22,2);    % markers in the right mirror
left_center_points  = zeros(22,2); % markers to match with the left mirror in the center image
right_center_points = zeros(22,2); % markers to match with the right mirror in the center image

% match beads in the mirrors with beads in the direct view
left_mirror_points(1:2,:) = boxMarkers.beadLocations.left_mirror_red_beads;
left_mirror_points(3:4,:) = boxMarkers.beadLocations.left_mirror_top_blue_beads;
left_mirror_points(5:6,:) = boxMarkers.beadLocations.left_mirror_shelf_blue_beads;

left_center_points(1:2,:) = boxMarkers.beadLocations.center_red_beads;
left_center_points(3:4,:)  = boxMarkers.beadLocations.center_top_blue_beads;
left_center_points(5:6,:) = boxMarkers.beadLocations.center_shelf_blue_beads;

right_center_points(1:2,:) = boxMarkers.beadLocations.center_green_beads;
right_center_points(3:4,:) = boxMarkers.beadLocations.center_top_blue_beads;
right_center_points(5:6,:) = boxMarkers.beadLocations.center_shelf_blue_beads;

right_mirror_points(1:2,:) = boxMarkers.beadLocations.right_mirror_green_beads;
right_mirror_points(3:4,:) = boxMarkers.beadLocations.right_mirror_top_blue_beads;
right_mirror_points(5:6,:) = boxMarkers.beadLocations.right_mirror_shelf_blue_beads;

startMatchPoint= 7;

% below images could be useful for debugging
% BG_lft = double(BGimg(register_ROI(1,2):register_ROI(1,2) + register_ROI(1,4), ...
%                      register_ROI(1,1):register_ROI(1,1) + register_ROI(1,3), :));
% BG_ctr = double(BGimg(register_ROI(2,2):register_ROI(2,2) + register_ROI(2,4), ...
%                      register_ROI(2,1):register_ROI(2,1) + register_ROI(2,3), :));
% BG_rgt = double(BGimg(register_ROI(3,2):register_ROI(3,2) + register_ROI(3,4), ...
%                      register_ROI(3,1):register_ROI(3,1) + register_ROI(3,3), :));
% BG_leftctr  = double(BGimg(register_ROI(2,2):register_ROI(2,2) + register_ROI(2,4), ...
%                     register_ROI(2,1):round(imWidth/2), :));
% BG_rightctr = double(BGimg(register_ROI(2,2):register_ROI(2,2) + register_ROI(2,4), ...
%                     round(imWidth/2):register_ROI(2,1) + register_ROI(2,3), :));

% MATCH THE CHECKERBOARD POINTS
% find the checkerboards, and map them onto coordinates in the original
% image
% left_mirror_cb  = detect_SR_checkerboard(BG_lft);
% right_mirror_cb = detect_SR_checkerboard(BG_rgt);
% left_center_cb  = detect_SR_checkerboard(BG_leftctr);
% right_center_cb = detect_SR_checkerboard(BG_rightctr);

left_mirror_cb(:,1) = boxMarkers.cbLocations.left_mirror_cb(:,1);
left_mirror_cb(:,2) = boxMarkers.cbLocations.left_mirror_cb(:,2) + register_ROI(1,2) - 1;
right_mirror_cb(:,1) = boxMarkers.cbLocations.right_mirror_cb(:,1);
right_mirror_cb(:,2) = boxMarkers.cbLocations.right_mirror_cb(:,2) + register_ROI(3,2) - 1;
left_center_cb(:,1) = boxMarkers.cbLocations.left_center_cb(:,1);
left_center_cb(:,2) = boxMarkers.cbLocations.left_center_cb(:,2) + register_ROI(2,2) - 1;
right_center_cb(:,1) = boxMarkers.cbLocations.right_center_cb(:,1);
right_center_cb(:,2) = boxMarkers.cbLocations.right_center_cb(:,2) + register_ROI(2,2) - 1;

% now map the points into the point-matching matrices
num_cb_points = size(left_mirror_cb, 1);
endMatchPoint = startMatchPoint + num_cb_points - 1;

% note: need to flip the points left to right for the mirror views to make
% them match up

numRows = size(left_center_cb,1) / pointsPerRow;
for iRow = 1 : numRows
    startIdx = (iRow-1)*pointsPerRow + 1;
    endIdx   = iRow*pointsPerRow;
    left_mirror_cb(startIdx:endIdx,:) = left_mirror_cb(endIdx:-1:startIdx,:);
    right_mirror_cb(startIdx:endIdx,:) = right_mirror_cb(endIdx:-1:startIdx,:);
end

left_mirror_points(startMatchPoint:endMatchPoint,:) = left_mirror_cb;
right_mirror_points(startMatchPoint:endMatchPoint,:) = right_mirror_cb;

left_center_points(startMatchPoint:endMatchPoint,:) = left_center_cb;
right_center_points(startMatchPoint:endMatchPoint,:) = right_center_cb;
% move coordinates into sub-image components, and flip the mirror images
% TURNS OUT WE DON'T NEED TO DO THIS; JUST MOVES CAMERAS BY A TRANSLATION
% left-right
% left_mirror_points(:,1)    = left_mirror_points(:,1) - register_ROI(1,1) + 1;
% left_mirror_points(:,1)    = register_ROI(1,3) - left_mirror_points(:,1);
% right_mirror_points(:,1)   = right_mirror_points(:,1) - register_ROI(3,1) + 1;
% right_mirror_points(:,1)   = register_ROI(3,3) - right_mirror_points(:,1);
% left_center_points(:,1)  = left_center_points(:,1) - register_ROI(2,1) + 1;
% right_center_points(:,1) = right_center_points(:,1) - register_ROI(2,1) + 1;

% calculate the fundamental matrices
F.left  = estimateFundamentalMatrix(left_center_points, left_mirror_points,'method','norm8point');
F.right = estimateFundamentalMatrix(right_center_points, right_mirror_points,'method','norm8point');

f = 8; % focal length in mm
x0 = ((size(BGimg, 2)+1) / 2);
y0 = ((size(BGimg, 1)+1) / 2);

x0prime = ((size(BGimg, 2)+1) / 2) - (register_ROI(1,1)-1);
y0prime = ((size(BGimg, 1)+1) / 2) - (register_ROI(1,2)-1);
pixSize = 5.5e-3;
K = [f/pixSize  000        x0
     000        f/pixSize  y0
     000        000        01];

cParams_dist = estimateDirectCameraParams(boxMarkers, cb_spacing, pointsPerRow);

% K = [f     000   x0*pixSize
%      000   f     y0*pixSize
%      000   000   pixSize];

% calculate the essential matrix, and then the camera matrices for the
% mirror views follwing Chaper 9 of Hartley and Zisserman
E.left  = K * F.left * K';    % note matlab intrinsic matrices are the transpose of the way
E.right = K * F.right * K';   % Hartley and Zisserman define them

W = [0 -1 0
     1  0 0
     0  0 1];
 
Z = [0  1 0
     -1 0 0
     0  0 0];
 
[Uleft,Sleft,Vleft] = svd(E.left);
[Uright,Sright,Vright] = svd(E.right);

Pleft  = [Uleft * W * Vleft',Uleft(:,3)]';
Pright = [Uright * W * Vright',Uright(:,3)]';

Pd = eye(4,3);

cParams{2} = cameraParameters('intrinsicmatrix',K');
[Rl,tl] = estimateExtrinsics(left_mirror_cb, 8, 4, K');
[Rd,td] = estimateExtrinsics(left_center_cb, 8, 4, K');

Pd = [Rd;td]*K';
Pl = [Rl;tl]*K';
temp = triangulate(left_center_points, left_mirror_points, Pd, Pl);

cParams_old{2} = estimateDirectCameraParams(boxMarkers, cb_spacing, pointsPerRow);
K = cParams{2}.IntrinsicMatrix;    % assume camera intrinsics are the same for mirror and direct views;
                                   % this seems to be generally true based
                                   % on my reading
cParams{1} = cameraParameters('IntrinsicMatrix',K);
cParams{3} = cameraParameters('IntrinsicMatrix',K);


% DOES IT MATTER THE ORDER IN WHICH THE POINTS ARE DEFINED IN CALCULATING
% THE CAMERA MATRICES?


end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function cParams = estimateDirectCameraParams(boxMarkers, cb_spacing, pointsPerRow)
%
% INPUTS:
%   boxMarkers
%   cb_spacing - real world size of a single checkerboard square (distance
%       between adjacent checkerboard points)

% 4 images because there are 4 checkerboards for the time being
% see matlab documentation for estimateCameraParameters to see how the
% imPoints matrix is structured

num_cb_points = size(boxMarkers.cbLocations.left_mirror_cb,1);
imPoints = zeros(num_cb_points,2,4);

imPoints(:,:,1) = boxMarkers.cbLocations.left_mirror_cb;
imPoints(:,:,2) = boxMarkers.cbLocations.left_center_cb;
imPoints(:,:,3) = boxMarkers.cbLocations.right_center_cb;
imPoints(:,:,4) = boxMarkers.cbLocations.right_mirror_cb;

wPoints = zeros(num_cb_points,2);
numRows = num_cb_points / pointsPerRow;
if numRows ~= round(numRows)
    error('checkerboard pattern must be complete')
end

for iRow = 1 : numRows
    startIdx = (iRow-1)*pointsPerRow + 1;
    endIdx   = iRow * pointsPerRow;
    
    wPoints(startIdx:endIdx,1) = 0 : cb_spacing : cb_spacing*(pointsPerRow-1);
    wPoints(startIdx:endIdx,2) = (iRow-1) * cb_spacing;
end    % for iRow...

[cParams,imused,estErrors] = estimateCameraParameters(imPoints,wPoints);

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [R,t] = estimateExtrinsics(cb_pts, cb_spacing, pointsPerRow, camIntrinsics)
%
% INPUTS:
%   boxMarkers
%   cb_spacing - real world size of a single checkerboard square (distance
%       between adjacent checkerboard points)

num_cb_points = size(cb_pts,1);

wPoints = zeros(num_cb_points,2);
numRows = num_cb_points / pointsPerRow;
if numRows ~= round(numRows)
    error('checkerboard pattern must be complete')
end

for iRow = 1 : numRows
    startIdx = (iRow-1)*pointsPerRow + 1;
    endIdx   = iRow * pointsPerRow;
    
    wPoints(startIdx:endIdx,1) = 0 : cb_spacing : cb_spacing*(pointsPerRow-1);
    wPoints(startIdx:endIdx,2) = (iRow-1) * cb_spacing;
end    % for iRow...

cParams = cameraParameters('intrinsicmatrix',camIntrinsics);
[R,t] = extrinsics(cb_pts,wPoints,cParams);

end