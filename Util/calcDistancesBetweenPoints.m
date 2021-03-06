function [distances, pts_idx] = calcDistancesBetweenPoints(points)
%
%
% INPUTS:
%   points - 
%
% OUTPUTS:
%   distances - 
%   pts_idx - 

numPoints = size(points,1);
numDims = size(points,2);
if numPoints == 1
    distances = zeros(1, numDims);
    return;
end

numDistances = sum(1:(numPoints - 1));
distances = zeros(numDistances, 1);
pts_idx   = uint8(zeros(numDistances, 2));
startIdx = 1;
for ii = 1 : numPoints - 1
    
    curPoint = points(ii,:);
    otherPoints = points(ii+1:numPoints, :);
    
    endIdx = sum(numPoints-1 : -1 : numPoints - ii);
    
    numDistForCurPt = endIdx - startIdx + 1;
    pts_idx(startIdx : endIdx,1) = uint8(ones(numDistForCurPt,1) .* ii);
    pts_idx(startIdx : endIdx,2) = uint8(ii+1 : numPoints);
    
    distMatrix = zeros(size(otherPoints));
    for jj = 1 : numDims
        distMatrix(:,jj) = otherPoints(:,jj) - curPoint(jj);
    end
    
    distances(startIdx : endIdx) = sqrt(sum(distMatrix.^2,2));
    startIdx = endIdx + 1;
end
    