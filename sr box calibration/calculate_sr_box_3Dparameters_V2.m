function [scale,F,P1,P2,wpts,reproj] = calculate_sr_box_3Dparameters_V2(K,mp,boardSize,varargin)
% V2: changed order of mp array

% usage: 
%
% INPUTS:
%   K - camera intrinsic matrix (matlab format, meaning lower triangular
%       version - Hartley and Zisserman and the rest of the world seem to
%       use the transpose of matlab K)
%   mp - m x 2 x 4 array containing [x,y] pairs of matched points in each
%       view. The third dimension is for:
%           1 - direct view, points visible in left mirror
%           2 - left mirror
%           3 - direct view, points visible in right mirror
%           4 - right mirror
%   boardSize - checkerboard size in [rows, columns]. Assume same sized
%       board is used in the left and right views
%
% OUTPUTS:
%   scale - scale factor by which 3D reconstruction in normalized points
%       must be multiplied to get coordinates in mm w.r.t. to the camera
%       center. 2-element vector; scale(1) is for the left mirror and
%       scale(2) is for the right mirror.
%   F - structure containing fundamental matrices going from direct views
%       to mirror views. Elements are F.left and F.right for the left and
%       right mirrors, respectively
%   P1 - camera matrix for the left mirror
%   P2 - camera matrix for the right mirror
%       NOTE: both camera matrices above assume the direct view camera
%       matrix is eye(4,3)

cb_spacing = 8;   % in mm

for iarg = 1 : 2 : nargin - 3
    switch lower(varargin{iarg})
        case 'cb_spacing'
            cb_spacing = varargin{iarg + 1};
    end
end

% estimate fundamental matrix, exploiting constraints imposed by using
% mirrors
F.left = fundMatrix_mirror(mp(:,:,1), mp(:,:,2));
F.right = fundMatrix_mirror(mp(:,:,3), mp(:,:,4));

% calculate the essential matrix
E.left = K * F.left * K';   % assumption - the intrinsic parameters are the
                            % same for the virtual "mirror" camera as the
                            % real camera
                            % NOTE: this gets confusing with the intrinsic
                            % matrix K. Matlab assumes K is lower
                            % triangular, the Hartley and Zisserman
                            % textbook assumes K is upper triangular. This 
                            % changes the shape of the camera matrices
                            % (4x3 in matlab, 3x4 in H-Z) and the order of 
                            % operations when computing projections
E.right = K * F.right * K';

P = eye(4,3);

[rot,t] = EssentialMatrixToCameraMatrix(E.left);
[cRot,cT,~] = SelectCorrectEssentialCameraMatrix_mirror(...
    rot,t,squeeze(mp(:,:,2))',squeeze(mp(:,:,1))',K');
P1 = [cRot,cT];
P1 = P1';

[rot,t] = EssentialMatrixToCameraMatrix(E.right);
[cRot,cT,~] = SelectCorrectEssentialCameraMatrix_mirror(rot,t,squeeze(mp(:,:,3))',squeeze(mp(:,:,4))',K');
P2 = [cRot,cT];
P2 = P2';

% normalize matched points by K
l_direct_hom  = [mp(:,:,1), ones(size(mp,1),1)];   % need homogeneous coordinates for normalization
l_direct_norm = (K' \ l_direct_hom')';             % normalize by the intrinsics matrix
l_direct_norm = bsxfun(@rdivide,l_direct_norm(:,1:2),l_direct_norm(:,3));

r_direct_hom  = [mp(:,:,3), ones(size(mp,1),1)];
r_direct_norm = (K' \ r_direct_hom')';
r_direct_norm = bsxfun(@rdivide,r_direct_norm(:,1:2),r_direct_norm(:,3));

l_mirror_hom  = [mp(:,:,2), ones(size(mp,1),1)];
l_mirror_norm = (K' \ l_mirror_hom')';
l_mirror_norm = bsxfun(@rdivide,l_mirror_norm(:,1:2),l_mirror_norm(:,3));

r_mirror_hom  = [mp(:,:,4), ones(size(mp,1),1)];
r_mirror_norm = (K' \ r_mirror_hom')';
r_mirror_norm = bsxfun(@rdivide,r_mirror_norm(:,1:2),r_mirror_norm(:,3));

% calculate world points of the checkerboards. This could be expanded later
% if multiple calibration images are taken
[wpts.left, reproj.left]  = triangulate_DL(l_direct_norm, l_mirror_norm, P, P1);
[wpts.right, reproj.right] = triangulate_DL(r_direct_norm, r_mirror_norm, P, P2);

% calculate mean spacing between checkerboard points
[d_horiz_left,d_vert_left] = calc_cb_spacing(wpts.left,boardSize);
[d_horiz_right,d_vert_right] = calc_cb_spacing(wpts.right,boardSize);
d_left = [d_horiz_left;d_vert_left];
d_right = [d_horiz_right;d_vert_right];

% calculate the scale factors based on the average distance between
% checkerboard points in normalized coordinates
scale(1) = cb_spacing / mean(d_left);
scale(2) = cb_spacing / mean(d_right);
