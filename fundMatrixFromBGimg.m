function [Fleft, Fright] = fundMatrixFromBGimg(BGimg, register_ROI, hsvBounds_beads, varargin)
%
% usage: 
%
% INPUTS:
%   BGimg - the background image averaged from the first ~50 frames of each
%       video
%   register_ROI - 3 x 4 matrix.
%              1st row - boundaries of left mirror region of interest
%              2nd row - boundaries of left mirror region of interest

% measure registration points from each perspective. Coordinates are with
% respect to the full video frame (that is, from the top left corner). To
% get coordinates in a segment of the image, subtract the location of the
% left/top edge of the subset

% note, this is hard-coded from the session R0030_20140430a. Will need
% other registration points for different sessions

% first, extract the relevant images
BG_hsv = rgb2hsv(BGimg);
BG_lft = uint8(BGimg(register_ROI(1,2):register_ROI(1,2) + register_ROI(1,4), ...
                     register_ROI(1,1):register_ROI(1,1) + register_ROI(1,3), :));
BG_ctr = uint8(BGimg(register_ROI(2,2):register_ROI(2,2) + register_ROI(2,4), ...
                     register_ROI(2,1):register_ROI(2,1) + register_ROI(2,3), :));
BG_rgt = uint8(BGimg(register_ROI(3,2):register_ROI(3,2) + register_ROI(3,4), ...
                     register_ROI(3,1):register_ROI(3,1) + register_ROI(3,3), :));

% find the colored beads; looks like HSV space is the way to go, but need
% to remember that the hue space is circular

lftFeatures = detectHarrisFeatures(BG_lft);
ctrFeatures = detectHarrisFeatures(BG_ctr);
rgtFeatures = detectHarrisFeatures(BG_rgt);

% lftFeatures = detectSURFFeatures(BG_lft,'metricthreshold',500);
% ctrFeatures = detectSURFFeatures(BG_ctr,'metricthreshold',500);
% rgtFeatures = detectSURFFeatures(BG_rgt,'metricthreshold',500);

plot(lftFeatures);
figure(1);imshow(BG_lft);hold on
plot(selectStrongest(lftFeatures, 30));
% plot(lftFeatures);
figure(2);imshow(BG_ctr);hold on
plot(selectStrongest(ctrFeatures, 30));
% plot(ctrFeatures);
figure(3);imshow(BG_rgt);hold on
plot(selectStrongest(rgtFeatures, 30));
% plot(rgtFeatures);

% next, find features in all 3 images
ctrView_rubiks1_left = [778,406];
ctrView_rubiks2_left = [773,534];
ctrView_rubiks3_left = [774,548];
ctrView_rubiks4_left = [775,672];
ctrView_rubiks5_left = [769,682];
ctrView_rubiks6_left = [766,803];
ctrView_bottom_left  = [446,882];
ctrView_shelf_bot_left  = [551,668];
ctrView_shelf_top_left  = [551,648];
ctrView_bracket_bot_left  = [607,789];
ctrView_bracket_top_left  = [567,683];

ctrView_rubiks1_right = [1181,413];
ctrView_rubiks2_right = [1179,543];
ctrView_rubiks3_right = [1177,553];
ctrView_rubiks4_right = [1175,680];
ctrView_rubiks5_right = [1171,690];
ctrView_rubiks6_right = [1169,813];
ctrView_bottom_right = [1524,888];
ctrView_shelf_bot_right  = [1382,679];
ctrView_shelf_top_right  = [1384,659];
ctrView_bracket_bot_right  = [1333,798];
ctrView_bracket_top_right  = [1354,695];

lftView_rubiks1 = [240,447];
lftView_rubiks2 = [237,539];
lftView_rubiks3 = [236,551];
lftView_rubiks4 = [239,641];
lftView_rubiks5 = [238,655];
lftView_rubiks6 = [238,744];
lftView_boxCorner = [210,815];
lftView_shelf_top = [6,624];
lftView_shelf_bot = [5,639];
lftView_bracket_top = [80,654];
lftView_bracket_bot = [189,739];
lftView_shelf_far = [53,609];    % correspoinds to ctrView_shelf_top_right

rtView_rubiks1 = [1745,449];
rtView_rubiks2 = [1749,543];
rtView_rubiks3 = [1748,555];
rtView_rubiks4 = [1749,644];
rtView_rubiks5 = [1750,653];
rtView_rubiks6 = [1750,741];
rtView_boxCorner = [1778,821];
rtView_shelf_top = [1987,626];
rtView_shelf_bot = [1987,641];
rtView_bracket_top = [1903,656];
rtView_bracket_bot = [1796,740];
rtView_shelf_far = [1927,601];    % correspoinds to ctrView_shelf_top_left


ctrView_left  = zeros(12, 2);
ctrView_right = zeros(12, 2);
lftView       = zeros(12, 2);
rtView        = zeros(12, 2);

ctrView_lftFrame_points = zeros(12, 2);
ctrView_rtFrame_points  = zeros(12, 2);
lftFrame_points         = zeros(12, 2);
rtFrame_points          = zeros(12, 2);

ctrView_left(1,:) = ctrView_rubiks1_left;
ctrView_left(2,:) = ctrView_rubiks2_left;
ctrView_left(3,:) = ctrView_rubiks3_left;
ctrView_left(4,:) = ctrView_rubiks4_left;
ctrView_left(5,:) = ctrView_rubiks5_left;
ctrView_left(6,:) = ctrView_rubiks6_left;
ctrView_left(7,:) = ctrView_bottom_left;
ctrView_left(8,:) = ctrView_shelf_top_left;
ctrView_left(9,:) = ctrView_shelf_bot_left;
ctrView_left(10,:) = ctrView_bracket_top_left;
ctrView_left(11,:) = ctrView_bracket_bot_left;
ctrView_left(12,:) = ctrView_shelf_top_right;

