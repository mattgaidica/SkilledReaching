function HSVdist = calcHSVdist(im_hsv, targetVal)
%
%   calculate the distance in hsv color space between each pixel in an hsv
%   image and targetVal (absolute values)
%
% INPUTS
%   im_hsv = image in hsv color space
%   targetVal - hsv triple
%
% OUTPUTS
%   HSVdist - h x w x 3 array containing the distance from each pixel in
%       im_hsv to targetVal in HSV space

HSVdist = zeros(size(im_hsv));

HSVdist(:,:,1) = circDiff(im_hsv(:,:,1),targetVal(1),0,1);

for iDim = 2 : 3
    HSVdist(:,:,iDim) = abs(im_hsv(:,:,iDim) - targetVal(iDim));
end