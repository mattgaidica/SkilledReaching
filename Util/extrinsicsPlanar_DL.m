function [R_final,T_final] = extrinsicsPlanar_DL(imagePoints, worldPoints, intrinsics)
% copied from matlab toolbox so I can see where things seem to be going
% wrong...

A = intrinsics';

% Compute homography.
H = fitgeotrans(worldPoints, imagePoints, 'projective');
H = H.T';
h1 = H(:, 1);
h2 = H(:, 2);
h3 = H(:, 3);

% lambda1 = 1 / norm(A \ h1);
% lambda2 = 1 / norm(A \ h2);
% lambda = mean([lambda1,lambda2]);

lambda = 1 / norm(A \ h2);

% Compute rotation
r1 = A \ (lambda * h1);
r2 = A \ (lambda * h2);
r3 = cross(r1, r2);
R_init = [r1'; r2'; r3'];

% R may not be a true rotation matrix because of noise in the data.
% Find the best rotation matrix to approximate R using SVD.
[U, ~, V] = svd(R_init);
R_init = U * V';

% Compute translation vector.
T_init = (A \ (lambda * h3))';

initParams = [R_init(:,1)',R_init(:,2)',R_init(:,3)',T_init];
% P = [R;T]*A'; % calculation of camera matrix
finalParams = refine_extrinsics(initParams, A, worldPoints, imagePoints);

R_final = [finalParams(1:3)',finalParams(4:6)',finalParams(7:9)'];
T_final = finalParams(10:12);
        
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function finalParams = refine_extrinsics(initParams, K, worldPoints, imPts)
%
% paramsVector - 
% [R11...R13,R21...R23,R31...R33, T1...T3, worldPoints]
               
worldPoints_hom = [worldPoints,ones(size(worldPoints,1),1)];
options = optimoptions('lsqnonlin','display','off','algorithm','levenberg-marquardt');
finalParams = lsqnonlin(@reprojectPoints,initParams,[],[],options);

    function reprojErrors = reprojectPoints(initParams)
        R = [initParams(1:3)',initParams(4:6)',initParams(7:9)'];
        T = initParams(10:12);

        reprojPointsHomog = worldPoints_hom * (K * [R(1,:)', R(2, :)', T'])';

        reprojectedPoints = bsxfun(@rdivide, reprojPointsHomog(:, 1:2), reprojPointsHomog(:,3));
        
        reprojErrors = reprojectedPoints - imPts;
        
    end

end