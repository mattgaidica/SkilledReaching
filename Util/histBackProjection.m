function I_bp = histBackProjection(I, modelHist, binLimits)
%
% usage: 
%
% INPUTS:
%   I - image for which to create the histogram backprojection
%   modelHist - n-dimensional matrix containing histogram values. If n==1,
%       the first backprojected histogram is calculated based on the first
%       channel of I. If n==2, the backprojected histogram is calculated
%       based on the first two channels of I, etc.
%   binLimits - n x m matrix containing the edges of the histogram bins.
%       Each row contains the bin limits for a different channel in image
%       I.
%
% OUTPUTS:
%   I_bp - the backprojected histogram

% make sure modelHist is normalized - IS THIS A GOOD IDEA OR NOT?

n = ndims(modelHist);
if size(binLimits,1) ~= n
    error('binLimits must have n rows, where n is the number of dimensions in modelHist');
end

I_bins = zeros(size(I,1),size(I,2),n);
numBins = size(modelHist, 2);
for iCh = 1 : n
    % subtract each bin limit from the current image channel, find where
    % the sign switches from positive to negative - that tells us which bin
    % for each pixel. I think that can work efficiently
    binFlags = true(size(I,1),size(I,2));
    for ii = 1 : numBins
        temp_bins = zeros(size(I,1),size(I,2));
        binDiffs = I(:,:,iCh) - binLimits(iCh,ii);
        temp_bins(binDiffs < 0 & binFlags) = ii;
        binFlags(binDiffs < 0) = false;
        I_bins(:,:,iCh) = I_bins(:,:,iCh) + temp_bins;
    end
    temp_bins = zeros(size(I,1),size(I,2));
    temp_bins(binFlags) = numBins;
    I_bins(:,:,iCh) = I_bins(:,:,iCh) + temp_bins;
end
    


I_bp = zeros(size(I,1),size(I,2));