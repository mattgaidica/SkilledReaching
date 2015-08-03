function F = fundMatrixFromBGimg(BGimg, boxMarkers, varargin)
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

register_ROI = boxMarkers.register_ROI;
imWidth = size(BGimg, 2);

leftMirrorPoints  = zeros(22,2);    % markers in the left mirror
rightMirrorPoints = zeros(22,2);    % markers in the right mirror
left_center_points  = zeros(22,2); % markers to match with the left mirror in the center image
right_center_points = zeros(22,2); % markers to match with the right mirror in the center image

% match beads in the mirrors with beads in the direct view
leftMirrorPoints(1:2,:) = boxMarkers.beadLocations.left_mirror_red_beads;
leftMirrorPoints(3:4,:) = boxMarkers.beadLocations.left_mirror_top_blue_beads;
leftMirrorPoints(5:6,:) = boxMarkers.beadLocations.left_mirror_shelf_blue_beads;

left_center_points(1:2,:) = boxMarkers.beadLocations.center_red_beads;
left_center_points(3:4,:)  = boxMarkers.beadLocations.center_top_blue_beads;
left_center_points(5:6,:) = boxMarkers.beadLocations.center_shelf_blue_beads;

right_center_points(1:2,:) = boxMarkers.beadLocations.center_green_beads;
right_center_points(3:4,:) = boxMarkers.beadLocations.center_top_blue_beads;
right_center_points(5:6,:) = boxMarkers.beadLocations.center_shelf_blue_beads;

rightMirrorPoints(1:2,:) = boxMarkers.beadLocations.right_mirror_green_beads;
rightMirrorPoints(3:4,:) = boxMarkers.beadLocations.right_mirror_top_blue_beads;
rightMirrorPoints(5:6,:) = boxMarkers.beadLocations.right_mirror_shelf_blue_beads;

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
leftMirrorPoints(startMatchPoint:endMatchPoint,:) = left_mirror_cb;
rightMirrorPoints(startMatchPoint:endMatchPoint,:) = right_mirror_cb;
% note: need to flip the points left to right for the center mirror to make
% them match up

numRows = size(left_center_cb,1) / pointsPerRow;
for iRow = 1 : numRows
    startIdx = (iRow-1)*pointsPerRow + 1;
    endIdx   = iRow*pointsPerRow;
    left_center_cb(startIdx:endIdx,:) = left_center_cb(endIdx:-1:startIdx,:);
    right_center_cb(startIdx:endIdx,:) = right_center_cb(endIdx:-1:startIdx,:);
end

left_center_points(startMatchPoint:endMatchPoint,:) = left_center_cb;
right_center_points(startMatchPoint:endMatchPoint,:) = right_center_cb;
% move coordinates into sub-image components, and flip the mirror images
% left-right
leftMirrorPoints(:,1)    = leftMirrorPoints(:,1) - register_ROI(1,1) + 1;
leftMirrorPoints(:,1)    = register_ROI(1,3) - leftMirrorPoints(:,1);
rightMirrorPoints(:,1)   = rightMirrorPoints(:,1) - register_ROI(3,1) + 1;
rightMirrorPoints(:,1)   = register_ROI(3,3) - rightMirrorPoints(:,1);
left_center_points(:,1)  = left_center_points(:,1) - register_ROI(2,1) + 1;
right_center_points(:,1) = right_center_points(:,1) - register_ROI(2,1) + 1;

% calculate the fundamental matrices
F.left  = estimateFundamentalMatrix(leftMirrorPoints, left_center_points,'method','norm8point');
F.right = estimateFundamentalMatrix(rightMirrorPoints, right_center_points,'method','norm8point');

end