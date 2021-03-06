function [cb_pts, boardSize, varargout] = detect_SR_checkerboard(I, varargin)
%
% usage: 
%
% INPUTS:
%
% OUTPUTS:
%
blackThresh = 60;
whiteThresh = 170;
areaLimits  = [1500 3500];
minExtent   = 0.8;
eccLimits   = [0 1];
maxCentroidSeparation = 90;
maxVertexSeparation = 10;    % for finding points that really represent the same vertex
pointsPerRow = 4;

for iarg = 1 : 2 : nargin - 1
    switch lower(varargin{iarg})
        case 'blackthresh',
            blackThresh = varargin{iarg + 1};
        case 'whitethresh',
            whiteThresh = varargin{iarg + 1};
        case 'arealimits',
            areaLimits = varargin{iarg + 1};
        case 'pointsperrow',
            pointsPerRow = varargin{iarg + 1};
    end
end

squareBlob = vision.BlobAnalysis;
squareBlob.AreaOutputPort = true;
squareBlob.CentroidOutputPort = true;
squareBlob.BoundingBoxOutputPort = true;
squareBlob.EccentricityOutputPort = true;
squareBlob.ExtentOutputPort = true;
squareBlob.LabelMatrixOutputPort = true;
squareBlob.MinimumBlobArea = areaLimits(1);   % eliminate everything that is too small
squareBlob.MaximumBlobArea = areaLimits(2);   % or too big

gray_I = rgb2gray(I);
% first, find the outline of the checkerboard
% threshold to find the black squares
blackSquareMask = gray_I < blackThresh;
blackSquareMask = isolateSquares(blackSquareMask, squareBlob, minExtent, eccLimits);

% find the minimum quadrilateral that will bound the black squares
[a,b] = minBlobsQuad(blackSquareMask);
[c,d] = outline_cb(a,b);
bordersMask = poly2mask(c,d,size(gray_I,1),size(gray_I,2));

% now, identify white squares, but only those squares within bordersMask
whiteSquareMask = gray_I > whiteThresh & bordersMask;
whiteSquareMask = isolateSquares(whiteSquareMask, squareBlob, minExtent, eccLimits);
squareMask = whiteSquareMask | blackSquareMask;

% find minimum bounding qudrilaterals around each square, and that should
% give us our checkerboard corners for point matching
[qx,qy] = minBlobsQuad(squareMask);
qx = qx(:);qy = qy(:);
vtx = unique([qx,qy],'rows');

% now find points that really represent the same vertex and average them
diffMatrix = zeros(size(vtx,1)-1,size(vtx,2));

for ii = 1 : size(vtx,1)
    ctrPoint = vtx(ii,:);
    switch ii
        case 1,
            otherPoints = vtx(ii+1:end,:);
        case size(vtx,1),
            otherPoints = vtx(1:end-1,:);
        otherwise,
            otherPoints = [vtx(1:ii-1,:);vtx(ii+1:end,:)];   
    end
    for jj = 1 : size(vtx,2)
        diffMatrix(:,jj) = ctrPoint(jj) - otherPoints(:,jj);
    end
    distances = sqrt(sum(diffMatrix.^2, 2));
    distIdx = find(distances < maxVertexSeparation);
    distIdx(distIdx >= ii) = distIdx(distIdx >= ii) + 1;
    distIdx = [distIdx; ii];
    if ii == 1
        cb_pts = mean(vtx(distIdx,:),1);
    else
        cb_pts = [cb_pts;mean(vtx(distIdx,:),1)];
    end
end
cb_pts = round(cb_pts * 1e4)/1e4;    % get rid of rounding errors past 10^-4
cb_pts = unique(cb_pts,'rows');

% sort checkerboard points so they go from top left to bottom right, moving
% from left to right then top to bottom
% first, sort along the y-axis
[~, idx] = sort(cb_pts(:,2));
cb_pts = cb_pts(idx,:);
% sort the points in each block of pointsPerRow points
numRows = size(cb_pts,1) / pointsPerRow;
if numRows ~= round(numRows)
    disp('different numbers of points in each row, unable to sort');
    return;
end

for iRow = 1 : numRows
    startIdx = (iRow-1)*pointsPerRow + 1;
    endIdx   = iRow*pointsPerRow;
    tempPts  = cb_pts(startIdx:endIdx,:);
    [~, idx] = sort(tempPts(:,1),1);
    tempPts = tempPts(idx,:);
    cb_pts(startIdx:endIdx,:) = tempPts;
end

numRows = size(cb_pts,1) / pointsPerRow;
boardSize = [numRows, pointsPerRow];

end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function squareMask = isolateSquares(mask, squareBlob, minExtent, eccLimits)


maxCentroidSeparation = 90;
maxVertexSeparation = 10;    % for finding points that really represent the same vertex
pointsPerRow = 4;

SE = strel('disk',2);
squareMask = imopen(mask,SE);
squareMask = imclose(squareMask,SE);
squareMask = imfill(squareMask,'holes');

% check that the extent (area/area of bounding box)of each region is
% large enough
[~,~, ~, ~,sq_extent,squareLabelMatrix] = step(squareBlob,squareMask);
validExtentIdx = find(sq_extent > minExtent);
squareMask = false(size(mask));
for ii = 1 : length(validExtentIdx)
    squareMask = squareMask | (squareLabelMatrix == validExtentIdx(ii));
