function plot_alternatingStim_summary(alternateKinematics)
%
% exptSummary - types
%   1 - chr2 during
%   2 - chr2 between
%   3 - arch
%   4 - eyfp

markSize = 50;

ratID_of_interest = 216;
date_of_interest = datetime('20180301','inputformat','yyyymmdd');

aperture_lim = [5 20];
zlimit = [-20 15];

saveDir = '/Users/dleventh/Box/Leventhal Lab/Meetings, Presentations/SfN/SFN 2019/Bova/figures';
saveName = 'alternatingStimSummary.pdf';
saveName = fullfile(saveDir,saveName);

figProps.m = 1;
figProps.n = 2;

figProps.topMargin = 0.5;
figProps.leftMargin = 2.5;

figProps.width = 39.01;
figProps.height = 10;

figProps.colSpacing = ones(figProps.n-1,1) * 0.5;
figProps.rowSpacing = 0.5;%ones(figProps.m-1,1) * 1;

figProps.panelWidth = ones(1,figProps.n)*((figProps.width - sum(figProps.colSpacing) - figProps.leftMargin - 0.5) / figProps.n);
figProps.panelHeight = ones(figProps.m,1) * 7;

[h_fig,h_axes] = createFigPanels5(figProps);

patchAlpha = 0.01;

patchX = [5.5 5.5 10.5 10.5];   % will need to change this...
patchX(2,:) = [15.5 15.5 20.5 20.5];
z_patchY = [zlimit(1),zlimit(2),zlimit(2),zlimit(1)];
xlimit = [0 21];
aperture_patchY = [aperture_lim(1),aperture_lim(2),aperture_lim(2),aperture_lim(1)];

n = 0;
RATIDlist = [];
% trials_per_block = size(alternateKinematics(1).on_endAperture,2);
numSessions = length(alternateKinematics);
for iSession = 1 : numSessions
    
    curKinematics = alternateKinematics(iSession);
    if isempty(curKinematics.ratID) || isempty(curKinematics.pd_endPts)
        continue;
    end
    
    sessionDateString = datestr(curKinematics.sessionDate,'yyyymmdd');
    try
    pawPref = curKinematics.thisRatInfo.pawPref;
    catch
        keyboard
    end
    
    ratID = curKinematics.ratID;
    
    if ratID == 197 && ~strcmp(sessionDateString,'20171213')
        continue;  % this is the only valid alternating session for R0197
    end
    
    n = n + 1;
    RATIDlist(n) = curKinematics.ratID;
    
    on_dig2_z = squeeze(curKinematics.on_dig2_endPts(:,:,3));
    off_dig2_z = squeeze(curKinematics.off_dig2_endPts(:,:,3));
    
    if n == 1
        all_on_dig2_z = nanmean(on_dig2_z);
        all_off_dig2_z = nanmean(off_dig2_z);
        
        all_on_aperture = nanmean(curKinematics.on_endAperture);
        all_off_aperture = nanmean(curKinematics.off_endAperture);
    else
        all_on_dig2_z(n,:) = nanmean(on_dig2_z);
        all_off_dig2_z(n,:) = nanmean(off_dig2_z);
        
        all_on_aperture(n,:) = nanmean(curKinematics.on_endAperture);
        all_off_aperture(n,:) = nanmean(curKinematics.off_endAperture);
    end
    
    % to use as the exemplar
    if ratID == 216 && ~strcmp(sessionDateString,'20180301')
        sample_on_dig2_z = all_on_dig2_z(n,:);
        sample_off_dig2_z = all_off_dig2_z(n,:);
        
        sample_on_aperture = all_on_aperture(n,:);
        sample_off_aperture = all_off_aperture(n,:);
        
        sample_std_on_dig2_z = nanstd(on_dig2_z,0,1);
        sample_std_off_dig2_z = nanstd(off_dig2_z,0,1);
        
        sample_std_on_aperture = nanstd(curKinematics.on_endAperture,0,1);
        sample_std_off_aperture = nanstd(curKinematics.off_endAperture,0,1);
        
        numValid_dig2_on = sum(~isnan(on_dig2_z),1);
        numValid_dig2_off = sum(~isnan(off_dig2_z),1);
        
        sample_sem_on_dig2_z = sample_std_on_dig2_z ./ sqrt(numValid_dig2_on);
        sample_sem_off_dig2_z = sample_std_off_dig2_z ./ sqrt(numValid_dig2_off);
        
        numValid_aperture_on = sum(~isnan(curKinematics.on_endAperture),1);
        numValid_aperture_off = sum(~isnan(curKinematics.off_endAperture),1);
        
        sample_sem_on_aperture = sample_std_on_aperture ./ sqrt(numValid_aperture_on);
        sample_sem_off_aperture = sample_std_off_aperture ./ sqrt(numValid_aperture_off);
    end

end

mean_on_dig2_z = nanmean(all_on_dig2_z);
mean_off_dig2_z = nanmean(all_off_dig2_z);

std_on_dig2_z = nanstd(all_on_dig2_z);
std_off_dig2_z = nanstd(all_off_dig2_z);

numValid_on_dig2 = sum(~isnan(all_on_dig2_z));
numValid_off_dig2 = sum(~isnan(all_off_dig2_z));

sem_on_dig2_z = std_on_dig2_z ./ sqrt(numValid_on_dig2);
sem_off_dig2_z = std_off_dig2_z ./ sqrt(numValid_off_dig2);

mean_on_aperture = nanmean(all_on_aperture);
mean_off_aperture = nanmean(all_off_aperture);

std_on_aperture = nanstd(all_on_aperture);
std_off_aperture = nanstd(all_off_aperture);

