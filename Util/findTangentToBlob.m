function [tanPts,tanLines] = findTangentToBlob(blobMask, pivotPt)

mask_ext = bwmorph(blobMask,'remove');
s = regionprops(mask_ext,'Centroid');

[y,x] = find(mask_ext);
num_pts = length(x);

ext_pts = sortClockWise(s.Centroid,[x,y]);

tanPts = zeros(2,2);
tanLines  = zeros(2,3);

tangentPointsFound = 0;
for ii = 1 : num_pts
    
    lineCoeff = lineCoeffFromPoints([pivotPt;ext_pts(ii,:)]);
    
	lineValue = lineCoeff(1) * ext_pts(:,1) + ...
                lineCoeff(2) * ext_pts(:,2) + lineCoeff(3);
            
    intersect_idx = detectZeroCrossings(lineValue);
    
    if length(intersect_idx) == 1
        tangentPointsFound = tangentPointsFound + 1;
        
        tanPts(tangentPointsFound,:) = ext_pts(ii,:);
        tanLines(tangentPointsFound,:) = lineCoeff;
    end
end

while tangentPointsFound > 2
    % more than one edge point lies on one of the tangent epipolar lines
    % find the ones that are redundant and get rid of them
    
    linesDiff = diff(tanLines,1);
    linesDist = sqrt(sum(linesDiff.^2,2));
    
    minDistIdx = find(linesDist == min(linesDist));
    
    tanLines = removeRow(tanLines, minDistIdx);
    tanPts = removeRow(tanPts, minDistIdx);
    
    tangentPointsFound = tangentPointsFound - 1;
end