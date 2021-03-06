function slotPoints = slot3dcoords(session_mp, varargin)
%
% function to estimate the 3d coordinates of the lower left and right
% corners of the reaching slot
%
% INPUTS:
%
% OUTPUTS:
%   slotPoints

rubikSpacing = 17.5;    % in mm
boxWidth = 150;         % in mm

K = [];
srCal = [];

excludePoints = {'left_bottom_box_corner','right_bottom_box_corner'};
camParamFile = '/Users/dleventh/Documents/Leventhal_lab_github/SkilledReaching/Manual Tracking Analysis/ConvertMarkedPointsToReal/cameraParameters.mat';
cb_path = '/Users/dleventh/Documents/Leventhal_lab_github/SkilledReaching/tattoo_track_testing/intrinsics calibration images';
computeCamParams = false;

for iarg = 1 : 2 : nargin - 1
    switch lower(varargin{iarg})
        case 'rubikspacing',
            rubikSpacing = varargin{iarg + 1};
        case 'boxwidth',
            boxWidth = varargin{iarg + 1};
        case 'excludepoints',
            excludePoints = varargin{iarg + 1};
        case 'intrinsicmatrix',
            K = varargin{iarg + 1};
        case 'srcal',
            srCal = varargin{iarg + 1};
    end
end

if isempty(K)
    if computeCamParams
        [cameraParams, ~, ~] = cb_calibration(...
                               'cb_path', cb_path, ...
                               'num_rad_coeff', num_rad_coeff, ...
                               'est_tan_distortion', est_tan_distortion, ...
                               'estimateskew', estimateSkew);
    else
        load(camParamFile);    % contains a cameraParameters object named cameraParams
    end
    K = cameraParams.IntrinsicMatrix;   % camera intrinsic matrix (matlab format, meaning lower triangular
                                        %       version - Hartley and Zisserman and the rest of the world seem to
                                        %       use the transpose of matlab K)
end

if isempty(srCal)
    [x1_left,x2_left,x1_right,x2_right,~,~] = ...
        sr_sessionMatchedPointVector(session_mp, 'excludepoints', excludePoints);
    srCal = sr_calibration(x1_left,x2_left,x1_right,x2_right, 'intrinsicmatrix', K);
end

P = squeeze(srCal.P(:,:,:,1));

sf = sr_estimateScale(session_mp, P, K, ...              % need to work on an alternative if no rubiks
                      'rubikspacing', rubikSpacing, ...
                      'boxwidth', boxWidth);
                  
% assume the "left_back_shelf_corner" and "right_back_shelf_corner" will
% give the z-location of the slot
shelfBackPts = zeros(4,2);
shelfBackPts(1,:) = session_mp.direct.left_back_shelf_corner;
shelfBackPts(2,:) = session_mp.leftMirror.left_back_shelf_corner;
shelfBackPts(3,:) = session_mp.direct.right_back_shelf_corner;
shelfBackPts(4,:) = session_mp.rightMirror.right_back_shelf_corner;

shelfBackPts_norm = normalize_points(shelfBackPts, K);

[leftBack3d,reprojectedPoints,errors] = triangulate_DL(shelfBackPts_norm(1,:), shelfBackPts_norm(2,:), eye(4,3), P(:,:,1));
[rightBack3d,reprojectedPoints,errors] = triangulate_DL(shelfBackPts_norm(3,:), shelfBackPts_norm(4,:), eye(4,3), P(:,:,2));

shelfBack3d = zeros(2,3);
shelfBack3d(1,:) = leftBack3d * mean(sf(:,1));
shelfBack3d(2,:) = rightBack3d * mean(sf(:,2));

slotCorners2d = zeros(4,2);
slotCorners2d(1,:) = session_mp.direct.left_bottom_slot_corner;
slotCorners2d(2,:) = session_mp.direct.left_top_slot_corner;
slotCorners2d(3,:) = session_mp.direct.right_bottom_slot_corner;
slotCorners2d(4,:) = session_mp.direct.right_top_slot_corner;

slotPoints = estimateSlotCorners(shelfBack3d, shelfBackPts([1,3],:), slotCorners2d);

end    % function
 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function slotPoints = estimateSlotCorners(shelfBack3d, shelfBack2d, slotCorners2d)

% estimate horizontal distance from left back shelf corner to right back
% shelf corner
shelfLength = shelfBack2d(2,1) - shelfBack2d(1,1);
left_xDiff = slotCorners2d(1,1) - shelfBack2d(1,1);
right_xDiff = slotCorners2d(3,1) - shelfBack2d(1,1);

shelfBack3d_diff = diff(shelfBack3d);

slotPoints = zeros(2,3);
slotPoints(1,:) = shelfBack3d(1,:) + ...
                  (left_xDiff / shelfLength) * shelfBack3d_diff;
slotPoints(2,:) = shelfBack3d(1,:) + ...
                  (right_xDiff / shelfLength) * shelfBack3d_diff;
              
end



    