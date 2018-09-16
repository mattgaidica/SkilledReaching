function directPawOrientation = determineDirectPawOrientation(direct_pts,direct_bp,direct_p,pawPref)
%
% function to determine the angle of the paw in the direct view with
% respect to horizontal (vertical?)

[invalidPoints,diff_per_frame] = find_invalid_DLC_points(direct_pts, direct_p);
% hard code strings that only occur in bodyparts that are part of the
% reaching paw
[mcpIdx,pipIdx,digIdx,pawDorsumIdx] = findReachingPawParts(direct_bp,pawPref);

% calculate paw orientation at each time point based on mcp, pip, and digit
% markers
numFrames = size(direct_pts,2);
mcpAngle = NaN(numFrames,1);
pipAngle = NaN(numFrames,1);
digitAngle = NaN(numFrames,1);

farthestMCPidx = NaN(numFrames,2);
farthestPIPidx = NaN(numFrames,2);
farthestDIGidx = NaN(numFrames,2);
for iFrame = 1 : numFrames
    
    % find valid mcp points in this frame, if there are any
    farthestMCPidx(iFrame,:) = findFarthestDigits(mcpIdx,~invalidPoints(:,iFrame));
    if all(farthestMCPidx(iFrame,:) > 0)
        MCPpts = squeeze(direct_pts(farthestMCPidx(iFrame,:),iFrame,:));
        
        % need to define what positive angles are for left vs right paws
        mcpAngle(iFrame) = pointsAngle(MCPpts);
    end

end

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function ptsIdx = findFarthestDigits(digitIdx,validPoints)
%
% INPUTS:
%   digIdx = indices of digits in the bodyparts array in order
%   validPoints = boolean vector indicating which bodyparts were reliably
%       identified (logical NOT of invalidPoints)

ptsIdx = zeros(1,2);
validDigIdx = validPoints(digitIdx);

if sum(validDigIdx) < 2
    % not enough points to determine an angle
    ptsIdx = [0,0];
end

ptsIdx(1) = digitIdx(find(validDigIdx,1,'first'));
ptsIdx(2) = digitIdx(find(validDigIdx,1,'last'));
    
end