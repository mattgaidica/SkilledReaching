function [P1,P2] = cameraMatricesFromCheckerboards(F, boxMarkers, rat_metadata, BG_lft, BG_ctr, BG_rgt, varargin)
%
% usage:
%
% INPUTS:
%
% OUTPUTS:

% THIS DOESN'T SEEM TO BE WORKING - NOT SURE IF I MADE A MISTAKE
% IMPLEMENTING ESTIMATECAMERAPARAMS OR I DON'T HAVE ENOUGH CORRESPONDENCE
% POINTS FROM THE CHECKERBOARD

pawPref = lower(rat_metadata.pawPref);
if iscell(pawPref)
    pawPref = pawPref{1};
end

switch pawPref
    case 'left',
        dMirrorIdx = 3;   % index of mirror with dorsal view of paw
        F_side = boxMarkers.F.right;
        mirrorPoints = boxMarkers.cbLocations.right_mirror_cb;
        centerPoints = boxMarkers.cbLocations.right_center_cb;
    case 'right',
        dMirrorIdx = 1;   % index of mirror with dorsal view of paw
        F_side = boxMarkers.F.left;
        mirrorPoints = boxMarkers.cbLocations.left_mirror_cb;
        centerPoints = boxMarkers.cbLocations.left_center_cb;
end

worldPoints = [00 00
               08 00
               00 08
               08 08];
           
% worldPoints = [00 00
%                08 00
%                16 00
%                00 08
%                08 08
%                16 08
%                00 16
%                08 16
%                16 16];
           
mirrorPoints(:,1) = mirrorPoints(:,1) - boxMarkers.register_ROI(dMirrorIdx,1) + 1;
% flip left/right
mirrorPoints(:,1) = boxMarkers.register_ROI(dMirrorIdx,3) - mirrorPoints(:,1) + 1;
mirrorPoints(:,2) = mirrorPoints(:,2) - boxMarkers.register_ROI(dMirrorIdx,2) + 1;

centerPoints(:,1) = centerPoints(:,1) - boxMarkers.register_ROI(2,1) + 1;
centerPoints(:,2) = centerPoints(:,2) - boxMarkers.register_ROI(2,2) + 1;

% find the top left square corners
[~, sortIdx] = sort(mirrorPoints(:,2));
mirrorPoints = mirrorPoints(sortIdx,:);

[~, sortIdx] = sort(centerPoints(:,2));
centerPoints = centerPoints(sortIdx,:);

mirrorRow = zeros(4,2,4);
centerRow = zeros(4,2,4);
for iRow = 1 : 4
    startIdx = (iRow - 1) * 4 + 1;
    temp = mirrorPoints(startIdx:startIdx + 3, :);
    % now arrange from left to right
    [~,sortIdx] = sort(temp(:,1));
    mirrorRow(:,:,iRow) = temp(sortIdx,:);
    
    temp = centerPoints(startIdx:startIdx + 3, :);
    [~,sortIdx] = sort(temp(:,1));
    centerRow(:,:,iRow) = temp(sortIdx,:);
end

% convert checkerboard corner points into camera view coordinates
imPoints = zeros(4,2,4,2);    % 4 points, 2 coords (x,y), 4 "images", 2 "cameras"

% top row checkerboard
imPoints(1:2,:,1,1) = centerRow(1:2,:,1);   % camera view 1 (direct view)
imPoints(3:4,:,1,1) = centerRow(1:2,:,2);

imPoints(1:2,:,1,2) = mirrorRow(1:2,:,1);   % camera view 2 (mirror view)
imPoints(3:4,:,1,2) = mirrorRow(1:2,:,2);

% middle row checkerboard square
imPoints(1:2,:,2,1) = centerRow(3:4,:,1);   % camera view 1 (direct view)
imPoints(3:4,:,2,1) = centerRow(3:4,:,2);

imPoints(1:2,:,2,2) = mirrorRow(3:4,:,1);   % camera view 2 (mirror view)
imPoints(3:4,:,2,2) = mirrorRow(3:4,:,2);

% bottom left checkerboard square
imPoints(1:2,:,3,1) = centerRow(1:2,:,3);   % camera view 1 (direct view)
imPoints(3:4,:,3,1) = centerRow(1:2,:,4);

imPoints(1:2,:,3,2) = mirrorRow(1:2,:,3);   % camera view 2 (mirror view)
imPoints(3:4,:,3,2) = mirrorRow(1:2,:,4);

% bottom right checkerboard square
imPoints(1:2,:,4,1) = centerRow(3:4,:,3);   % camera view 1 (direct view)
imPoints(3:4,:,4,1) = centerRow(3:4,:,4);

imPoints(1:2,:,4,2) = mirrorRow(3:4,:,3);   % camera view 2 (mirror view)
imPoints(3:4,:,4,2) = mirrorRow(3:4,:,4);

% % left column checkerboard square
% imPoints(2:4:4,:,4,1) = centerRow(2:4,:,2);   % camera view 1 (direct view)
% imPoints(5:8,:,4,1) = centerRow(2:4,:,3);
% 
% imPoints(1:4,:,4,2) = mirrorRow(2:4,:,2);   % camera view 2 (mirror view)
% imPoints(5:8,:,4,2) = mirrorRow(2:4,:,3);


% % top left checkerboard square
% imPoints(1:3,:,1,1) = centerRow(1:3,:,1);   % camera view 1 (direct view)
% imPoints(4:6,:,1,1) = centerRow(1:3,:,2);
% 
% imPoints(1:3,:,1,2) = mirrorRow(1:3,:,1);   % camera view 2 (mirror view)
% imPoints(4:6,:,1,2) = mirrorRow(1:3,:,2);
% 
% % top right checkerboard square
% imPoints(1:3,:,2,1) = centerRow(2:4,:,1);   % camera view 1 (direct view)
% imPoints(4:6,:,2,1) = centerRow(2:4,:,2);
% 
% imPoints(1:3,:,2,2) = mirrorRow(2:4,:,1);   % camera view 2 (mirror view)
% imPoints(4:6,:,2,2) = mirrorRow(2:4,:,2);
% 
% % bottom left checkerboard square
% imPoints(1:3,:,3,1) = centerRow(1:3,:,2);   % camera view 1 (direct view)
% imPoints(4:6,:,3,1) = centerRow(1:3,:,3);
% 
% imPoints(1:3,:,3,2) = mirrorRow(1:3,:,2);   % camera view 2 (mirror view)
% imPoints(4:6,:,3,2) = mirrorRow(1:3,:,3);
% 
% % bottom right checkerboard square
% imPoints(1:3,:,4,1) = centerRow(2:4,:,2);   % camera view 1 (direct view)
% imPoints(4:6,:,4,1) = centerRow(2:4,:,3);
% 
% imPoints(1:3,:,4,2) = mirrorRow(2:4,:,2);   % camera view 2 (mirror view)
% imPoints(4:6,:,4,2) = mirrorRow(2:4,:,3);

[stereoParams, pairsUsed, estimationErrors] = estimateCameraParameters(imPoints, worldPoints);

end
% 
% P1 = [eye(3), zeros(3,1)];
% [stereoParams, pairsUsed, estimationErrors] = estimateCameraParameters(