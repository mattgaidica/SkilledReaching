function reprojErrors = calculatePawReprojectionErrors(pawTrajectory, direct_pts, mirror_pts, pawPref, boxCal)

K = boxCal.cameraParams.IntrinsicMatrix;

switch pawPref
    case 'right'
        Pn = squeeze(boxCal.Pn(:,:,2));
        sf = mean(boxCal.scaleFactor(2,:));
    case 'left'
        Pn = squeeze(boxCal.Pn(:,:,3));
        sf = mean(boxCal.scaleFactor(3,:));
end

unscaled_trajectory = pawTrajectory / sf;
pawTrajectory(pawTrajectory==0) = NaN;

% direct_proj = NaN(size(pawTrajectory,1),2,size(pawTrajectory,3));
% mirror_proj = NaN(size(pawTrajectory,1),2,size(pawTrajectory,3));
reprojErrors = zeros(size(pawTrajectory,1),size(pawTrajectory,3),2);
for i_bp = 1 : 16
    current3D = squeeze(unscaled_trajectory(:,:,i_bp));
    direct_proj = projectPoints_DL(current3D, boxCal.P);
    direct_proj = unnormalize_points(direct_proj,K);
    direct_error = direct_proj - squeeze(direct_pts(i_bp,:,:));
    reprojErrors(:,i_bp,1) = sqrt(sum(direct_error.^2,2));
    
    
    mirror_proj = projectPoints_DL(current3D, Pn);
    mirror_proj = unnormalize_points(mirror_pts,K);
    mirror_error = mirror_proj - squeeze(mirror_pts(i_bp,:,:));
    reprojErrors(:,i_bp,2) = sqrt(sum(mirror_error.^2,2));
    
    
end