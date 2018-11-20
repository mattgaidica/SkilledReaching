function [final_direct_pts,final_mirror_pts,isEstimate] = estimateHiddenPoints(direct_pts, mirror_pts, direct_p, mirror_p, direct_bp, mirror_bp, boxCal, ROIs, imSize, pawPref)

switch pawPref
    case 'right'
        F = squeeze(boxCal.F(:,:,2));
    case 'left'
        F = squeeze(boxCal.F(:,:,3));
end

numFrames = size(direct_pts,2);

[direct_mcp_idx,direct_pip_idx,direct_digit_idx,direct_pawdorsum_idx,~,~,~] = group_DLC_bodyparts(direct_bp,pawPref);
[mirror_mcp_idx,mirror_pip_idx,mirror_digit_idx,mirror_pawdorsum_idx,~,~,~] = group_DLC_bodyparts(mirror_bp,pawPref);
% can work on the other body parts later; for now, just concerned with the
% reaching paw

numPawParts = length(direct_mcp_idx) + length(direct_pip_idx) + length(direct_digit_idx) + length(direct_pawdorsum_idx);

invalid_direct = find_invalid_DLC_points(direct_pts, direct_p);
invalid_mirror = find_invalid_DLC_points(mirror_pts, mirror_p);
isEstimate = false(size(direct_pts,1),size(direct_pts,2),2);

final_direct_pts = reconstructUndistortedPoints(direct_pts,ROIs(1,:),boxCal.cameraParams);
final_mirror_pts = reconstructUndistortedPoints(mirror_pts,ROIs(2,:),boxCal.cameraParams);

for iFrame = 1 : numFrames
    
    for i_pawPart = 1 : numPawParts
        
        direct_part_idx = 
        
        
        
    end
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function points_ud = reconstructUndistortedPoints(pts,ROI,cameraParams)

points_ud = zeros(size(pts));
for i_coord = 1 : 2
    points_ud(:,:,i_coord) = pts(:,:,i_coord) + ROI(i_coord) - 1;
end

for i_part = 1 : size(points_ud,1)
    points_ud(i_part,:,:) = undistortPoints(squeeze(points_ud(i_part,:,:)),cameraParams);
end