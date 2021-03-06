function possObscured = couldObjectsBeObscured(masks, fundmat, bbox, imSize, isDirectView)
%
% function to determine if the blob in mask1 might be partially obscured by
% mask2 in the mirror (or direct) view, and vice-versa
%
% INPUTS:
%   masks - mxnx2 boolean array, where m is the number of rows, n is the
%       number of columns in each masking image
%   fundmat
%   bbox
%   imSize
%   isDirectView - boolean indicating whether the masks come from the
%       direct view (true) or mirror view (false)
%
% OUTPUTS:
%   possObscured - 1x2 vector of booleans where each element indicates
%       whether the mask with the same index COULD BE obscured by the
%       object represented by the other mask in the other (mirror vs
%       direct) view

possObscured = false(1,2);

tangentPoints = zeros(2,2,2);    % mxnxp where m is number of points, n is (x,y), p is the view index (1 for direct, 2 for mirror)
tangentLines = zeros(2,3,2);     % mxnxp where m is number of points, n is (A,B,C), p is the view index (1 for direct, 2 for mirror)
fullMasks = false(imSize(1),imSize(2),2);

edge_y = zeros(2,2);
maskProjection = zeros(imSize(1),imSize(2),2);

[~,epipole] = isEpipoleInImage(fundmat, imSize);

if epipole(1) < 0 % && isDirectView  % mirror is on the left
	edge_x = 1; 
else
    edge_x = imSize(2);
end

for iMask = 1 : 2
    fullMasks(bbox(2):bbox(2)+bbox(4),bbox(1):bbox(1)+bbox(3),iMask) = masks(:,:,iMask);
end

for iMask = 1 : 2
    [tangentPoints(:,:,iMask), tangentLines(:,:,iMask)] = findTangentToEpipolarLine(masks(:,:,iMask), fundmat, bbox);

    for iLine = 1 : 2
        edge_y(iLine,iMask) = (-tangentLines(iLine,3,iMask) - tangentLines(iLine,1,iMask)*edge_x) / ...
                                tangentLines(iLine,2,iMask);
    end
    
    proj_x = [edge_x, edge_x, tangentPoints(1,1,iMask), tangentPoints(2,1,iMask), edge_x];
    proj_y = [edge_y(2), edge_y(1), tangentPoints(1,2,iMask), tangentPoints(2,2,iMask), edge_y(2)];
    maskProjection(:,:,iMask) = poly2mask(proj_x,proj_y,imSize(1),imSize(2));
    
    overlapMask = maskProjection(:,:,iMask) & fullMasks(:,:,3-iMask);
    possObscured(iMask) = any(overlapMask(:));
end    