ctrView_right(1,:) = ctrView_rubiks1_right;
ctrView_right(2,:) = ctrView_rubiks2_right;
ctrView_right(3,:) = ctrView_rubiks3_right;
ctrView_right(4,:) = ctrView_rubiks4_right;
ctrView_right(5,:) = ctrView_rubiks5_right;
ctrView_right(6,:) = ctrView_rubiks6_right;
ctrView_right(7,:) = ctrView_bottom_right;
ctrView_right(8,:) = ctrView_shelf_top_right;
ctrView_right(9,:) = ctrView_shelf_bot_right;
ctrView_right(10,:) = ctrView_bracket_top_right;
ctrView_right(11,:) = ctrView_bracket_bot_right;
ctrView_right(12,:) = ctrView_shelf_top_left;

lftView(1,:) = lftView_rubiks1;
lftView(2,:) = lftView_rubiks2;
lftView(3,:) = lftView_rubiks3;
lftView(4,:) = lftView_rubiks4;
lftView(5,:) = lftView_rubiks5;
lftView(6,:) = lftView_rubiks6;
lftView(7,:) = lftView_boxCorner;
lftView(8,:) = lftView_shelf_top;
lftView(9,:) = lftView_shelf_bot;
lftView(10,:) = lftView_bracket_top;
lftView(11,:) = lftView_bracket_bot;
lftView(12,:) = lftView_shelf_far;

rtView(1,:) = rtView_rubiks1;
rtView(2,:) = rtView_rubiks2;
rtView(3,:) = rtView_rubiks3;
rtView(4,:) = rtView_rubiks4;
rtView(5,:) = rtView_rubiks5;
rtView(6,:) = rtView_rubiks6;
rtView(7,:) = rtView_boxCorner;
rtView(8,:) = rtView_shelf_top;
rtView(9,:) = rtView_shelf_bot;
rtView(10,:) = rtView_bracket_top;
rtView(11,:) = rtView_bracket_bot;
rtView(12,:) = rtView_shelf_far;

% now recompute the registration point coordinates based on the windows
% used for each view

ctrView_lftFrame_points(:,1) = ctrView_left(:,1) - register_ROI(2,1);
ctrView_lftFrame_points(:,2) = ctrView_left(:,2) - register_ROI(2,2);
ctrView_rtFrame_points(:,1) = ctrView_right(:,1) - register_ROI(2,1);
ctrView_rtFrame_points(:,2) = ctrView_right(:,2) - register_ROI(2,2);

% left and right frames are flipped left-right to account for the image
% reversal in the mirrors
lftFrame_points(:,1) = register_ROI(1,3) - (lftView(:, 1) - register_ROI(1,1));
lftFrame_points(:,2) = (lftView(:, 2) - register_ROI(1,2));
rtFrame_points(:,1)  = register_ROI(3,3) - (rtView(:, 1) - register_ROI(3,1));
rtFrame_points(:,2)  = (rtView(:, 2) - register_ROI(3,2));
% 
% % sanity check to make sure the points are marked properly
% figure(1);hold off;
% imshow(BGimg);
% hold on
% for ii = 1 : size(rtView, 1)
%     plot(ctrView_left(ii,1),ctrView_left(ii,2),'linestyle','none','marker','*','color','b');
%     plot(ctrView_right(ii,1),ctrView_right(ii,2),'linestyle','none','marker','*','color','b');
%     plot(lftView(ii,1),lftView(ii,2),'linestyle','none','marker','*','color','b');
%     plot(rtView(ii,1),rtView(ii,2),'linestyle','none','marker','*','color','b');
% end
% 
% figure(2);hold off;
% imshow(lft_calROI);
% hold on
% for ii = 1 : size(rtView, 1)
%     plot(lftFrame_points(ii,1),lftFrame_points(ii,2),'linestyle','none','marker','*','color','b');
% end
% 
% figure(3);hold off;
% imshow(ctr_calROI);
% hold on
% for ii = 1 : size(rtView, 1)
%     plot(ctrView_lftFrame_points(ii,1),ctrView_lftFrame_points(ii,2),'linestyle','none','marker','*','color','b');
%     plot(ctrView_rtFrame_points(ii,1),ctrView_rtFrame_points(ii,2),'linestyle','none','marker','*','color','r');
% end
% 
% figure(4);hold off;
% imshow(rt_calROI);
% hold on
% for ii = 1 : size(rtView, 1)
%     plot(rtFrame_points(ii,1),rtFrame_points(ii,2),'linestyle','none','marker','*','color','r');
% end



% now calculate the fundamental matrices for the right and left views
% mapping onto the center view
Fleft  = estimateFundamentalMatrix(lftFrame_points, ctrView_lftFrame_points,'method','norm8point');
Fright = estimateFundamentalMatrix(rtFrame_points, ctrView_rtFrame_points,'method','norm8point');

% leftLines   = epipolarLine(Fleft, lftFrame_points);
% righttLines = epipolarLine(Fright, rtFrame_points);
% 
% leftPoints  = lineToBorderPoints(leftLines, [size(ctr_calROI,1),size(ctr_calROI,2)]);
% rightPoints = lineToBorderPoints(righttLines, [size(ctr_calROI,1),size(ctr_calROI,2)]);
% 
% figure(3);
% line(leftPoints(:,[1,3])',leftPoints(:,[2,4])');
% line(rightPoints(:,[1,3])',rightPoints(:,[2,4])');
% 
% 
