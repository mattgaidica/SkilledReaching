function [digitImg,palmImg,paw_img,paw_mask] = maskPaw( img, BGimg, ROI_to_mask_paw, Fleft,Fright,register_ROI,rat_metadata,varargin )
%
% usage:
%
% INPUTS:
%   img - the image in which to find the paw mask
%   ROI_to_mask_paw - 

diff_threshold = 45;

for iarg = 1 : 2 : nargin - 7
    switch lower(varargin{iarg})
        case 'diffthreshold',
            diff_threshold = varargin{iarg + 1};
    end
end

paw_diff_img = cell(1,3);paw_img = cell(1,3);
thresh_mask = cell(1,3);
paw_mask = cell(1,3);
bg_subtracted_image = imabsdiff(img, BGimg);

for ii = 1 : 3
    paw_diff_img{ii} = bg_subtracted_image(ROI_to_mask_paw(ii,2):ROI_to_mask_paw(ii,2) + ROI_to_mask_paw(ii,4),...
                                           ROI_to_mask_paw(ii,1):ROI_to_mask_paw(ii,1) + ROI_to_mask_paw(ii,3),:);
    paw_img{ii} = img(ROI_to_mask_paw(ii,2):ROI_to_mask_paw(ii,2) + ROI_to_mask_paw(ii,4),...
                      ROI_to_mask_paw(ii,1):ROI_to_mask_paw(ii,1) + ROI_to_mask_paw(ii,3),:);
                                                               
	thresh_mask{ii} = rgb2gray(paw_diff_img{ii}) > diff_threshold;
end

% work on the left and right images first...
SE = strel('disk',3);
for ii = 1 : 2 : 3
    paw_mask{ii} = bwdist(thresh_mask{ii}) < 2;
    paw_mask{ii} = imopen(paw_mask{ii}, SE);
    paw_mask{ii} = imclose(paw_mask{ii},SE);
    paw_mask{ii} = imfill(paw_mask{ii},'holes');
    paw_mask{ii} = fliplr(paw_mask{ii});
end

% mask out the individual digits
if strcmpi(rat_metadata.pawPref,'right')    % back of paw in the left mirror
    digitWindow = 1;    % look in the left mirror for the digits
    palmWindow  = 3;    % look in the right mirror for the palm
else
    digitWindow = 3;    % look in the right mirror for the digits
    palmWindow  = 1;    % look in the left mirror for the palm
end

digitMask = repmat(paw_mask{digitWindow},1,1,3);
% [pawRows,pawCols] = find(paw_mask{digitWindow});
digitImg  = fliplr(paw_img{digitWindow}) .* uint8(digitMask);
% digitImg_enh = decorrstretch(digitImg,'samplesubs',{pawRows,pawCols});
% digitImg = fliplr(digitImg);
% digitImg_enh  = fliplr(digitImg_enh);

palmMask  = repmat(paw_mask{palmWindow},1,1,3);
palmImg   = fliplr(paw_img{palmWindow}) .* uint8(palmMask);
% palmImg   = fliplr(palmImg);
% given the fundamental transformation matrix from the background, we
% should be able to constrain where the paw is in the front view
% 

% WORKING HERE...
% IDENTIFY INDIVIDUAL DIGITS IN EACH VIEW
% USE THE MIRROR VIEWS TO CONSTRAIN WHERE THE PAW CAN BE IN THE CENTER
% VIEW? MAYBE USE BOUNDING BOXES ON THE MASKED IMAGES AND THE FUNDAMENTAL
% MATRICES TO ZOOM IN ON THE PAW'S LOCATION.


% START BY THRESHOLDING BASED ON IMAGE SUBTRACTION, THEN GO BACK TO
% IDENTIFY COLORS IN THE PREVIOUSLY MASKED IMAGE
% LOOK INTO WHETHER ANY OF THE MATLAB IMAGE TRACKING ALGORITHMS WILL FOLLOW
% THE PAW AND/OR DIGITS ONCE IDENTIFIED IN THE FIRST FRAME
% ALSO NEED TO FIGURE OUT WHAT TO DO ABOUT THE CENTER WHERE THE BG
% SUBTRACTION ISN'T AS CLEAN

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
