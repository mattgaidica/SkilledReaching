function [x1_left,x2_left,x1_right,x2_right,leftMirrorPoints,rightMirrorPoints] = ...
    sr_sessionMatchedPointVector(session_mp, varargin)
%
% usage:
%
% INPUTS:
%
% OUTPUTS:
%   x1_left - points in the direct view that show up in the left mirror
%       view. M x 2 where M is the number of matched points
%   x2_left - points in the left mirror view that correspond to the x1_left
%       matrix (M x 2)
%   x1_right - points in the direct view that show up in the right mirror
%       view. M x 2 where M is the number of matched points
%   x2_right - points in the right mirror view that correspond to the
%       x1_right matrix (M x 2)

excludePoints = {'left_bottom_box_corner','right_bottom_box_corner'};

for iarg = 1 : 2 : nargin - 1
    switch lower(varargin{iarg})
        case 'excludepoints'
            excludePoints = varargin{iarg + 1};
    end
end

% need to find points for which there is both a direct and left point
leftMirrorPoints = {};
leftPointNames = fieldnames(session_mp.leftMirror);
numValidPoints = 0;
x1_left = zeros(1,2);
x2_left = zeros(1,2);
for ii = 1 : length(leftPointNames)
    pointMatch = strcmp(leftPointNames{ii}, excludePoints);
    if any(pointMatch(:)); continue; end

    if any(isnan(session_mp.leftMirror.(leftPointNames{ii})))
        continue;
    end

    % check to see if this point is also valid in the direc view
    if any(isnan(session_mp.direct.(leftPointNames{ii})))
        continue;
    end

    numValidPoints = numValidPoints + 1;
    leftMirrorPoints{numValidPoints} = leftPointNames{ii};
    x1_left(numValidPoints,:) = session_mp.direct.(leftPointNames{ii});
    x2_left(numValidPoints,:) = session_mp.leftMirror.(leftPointNames{ii});
end


rightMirrorPoints = {};
rightPointNames = fieldnames(session_mp.rightMirror);
numValidPoints = 0;
x1_right = zeros(1,2);
x2_right = zeros(1,2);
for ii = 1 : length(rightPointNames)
    pointMatch = strcmp(rightPointNames{ii}, excludePoints);
    if any(pointMatch(:)); continue; end

    if any(isnan(session_mp.rightMirror.(rightPointNames{ii})))
        continue;
    end

    % check to see if this point is also valid in the direc view
    if any(isnan(session_mp.direct.(rightPointNames{ii})))
        continue;
    end

    numValidPoints = numValidPoints + 1;
    rightMirrorPoints{numValidPoints} = rightPointNames{ii};
    x1_right(numValidPoints,:) = session_mp.direct.(rightPointNames{ii});
    x2_right(numValidPoints,:) = session_mp.rightMirror.(rightPointNames{ii});
end
