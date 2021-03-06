function reprojErrors = calculatePawReprojectionErrors(pawTrajectory, direct_pts, mirror_pts, bodyparts, direct_bp, mirror_bp, pawPref, boxCal, ROIs)
%
% INPUTS:
%   pawTrajectory - numFrames x 3 x numBodyparts array. Each numFramex x 3
%       matrix contains x,y,z points for each bodypart
%   direct_pts, mirror_pts - num_bodyparts x num_frames x 2 matrices
%       containing (x,y) coordinates of each bodypart in each frame
%   bodyparts - cell arrays containing strings describing each bodypart in 
%       the same order as in the pawTrajectory array
%   direct_bp, mirror_bp - cell arrays containing strings describing each
%       bodypart in the same order as the direct_pts, mirror_pts arrays. In
%       general this should match the order for bodyparts/pawTrajectory,
%       but that may not necessarily be true.
%   pawPref - 'right' or 'left'
%   boxCal - box calibration structure with the following fields:
%       .E - essential matrix (3 x 3 x numViews) array where numViews is
%           the number of different mirror views (3 for now)
%       .F - fundamental matrix (3 x 3 x numViews) array where numViews is
%           the number of different mirror views (3 for now)
%       .Pn - camera matrices assuming the direct view is eye(4,3). 4 x 3 x
%           numViews array
%       .P - direct camera matrix (eye(4,3))
%       .cameraParams
%       .curDate - YYYYMMDD format date the data were collected
%   ROIs - 2 x 4 array containing the ROI boundaries of the videos
%       input to DLC (note, these are distorted - prior to undistortion)
%       frames. Each row is [left, top, width, height]. First row for
%       direct view, second row for mirror view relevant to the reaching
%       paw (left mirror for right paw and vice versa)
%
% OUTPUTS:
%   reprojErrors - 

% intrinsic camera calibration matrix in matlab format
K = boxCal.cameraParams.IntrinsicMatrix;

% select the correct Pn (camera matrix) for the appropriate mirror, as well
% as the appropriate scale factor that converts from camera coordinates to
% mm
switch pawPref
    case 'right'
        Pn = squeeze(boxCal.Pn(:,:,2));
        sf = mean(boxCal.scaleFactor(2,:));
    case 'left'
        Pn = squeeze(boxCal.Pn(:,:,3));
        sf = mean(boxCal.scaleFactor(3,:));
end

pawTrajectory(pawTrajectory==0) = NaN;
unscaled_trajectory = pawTrajectory / sf;

numFrames = size(pawTrajectory,1);
num_bp = size(pawTrajectory,3);
reprojErrors = zeros(numFrames,num_bp,2);
for i_bp = 1 : num_bp
    
    bpName = bodyparts{i_bp};
    direct_bp_idx = strcmpi(direct_bp, bpName);
    mirror_bp_idx = strcmpi(mirror_bp, bpName);

    current3D = squeeze(unscaled_trajectory(:,:,i_bp));
    
    % calculate reprojection into the direct view
    direct_proj = projectPoints_DL(current3D, boxCal.P);
    direct_proj = unnormalize_points(direct_proj,K);
    cur_direct_pts = squeeze(direct_pts(direct_bp_idx,:,:)) + ...
        + repmat(ROIs(1,1:2),numFrames,1) - 1;
    cur_direct_pts = undistortPoints(cur_direct_pts, boxCal.cameraParams);
    
    direct_error = direct_proj - cur_direct_pts;
    reprojErrors(:,i_bp,1) = sqrt(sum(direct_error.^2,2));
    
    % calculate reprojection into the mirror view
    mirror_proj = projectPoints_DL(current3D, Pn);
    mirror_proj = unnormalize_points(mirror_proj,K);
    cur_mirror_pts = squeeze(mirror_pts(mirror_bp_idx,:,:)) + ...
        + repmat(ROIs(2,1:2),numFrames,1) - 1;
    cur_mirror_pts = undistortPoints(cur_mirror_pts, boxCal.cameraParams);
    
    mirror_error = mirror_proj - cur_mirror_pts;
    reprojErrors(:,i_bp,2) = sqrt(sum(mirror_error.^2,2)); 
end