end

% check that the eccentricity is in the appropriate range. Excludes, for
% example, vertical or horizontal lines that might not be captured by the
% Extent constraint above
[~,~, ~, sq_ecc,~,squareLabelMatrix] = step(squareBlob,squareMask);
validEccentricityIdx = find(sq_ecc > eccLimits(1) & sq_ecc < eccLimits(2));
squareMask = false(size(mask));
for ii = 1 : length(validEccentricityIdx)
    squareMask = squareMask | (squareLabelMatrix == validEccentricityIdx(ii));
end

% now, throw out blobs that are too far away from the other blobs
[~,sq_cent,~,~,~,squareLabelMatrix] = step(squareBlob,squareMask);
[nn,~,~] = nearestNeighbor(sq_cent);
validDistanceIdx = find(nn < maxCentroidSeparation);
squareMask = false(size(mask));
for ii = 1 : length(validDistanceIdx)
    squareMask = squareMask | (squareLabelMatrix == validDistanceIdx(ii));
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [qx,qy] = minWholeMaskQuad(mask)

props = regionprops(mask,'convexhull');
hullPoints = props(1).ConvexHull;
for ii = 2 : length(props)
    hullPoints = [hullPoints;props(ii).ConvexHull];
end
[qx,qy,~] = minboundquad(hullPoints(:,1),hullPoints(:,2));

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [qx,qy] = minBlobsQuad(mask)

props = regionprops(mask,'convexhull');
qx = zeros(length(props),5);qy = zeros(length(props),5);
for ii = 1 : length(props)
    [qx(ii,:), qy(ii,:), ~] = minboundquad(props(ii).ConvexHull(:,1),props(ii).ConvexHull(:,2));
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [qx,qy] = outline_cb(x,y)
% x and y are n x 5 matrices containing x,y coordinates of vertices for
% each individual square

temp = x(:,1:4);
x_lin = temp(:);
temp = y(:,1:4);
y_lin = temp(:);
if size(x,1) == 4
    [qx,qy] = quad_from_edge_center_squares(x_lin,y_lin);
elseif size(x,1) == 5
    [qx,qy] = quad_from_corner_squares(x_lin,y_lin);
end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [qx,qy] = quad_from_edge_center_squares(x,y)

% find the two topmost and bottom-most points
[~,idx] = sort(y);
x_top = x(idx(1:2));
y_top = y(idx(1:2));

x_bot = x(idx(end-1:end));
y_bot = y(idx(end-1:end));

% find the two left- and right-most points
[~,idx] = sort(x);
x_left = x(idx(1:2));
y_left = y(idx(1:2));

x_right = x(idx(end-1:end));
y_right = y(idx(end-1:end));

% find intersections
m_top = diff(y_top) / diff(x_top);
m_bot = diff(y_bot) / diff(x_bot);
m_left = diff(y_left) / diff(x_left);
m_right = diff(y_right) / diff(x_right);

b_top = y_top(1) - m_top*x_top(1);
b_bot = y_bot(1) - m_bot*x_bot(1);
b_left = y_left(1) - m_left*x_left(1);
b_right = y_right(1) - m_right*x_right(1);

% top left corner
qx = zeros(1,5);qy = zeros(1,5);
qx(1) = (b_left - b_top) / (m_top - m_left);
if isnan(qx(1))   % left slope is infinite
    qx(1) = x_left(1);
end
qy(1) = m_top * qx(1) + b_top;
qx(5) = qx(1);
qy(5) = qy(1);

% top right corner
qx(2) = (b_right - b_top) / (m_top - m_right);
if isnan(qx(2))   % right slope is infinite
    qx(2) = x_right(1);
end
qy(2) = m_top * qx(2) + b_top;

% bottom right corner
qx(3) = (b_right - b_bot) / (m_bot - m_right);
if isnan(qx(3))   % right slope is infinite
    qx(3) = x_right(1);
end
qy(3) = m_bot * qx(3) + b_bot;

% bottom left corner
qx(4) = (b_left - b_bot) / (m_bot - m_left);
if isnan(qx(4))   % left slope is infinite
    qx(4) = x_left(1);
end
qy(4) = m_bot * qx(4) + b_bot;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function [qx,qy] = quad_from_corner_squares(x,y)

% find the leftmost points, and pick out the top and bottom ones
[~,idx] = sort(x);
left_x  = x(idx(1:4));
right_x = x(idx(end-3:end));
left_y  = y(idx(1:4));
right_y = y(idx(end-3:end));

% find top left point
[~,idx] = sort(left_y);
qx(1) = left_x(idx(1));
qx(5) = qx(1);
qy(1) = left_y(idx(1));
qy(5) = qy(1);

% bottom left point
qx(4) = left_x(idx(end));
qy(4) = left_y(idx(end));

% top right point
[~,idx] = sort(right_y);
qx(2) = right_x(idx(1));
qy(2) = right_y(idx(1));

% bottom right point
qx(3) = right_x(idx(end));
qy(3) = right_y(idx(end));

end