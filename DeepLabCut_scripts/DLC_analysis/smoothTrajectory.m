function [normalized_trajectory,interp_trajectory,smoothed_trajectory] = smoothTrajectory(rawTrajectory,varargin)
% function smoothed_trajectory = smoothTrajectory(rawTrajectory,trialEstimate,varargin)
%
% INPUTS
%   rawTrajectory - m x 3 array where each row m is the number of frames 
%       and each row is an (x,y,z) triple
%
% OUTPUTS
%
%

smoothWindow = 3;
numTrajectoryPoints = 100;

for iarg = 1 : 2 : nargin - 1
    switch lower(varargin{iarg})
        case 'numtrajectorypoints'
            numTrajectoryPoints = varargin{iarg + 1};
        case 'smoothwindow'
            smoothWindow = varargin{iarg + 1};
    end
end

% step1 = zeros(size(rawTrajectory));
% spline_interp = zeros(size(rawTrajectory));

% clip rawTrajectory to remove any NaN's from the beginning or end of the
% trajectory. This can be a problem especially for trials where the paw
% doesn't completely break through the reaching slot.
if isnan(rawTrajectory(1,1))
    firstValidFrame = find(~isnan(rawTrajectory(:,1)),1);
    rawTrajectory = rawTrajectory(firstValidFrame:end,:);
end
if isnan(rawTrajectory(end,1))
    lastValidFrame = find(~isnan(rawTrajectory(:,1)),1,'last');
    rawTrajectory = rawTrajectory(1:lastValidFrame,:);
end
interp_trajectory = zeros(size(rawTrajectory));
smoothed_trajectory = zeros(size(rawTrajectory));
num_x = size(rawTrajectory,1);
% temp = zeros(size(rawTrajectory));
% numFrames = size(rawTrajectory,1);
% isEstimate = trialEstimate(:,1) | trialEstimate(:,2);   % left over from
% trying to weight estimates
% w = ones(numFrames,1);
% w(isEstimate) = 0.2;
for iDim = 1 : size(rawTrajectory,2)
%     step1(:,iDim) = smooth(rawTrajectory(:,iDim),'rlowess');
%     spline_interp(:,iDim) = spline(1:num_x,rawTrajectory(:,iDim),1:num_x);
    interp_trajectory(:,iDim) = pchip(1:num_x,rawTrajectory(:,iDim),1:num_x);
    smoothed_trajectory(:,iDim) = smooth(interp_trajectory(:,iDim),smoothWindow);
%     temp(:,iDim) = csaps(1:numFrames,rawTrajectory(:,iDim),[],1:numFrames,w);
end

normalized_trajectory = evenlySpacedPointsAlongTrajectory(smoothed_trajectory,numTrajectoryPoints);

% temp2 = evenlySpacedPointsAlongTrajectory(temp,numTrajectoryPoints);

% figure
% for ii = 1 : 3
%     subplot(3,1,ii)
%     plot(smoothed_trajectory(:,ii))
%     hold on
%     plot(temp2(:,ii))
% %     scatter(rawTrajectory(:,1))
% end
% 
% figure
% plot3(smoothed_trajectory(:,1),smoothed_trajectory(:,3),smoothed_trajectory(:,2))
% hold on
% plot3(temp2(:,1),temp2(:,3),temp2(:,2))
% scatter3(rawTrajectory(:,1),rawTrajectory(:,3),rawTrajectory(:,2))



% MAYBE THERE'S SOME FANCY STUFF STILL TO DO FOR INTERPOLATING...WE'LL SEE
end