numValid_on_aperture = sum(~isnan(all_on_aperture));
numValid_off_aperture = sum(~isnan(all_off_aperture));

sem_on_aperture = std_on_aperture ./ sqrt(numValid_on_aperture);
sem_off_aperture = std_off_aperture ./ sqrt(numValid_off_aperture);

% now make the plots
on_idx = [6:10,16:20];
off_idx = [1:5,11:15];

% first, average z
axes(h_axes(1,2))
toPlot = [mean_off_dig2_z,mean_off_dig2_z];
e_bar = [sem_off_dig2_z,sem_off_dig2_z];
scatter(off_idx,toPlot,markSize,'markeredgecolor','b','markerfacecolor','b')
hold on
errorbar(off_idx,toPlot,e_bar,'b','linestyle','none');
toPlot = [mean_on_dig2_z,mean_on_dig2_z];
e_bar = [sem_on_dig2_z,sem_on_dig2_z];
scatter(on_idx,toPlot,markSize,'markeredgecolor','b')
errorbar(on_idx,toPlot,e_bar,'b','linestyle','none');
patch(patchX(1,:),z_patchY,'b','facealpha',patchAlpha);
patch(patchX(2,:),z_patchY,'b','facealpha',patchAlpha);
line([0,21],[0,0],'color','k');
set(gca,'ylim',zlimit,'ytick',[-20:10:10],'fontname','arial','fontsize',18);
set(gca,'xtick',[1,5,6,10,11,15,16,20],'xticklabel',[1,5,1,5,1,5,1,5]);
% set(gca,'xticklabel',[]);
set(gca,'xlim',xlimit);
set(gca,'yticklabel',[]);
xlabel('trial in block','fontname','arial','fontsize',18);

% now the exemplar
axes(h_axes(1,1));
toPlot = [sample_off_dig2_z,sample_off_dig2_z];
e_bar = [sample_sem_off_dig2_z,sample_sem_off_dig2_z];
scatter(off_idx,toPlot,markSize,'markeredgecolor','b','markerfacecolor','b')
hold on
errorbar(off_idx,toPlot,e_bar,'b','linestyle','none');
toPlot = [sample_on_dig2_z,sample_on_dig2_z];
e_bar = [sample_sem_on_dig2_z,sample_sem_on_dig2_z];
scatter(on_idx,toPlot,markSize,'markeredgecolor','b')
errorbar(on_idx,toPlot,e_bar,'b','linestyle','none');
patch(patchX(1,:),z_patchY,'b','facealpha',patchAlpha);
patch(patchX(2,:),z_patchY,'b','facealpha',patchAlpha);
line([0,21],[0,0],'color','k');
set(gca,'ylim',zlimit,'ytick',[-20:10:10],'fontname','arial','fontsize',18);
set(gca,'xtick',[1,5,6,10,11,15,16,20],'xticklabel',[1,5,1,5,1,5,1,5]);
% set(gca,'xticklabel',[]);
set(gca,'xlim',xlimit);
xlabel('trial in block','fontname','arial','fontsize',18);
ylabel('z (mm)')
% 
% % first, average aperture
% axes(h_axes(2,2))
% toPlot = [mean_off_aperture,mean_off_aperture];
% e_bar = [sem_off_aperture,sem_off_aperture];
% scatter(off_idx,toPlot,markSize,'markeredgecolor','b','markerfacecolor','b')
% hold on
% errorbar(off_idx,toPlot,e_bar,'b','linestyle','none');
% toPlot = [mean_on_aperture,mean_on_aperture];
% e_bar = [sem_on_aperture,sem_on_aperture];
% scatter(on_idx,toPlot,markSize,'markeredgecolor','b')
% errorbar(on_idx,toPlot,e_bar,'b','linestyle','none');
% patch(patchX(1,:),aperture_patchY,'b','facealpha',patchAlpha);
% patch(patchX(2,:),aperture_patchY,'b','facealpha',patchAlpha);
% set(gca,'ylim',aperture_lim,'ytick',[-20:10:10],'fontname','arial','fontsize',18);
% set(gca,'xtick',[1,5,6,10,11,15,16,20],'xticklabel',[1,5,1,5,1,5,1,5]);
% set(gca,'xlim',xlimit);
% set(gca,'yticklabel',[]);
% 
% % now the exemplar
% axes(h_axes(2,1));
% toPlot = [sample_off_aperture,sample_off_aperture];
% e_bar = [sample_sem_off_aperture,sample_sem_off_aperture];
% scatter(off_idx,toPlot,markSize,'markeredgecolor','b','markerfacecolor','b')
% hold on
% errorbar(off_idx,toPlot,e_bar,'b','linestyle','none');
% toPlot = [sample_on_aperture,sample_on_aperture];
% e_bar = [sample_sem_on_aperture,sample_sem_on_aperture];
% scatter(on_idx,toPlot,markSize,'markeredgecolor','b')
% errorbar(on_idx,toPlot,e_bar,'b','linestyle','none');
% patch(patchX(1,:),aperture_patchY,'b','facealpha',patchAlpha);
% patch(patchX(2,:),aperture_patchY,'b','facealpha',patchAlpha);
% line([1,20],[0,0],'color','k');
% set(gca,'ylim',aperture_lim,'ytick',[-20:10:10],'fontname','arial','fontsize',18);
% set(gca,'xtick',[1,5,6,10,11,15,16,20],'xticklabel',[1,5,1,5,1,5,1,5]);
% set(gca,'xlim',xlimit);
% ylabel('aperture (mm)')

print(h_fig,saveName,'-dpdf');