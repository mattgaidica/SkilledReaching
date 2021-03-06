function [h_fig,h_axes] = plot_max_v_acrossSessions_singleRat(ratSummary,thisRatInfo,varargin)
%
% INPUTS
%   ratSummary
%   thisRatInfo
%
% OUTPUTS
%
occludeRatio=0.5;

switch ratSummary.exptType
    case 'chr2_during'
        laserOnColor = 'b';
        occludeColor = [0 0 1] * occludeRatio;
    case 'chr2_between'
        laserOnColor = 'c';
        occludeColor = [0 0 1] * occludeRatio;
    case 'arch_during'
        laserOnColor = 'g';
        occludeColor = [0 1 0.0] * occludeRatio;
    case 'eyfp_during'
        laserOnColor = 'r';
        occludeColor = [1 0.0 0.0] * occludeRatio;
end
baselineColor = [0 0 0];

full_traj_z_lim = [-5 50];
x_lim = [-30 10];
y_lim = [-20 10];

h_axes = [];

for i_arg = 1 : 2 : nargin - 2
    switch lower(varargin{i_arg})
        case 'h_axes'
            h_axes = varargin{i_arg+1};
            axes(h_axes);
            h_fig = gcf;
        case 'full_traj_z_lim'
            full_traj_z_lim = varargin{i_arg+1};
        case 'x_lim'
            x_lim = varargin{i_arg+1};
        case 'y_lim'
            y_lim = varargin{i_arg+1};
    end
end
if isempty(h_axes)
    h_fig = figure;
    h_axes = gca;
end

numSessions = size(ratSummary.mean_pd_trajectory,1);
pawPref = thisRatInfo.pawPref;
sessions_analyzed = ratSummary.sessions_analyzed;

baseLineSessions = find(sessions_analyzed.trainingStage == 'retraining');
laserOnSessions = find(sessions_analyzed.laserStim == 'on');
occludeSessions = find(sessions_analyzed.laserStim == 'occlude');

scatter(baseLineSessions,ratSummary.mean_pd_v(baseLineSessions,1),'markeredgecolor',baselineColor);
hold on
scatter(laserOnSessions,ratSummary.mean_pd_v(laserOnSessions,1),'markeredgecolor',laserOnColor,'markerfacecolor',laserOnColor);
scatter(occludeSessions,ratSummary.mean_pd_v(occludeSessions,1),'markeredgecolor',laserOnColor);

errorbar(baseLineSessions,ratSummary.mean_pd_v(baseLineSessions,1),ratSummary.std_pd_v(baseLineSessions,1),'linestyle','none');
errorbar(laserOnSessions,ratSummary.mean_pd_v(laserOnSessions,1),ratSummary.std_pd_v(laserOnSessions,1),'linestyle','none');
errorbar(occludeSessions,ratSummary.mean_pd_v(occludeSessions,1),ratSummary.std_pd_v(occludeSessions,1),'linestyle','none');

ylabel('mean max v (mm/s)')
xlabel('session #')
set(gca,'xtick',[1,2,3,12,13,22]);
set(gca,'ylim',[200 1200],'ytick',[200 700 1200]);