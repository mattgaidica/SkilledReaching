function [h1,h2]=test_plot1dDistanceScores(folderPath,plotFrames)
   % scoreLookup = dir(fullfile(folderPath,'*.csv'));
%     scoreData = csvread(fullfile(folderPath,scoreLookup(1).name));

    matLookup = dir(fullfile(folderPath,'_xyzData','*.mat'));
    load(fullfile(folderPath,'_xyzData',matLookup(1).name));

    startFrame = 1;
%     plot1Indexes = find(ismember(scoreData(:,2),[1]));
%     plot2Indexes = find(ismember(scoreData(:,2),[2,3,4,7]));
%     plot1Cells = allAlignedXyzDistPawCenters(plot1Indexes);
    allDistData = [];
%     plot1Indexes = ismember(scoreData(:,2),1);
%     plot2Indexes = ismember(scoreData(:,2),[2,3,4,7]);
    
    dataSet = allXyzDistPawCenters;
    for i = 1:numel(dataSet)
        distData = dataSet{i}(startFrame:plotFrames);
        distFilt = smoothn(distData,10,'robust');
        hold on;
        p = plot(startFrame:plotFrames,distFilt);
        %set(p,'Color',color);
    end

end
%     for i=1:numel(dataSet)
%          if(size(dataSet{i},2) > 1)
%              distData = dataSet{i}(startFrame:plotFrames);
% %             switch scoreData(i,2)
% %                 case 1
% %                     subplot(1,2,1);
% %                 case {2,3,4,7}
% %                     subplot(1,2,2);
% %                 otherwise
% %                     disp(['bad trial: ',num2str(i)]);
% %                     continue;
% %             end
%             distFilt = smoothn(distData,10,'robust');
%             allDistData(i,:) = distFilt; % removes nans so mean works
%             %colormapline(startFrame:plotFrames,distFilt,[]);
%             hold on;
%         else
%             disp(['skipped session: ',num2str(i)]);
%             % use indexes as a flag to skip over bad sessions
%             plot1Indexes(i) = 0;
% %             plot2Indexes(i) = 0;
%          end
%     end
% %     
%     for k=1:1
%          h(k) = subplot(1,1,k);
%         %view(h(k),[37.5,30]); % az,el
%         %view(h(k),azel); % az,el
%         xlabel(h(k),'frames');
%         %zlabel(h(k),'z');
%         %legend on;
%         grid(h(k));
%         box(h(k));
% %         switch diffn
% %             case 0
%                 axis(h(k),[0 plotFrames 0 70]); % x y z
%                 ylabel(h(k),'distance (mm)');
% %             case 1
% %                 axis(h(k),[0 (plotFrames-diffn) -5 3]); % x y z
% %                 ylabel(h(k),'d/t');
% %             otherwise
% %                 axis(h(k),[0 (plotFrames-diffn) -0.25 .5]); % x y z
% %                 ylabel(h(k),'d/t');
% %         end
%         hold on;
%         
% %         switch k
% %             case 1
%                 title(h(k),'First Trial Success - 1');
%                 h1 = plotLine(allDistData(plot1Indexes,:),startFrame,plotFrames,lineColor,diffn);
% %             case 2
% %                 title(h(k),'Unsuccessful - {2,3,4,7}');
% %                 h2 = plotLine(allDistData(plot2Indexes,:),startFrame,plotFrames,lineColor,diffn);
% %         end
%     end
% end
% 
% % simply allows zeros to be pass into the diff function
% function data=ezDiff(data,diffn)
%     if(diffn > 0)
%         data = diff(data,diffn,2);
%     end
% end
% 
% function h=plotLine(plotData,startFrame,plotFrames,lineColor,diffn)
%     plotData = ezDiff(plotData,diffn);
%     dataMean = mean(plotData);
%     dataStd = std(plotData);
%     
%     h = plot(startFrame:(plotFrames-diffn),dataMean,'Color',lineColor,'Marker','o','MarkerSize',5);
%     plot(startFrame:(plotFrames-diffn),dataMean+dataStd,'Color',lineColor,'LineStyle','--');
%     plot(startFrame:(plotFrames-diffn),dataMean-dataStd,'Color',lineColor,'LineStyle','--');
% end