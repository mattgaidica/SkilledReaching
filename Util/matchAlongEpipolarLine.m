function matchPts = matchAlongEpipolarLine(epiLine, searchMask, img_ud, pawMask)

colorThresh = 2;   % standard deviations

max_dist_from_line = 1;
boxSize = 15;

[y_search,x_search] = find(searchMask);

% find points close to the epipolarLine
testValues = epiLine(1) * x_search + epiLine(2) * y_search + epiLine(3);

pts_to_search = find(abs(testValues) < max_dist_from_line);

search_r_vals = zeros(length(x_search),1);
search_g_vals = zeros(length(x_search),1);
search_b_vals = zeros(length(x_search),1);
for ii = 1 : length(x_search)
    search_r_vals(ii) = img_ud(y_search(ii),x_search(ii),1);
    search_g_vals(ii) = img_ud(y_search(ii),x_search(ii),2);
    search_b_vals(ii) = img_ud(y_search(ii),x_search(ii),3);
end

[y_template,x_template] = find(pawMask);

template_r_vals = zeros(length(x_template),1);
template_g_vals = zeros(length(x_template),1);
template_b_vals = zeros(length(x_template),1);
for ii = 1 : length(x_template)
    template_r_vals(ii) = img_ud(y_template(ii),x_template(ii),1);
    template_g_vals(ii) = img_ud(y_template(ii),x_template(ii),2);
    template_b_vals(ii) = img_ud(y_template(ii),x_template(ii),3);
end
mean_color = mean([template_r_vals,template_g_vals,template_b_vals]);
std_color = std([template_r_vals,template_g_vals,template_b_vals],0,1);
color_dist = zeros(length(pts_to_search),1);

num_match_pts = 0;
for ii = 1 : length(pts_to_search)
    
    color_dist(ii) = norm(([search_r_vals(ii),search_g_vals(ii),search_b_vals(ii)] - mean_color) ./ std_color);
%     bbox = [x(pts_to_search(ii)) - floor(boxSize/2), y(pts_to_search(ii)) - floor(boxSize/2), ...
%             x(pts_to_search(ii)) + floor(boxSize/2), y(pts_to_search(ii)) + floor(boxSize/2)];
%         
% 	testWindow = img_ud(bbox(2):bbox(4),bbox(1):bbox(3),:);
    
    % NEED SOME METRIC OF HOW "PAW-LIKE" THE POINTS ARE AND WHERE THE POINT
    % WOULD END UP IN 3-D SPACE - COULD USE PREVIOUS AND FOLLOWING FRAMES
    % TO SEE IF IT'S GOING THE RIGHT DIRECTION?

    if color_dist(ii) < colorThresh
        num_match_pts = num_match_pts + 1;
        if num_match_pts == 1
            matchPts
        else
            matchPts(num_match_pts,:) = [x_search(ii),y_search(ii)];
        
end

matchPts = 0;