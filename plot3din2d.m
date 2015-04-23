function plot3din2d(folderPathBefore,folderPathAfter)

startFrame = 50;
plotFrames = 150;

figure('position',[400 400 800 800]);
subplot(221); title('Before & Miss / Before & Success'); hold on;
subplot(222); title('After & Miss / After & Success'); hold on;
subplot(223); title('Before & Miss / After & Miss'); hold on;
subplot(224); title('Before & Success / After & Success'); hold on;

xfiltsSuccess = [];
yfiltsSuccess = [];
zfiltsSuccess = [];

xfiltsMiss = [];
yfiltsMiss = [];
zfiltsMiss = [];

for iFolder=1:2
    if(iFolder==1)
        folderPath = folderPathBefore;
    else
        folderPath = folderPathAfter;
    end
    scoreLookup = dir(fullfile(folderPath,'*.csv'));
    scoreData = csvread(fullfile(folderPath,scoreLookup(1).name));
    matLookup = dir(fullfile(folderPath,'_xyzData','*.mat'));
    load(fullfile(folderPath,'_xyzData',matLookup(1).name));
    
    for iTrial=1:numel(allAlignedXyzPawCenters)
        alignedXyzPawCenters = allAlignedXyzPawCenters{iTrial};
        if(size(alignedXyzPawCenters,1) > 5) %why are some [NaN NaN Nan] and others empty?
            xfilt = medfilt1(alignedXyzPawCenters(startFrame:plotFrames,1),2);
            xfilt = smoothn(xfilt,2,'robust');
            yfilt = medfilt1(alignedXyzPawCenters(startFrame:plotFrames,2),2);
            yfilt = smoothn(yfilt,2,'robust');
            zfilt = medfilt1(alignedXyzPawCenters(startFrame:plotFrames,3),2);
            zfilt = smoothn(zfilt,2,'robust');

            if(ismember(scoreData(iTrial,2),[1,2,3,4,7]))
                switch(scoreData(iTrial,2))
                    case 1
                        if(iFolder==1)
                            subplot(221);
                            patchline(xfilt,yfilt,'edgecolor',[67/360 179/360 225/360],'linewidth',1,'edgealpha',0.1);
                            subplot(224);
                            patchline(xfilt,yfilt,'edgecolor',[67/360 179/360 225/360],'linewidth',1,'edgealpha',0.1);
                        else
                            subplot(222);
                            patchline(xfilt,yfilt,'edgecolor',[67/360 179/360 225/360],'linewidth',1,'edgealpha',0.1);
                            subplot(224);
                            patchline(xfilt,yfilt,'edgecolor',[67/360 179/360 225/360],'linewidth',1,'edgealpha',0.1);
                        end
                        xfiltsSuccess = [xfiltsSuccess;xfilt'];
                        yfiltsSuccess = [yfiltsSuccess;yfilt'];
                        zfiltsSuccess = [zfiltsSuccess;zfilt'];
                    case {2,3,4,7}
                        if(iFolder==1)
                            subplot(221);
                            patchline(xfilt,yfilt,'edgecolor',[225/360 67/360 67/360],'linewidth',1,'edgealpha',0.1);
                            subplot(223);
                            patchline(xfilt,yfilt,'edgecolor',[225/360 67/360 67/360],'linewidth',1,'edgealpha',0.1);
                        else
                            subplot(222);
                            patchline(xfilt,yfilt,'edgecolor',[252/360 12/360 12/360],'linewidth',1,'edgealpha',0.1);
                            subplot(223);
                            patchline(xfilt,yfilt,'edgecolor',[252/360 12/360 12/360],'linewidth',1,'edgealpha',0.1);
                        end
                        xfiltsMiss = [xfiltsMiss;xfilt'];
                        yfiltsMiss = [yfiltsMiss;yfilt'];
                        zfiltsMiss = [zfiltsMiss;zfilt'];
                end
            end

        end
    end
    if(iFolder==1)
        subplot(221);
        patchline(mean(xfiltsSuccess),mean(yfiltsSuccess),'edgecolor',[67/360 179/360 225/360],'linewidth',3,'edgealpha',1);
        subplot(221);
        patchline(mean(xfiltsMiss),mean(yfiltsMiss),'edgecolor',[225/360 67/360 67/360],'linewidth',3,'edgealpha',1);
        subplot(223);
        patchline(mean(xfiltsMiss),mean(yfiltsMiss),'edgecolor',[225/360 67/360 67/360],'linewidth',3,'edgealpha',1);
        subplot(224);
        patchline(mean(xfiltsSuccess),mean(yfiltsSuccess),'edgecolor',[67/360 179/360 225/360],'linewidth',3,'edgealpha',1);
    else
        subplot(222);
        patchline(mean(xfiltsSuccess),mean(yfiltsSuccess),'edgecolor',[67/360 179/360 225/360],'linewidth',3,'edgealpha',1);
        subplot(222);
        patchline(mean(xfiltsMiss),mean(yfiltsMiss),'edgecolor',[252/360 12/360 12/360],'linewidth',3,'edgealpha',1);
        subplot(223);
        patchline(mean(xfiltsMiss),mean(yfiltsMiss),'edgecolor',[252/360 12/360 12/360],'linewidth',3,'edgealpha',1);
        subplot(224);
        patchline(mean(xfiltsSuccess),mean(yfiltsSuccess),'edgecolor',[67/360 179/360 225/360],'linewidth',3,'edgealpha',1);
    end
end
