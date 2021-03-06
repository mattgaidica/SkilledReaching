function newBoardPts = detectMatchingCheckerboard(img, epiPt, ROI, knownPts)

num_points = size(knownPts,1);
linePoints = zeros(2,2);
linePoints(1,:) = epiPt;

h = size(img,1);
w = size(img,2);

img_eq = adapthisteq(rgb2gray(img));
for i_pt = 1 : num_points
    
    % create a line between the epipole and the current point
    linePoints(2,:) = knownPts(i_pt,:);
    testLine = lineCoeffFromPoints(linePoints);
    
    pts = lineToBorderPoints(testLine,[h,w]);
end