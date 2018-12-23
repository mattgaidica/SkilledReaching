function firstPawDorsumFrame = findFirstPawDorsumFrame(mirror_p,mirror_bp,paw_through_slot_frame,pawPref,varargin)
%
% INPUTS
%   trajectory - m x 3 x p array, where m is the number of frames, the
%       second dimension is for x,y,z coordinates, and p is the number of
%       bodyparts
%   mirror_p

pThresh = 0.99;   % minimum prob of finding the paw dorsum in the mirror view
min_consec_frames = 5;   % minimum number of consecutive frames in which the paw dorsum must be found in the mirror view
max_consecutive_misses = 50;   % maximum number of consecutive frames for which there could be a gap where the paw isn't visible in the mirror view

for iarg = 1 : 2 : nargin - 4
    switch lower(varargin{iarg})
        case 'pthresh'
            pThresh = varargin{iarg + 1};
        case 'min_consec_frames'
            min_consec_frames = varargin{iarg + 1};
        case 'max_consecutive_misses'
            max_consecutive_misses = varargin{iarg + 1};
    end
end

[~,~,~,mirror_pawdorsum_idx,~,~,~] = group_DLC_bodyparts(mirror_bp,pawPref);

pawDorsum_p = mirror_p(mirror_pawdorsum_idx,1:paw_through_slot_frame)';

% find the first frame before the paw_through_slot_frame where mirror_p >
% pThresh and a valid trajectory point was found (so there must have also
% been at least some points found in the direct view), and this is true for
% at least min_consec_frames frames in a row
% valid3d = ~isnan(trajectory(1:paw_through_slot_frame,1,mirror_pawdorsum_idx));

validPawDorsumIdx = pawDorsum_p > pThresh;% & valid3d;
validPawDorsumBorders = findConsecutiveEntries(validPawDorsumIdx);
if isempty(validPawDorsumBorders)
    firstPawDorsumFrame = paw_through_slot_frame;
    return;
end

% find the last gap in finding the paw dorsum in the mirror that is longer
% than max_consecutive_misses
invalidPawDorsumBorders = findConsecutiveEntries(~validPawDorsumIdx);
if isempty(invalidPawDorsumBorders)
    minPawDorsumFrame = 0;
else
    invalidStreakLengths = invalidPawDorsumBorders(:,2) - invalidPawDorsumBorders(:,1) + 1;
    invalidStreaksEnd = find(invalidStreakLengths > max_consecutive_misses,1,'last');
    if isempty(invalidStreaksEnd)
        minPawDorsumFrame = 0;
    else
        minPawDorsumFrame = invalidPawDorsumBorders(invalidStreaksEnd,2);
    end
end
validPawDorsumBorders = validPawDorsumBorders(validPawDorsumBorders(:,1) > minPawDorsumFrame,:);

if isempty(validPawDorsumBorders)
    firstPawDorsumFrame = paw_through_slot_frame;
    return;
end

streakLengths = validPawDorsumBorders(:,2) - validPawDorsumBorders(:,1) + 1;
streak_idx = find(streakLengths > min_consec_frames,1);

if isempty(streak_idx)
    % this could happen if there aren't enough consecutive frames with a
    % high enough probability of accurately finding the paw dorsum
    firstPawDorsumFrame = paw_through_slot_frame;
    return;
end

firstPawDorsumFrame = validPawDorsumBorders(streak_idx,1);

end