function [nndist, meansep, nnidx] = nearestNeighbor(x)
%
% usage: 
%
% INPUTS:
%
% VARARGs:
%
% OUTPUTS:

diffMatrix = zeros(size(x,1)-1,size(x,2));
nndist = zeros(size(x,1),1);nnidx = zeros(size(x,1),1);
meansep = zeros(size(x,1),1);
for ii = 1 : size(x,1)
    curPoint = x(ii,:);
    switch ii
        case 1,
            otherPoints = x(ii+1:end,:);
        case size(x,1),
            otherPoints = x(1:end-1,:);
        otherwise,
            otherPoints = [x(1:ii-1,:);x(ii+1:end,:)];   
    end
    
    for jj = 1 : size(x,2)
        diffMatrix(:,jj) = curPoint(jj) - otherPoints(:,jj);
    end
    distances = sqrt(sum(diffMatrix.^2, 2));
    
    nndist(ii) = min(distances);
    mindistidx = find(distances == min(distances));
    if mindistidx < ii
        nnidx(ii) = mindistidx;
    else
        nnidx(ii) = mindistidx + 1;
    end
    meansep(ii) = mean(distances);
end