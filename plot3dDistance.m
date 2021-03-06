% Matt Gaidica, mgaidica@med.umich.edu
% Leventhal Lab, University of Michigan
% --- release: beta ---

function h=plot3dDistance(allAlignedXyzPawCenters,plotFrames)
    h = figure;
    view(37.5,30);
    xlabel('x');
    ylabel('y');
    zlabel('z');
    grid on; 
    box on;
    startFrame = 10;
    for i=1:numel(allAlignedXyzPawCenters)
        alignedXyzPawCenters = allAlignedXyzPawCenters{i};
        if(size(alignedXyzPawCenters,1) > 5)
            xfilt = medfilt1(alignedXyzPawCenters(startFrame:plotFrames,1),4);
            yfilt = medfilt1(alignedXyzPawCenters(startFrame:plotFrames,2),4);
            zfilt = medfilt1(alignedXyzPawCenters(startFrame:plotFrames,3),4);
            hold on;
            colormapline(smoothn(xfilt,3,'robust'),smoothn(yfilt,3,'robust'),smoothn(zfilt,3,'robust'),jet(128));
        end
    end
end