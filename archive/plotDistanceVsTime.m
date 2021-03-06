function plotDistanceVsTime(pawCenters,frameRate,pxToMm,pelletCoords)
    allDist = NaN(size(pawCenters,1),1);
    for i=1:size(pawCenters,1)
        if(~isnan(pawCenters(i,1)))
            allDist(i) = pdist([pawCenters(i,:);pelletCoords])*pxToMm;
        else
            allDist(i) = NaN;
        end
    end
    
    for i=1:numel(allDist)
        if(allDist(i) < 10)
           break;
        end
    end
    
    if(i > 100 && i < 200) % less than this is a bad reach/data
        alignedDist = NaN(200,1);
        alignedDist(1:numel(allDist(i-50:end))) = allDist(i-50:end);
        hold on;
        % smoothn: http://www.biomecardio.com/matlab/smoothn.html
        %plot(0:(1/frameRate):((1/frameRate)*size(pawCenters,1))-(1/frameRate),smoothn(allDist,10,'robust'));
        plot(1:numel(alignedDist),smoothn((alignedDist),10,'robust'));
    end
end