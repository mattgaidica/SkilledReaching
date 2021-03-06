function showNewTracking(image_ud, old_points2d, new_points2d, F)


figure(1)
imshow(image_ud)
h = size(image_ud,1);
w = size(image_ud,2);
% edge_pts = cell(1,2);
% 
% if iscell(fullMask)
%     for iView = 1 : 2
%         mask_outline = bwmorph(fullMask{iView},'remove');
%         [y,x] = find(mask_outline);
%         edge_pts{iView} = [x,y];
%     end
% else
%     mask_outline = bwmorph(fullMask,'remove');
%     [y,x] = find(mask_outline);
%     edge_pts = [x,y];
% end

% hold on
% if ~isempty(bbox)
%     rectangle('position',bbox(1,:));
%     rectangle('position',bbox(2,:));
% end
hold on
for iView = 1 : 2
    if any(old_points2d{iView}(:))
        plot(old_points2d{iView}(:,1),old_points2d{iView}(:,2),'color','b','marker','.','linestyle','none');
    end
    if any(new_points2d{iView}(:))
        plot(new_points2d{iView}(:,1),new_points2d{iView}(:,2),'color','r','marker','.','linestyle','none');
    end
end

newDirectMask = false(h,w);

for ii = 1 : size(new_points2d{1},1)
    newDirectMask(new_points2d{1}(ii,2),new_points2d{1}(ii,1)) = true;
end
newDirectMask = bwconvhull(newDirectMask);

directProjMask = projMaskFromTangentLines(newDirectMask,F,[1,1,h-1,w-1],[h,w]);
projMaskOutline = bwmorph(directProjMask,'remove');

[y,x] = find(projMaskOutline);
hold on
plot(x,y,'marker','.','linestyle','none');

end