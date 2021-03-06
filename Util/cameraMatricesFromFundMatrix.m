function [P1,P2] = cameraMatricesFromFundMatrix(boxMarkers, rat_metadata)
%
% usage: [P1,P2] = cameraMatricesFromFundMatrix(boxMarkers, rat_metadata)
%
% function to compute camera matrices from the fundamental matrix. Note
% that the camera matrices returned are only correct within a scale factor.
% Still need to calibrate using the checkerboard pattern
%
% INPUTS:
%   boxMarkers - structure containing the following:
%       beadLocations (not needed for this function)
%       beadMasks (not needed for this function)
%       cbLocations (not needed for this function)
%       frontPanel_x (not needed for this function)
%       front_anel_y (not needed for this function)
%       register_ROI - 3 x 4 matrix where each row is in the form
%           [left edge, top edge, width, height]. First row is for the
%           image in the left mirror, second row for the direct image,
%           third row is for the image in the right mirror
%       F - structure containing the fundamental matrices going from the
%           mirror views to direct view. F is calculated by flipping the
%           mirror views left to right, so that it is as if there is a
%           second camera pointing into the box. F.left is the fundamental
%           matrix going from left mirror view to direct view; F.right is
%           the fundamental matrix going from the right mirror view to the
%           direct view
%
%   rat_metadata - structure containing the following:
%       ratID - rat ID number
%       localizers_present - whether or not image localizers (beads and
%           checkerboards) are present
%       camera_distance - distance from the camera to the box in cm (I think)
%       pawPref - string, or cell array, containing whether the rat was
%           supposed to use its left or right paw (strings are either
%           "left" or "right"
%
% OUTPUTS:
%   P1 - camera matrix for the direct camera
%   P2 - camera matrix for the virtual mirror view camera


pawPref = lower(rat_metadata.pawPref);
if iscell(pawPref)
    pawPref = pawPref{1};
end

register_ROI = boxMarkers.register_ROI;
switch pawPref
    case 'left',
        F_side = boxMarkers.F.right;
        mirror_h = [register_ROI(3,4) + 1];
        mirror_w = [register_ROI(3,3) + 1];
    case 'right',
        F_side = boxMarkers.F.left;
        mirror_h = [register_ROI(1,4) + 1];
        mirror_w = [register_ROI(1,3) + 1];
end
mirrorImgSize = [mirror_h, mirror_w];

P1 = [eye(3), zeros(3,1)];

[~,epipole] = isEpipoleInImage(F_side, mirrorImgSize);
epipole = [epipole,1]';
e_x = skewSymm(epipole);
P2 = zeros(3,4);

P2(:,1:3) = e_x * F_side';
P2(:,4) = epipole;

P1 = P1';P2 = P2';   % matlab turns the camera matrices on their sides compared to most conventions

end