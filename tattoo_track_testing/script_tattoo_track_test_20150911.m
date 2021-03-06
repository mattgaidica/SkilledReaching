% scipt_tattoo_track_test
% testing identification of tattooed paw and digits

% algorithm outline:
% first issue: correctly identify colored paw regions

% 1) calibrate based on rubiks image to get fundamental matrix
%       - mark matching points either manually or automatically. manually
%       is probably going to be more accurate until we put clearer markers
%       in.
%       - create matrices of matching points coordinates and calculate F
%       for left to center and right to center
% 2) 


% criteria we can use to identify the paw:
%   1 - the paw is moving
%   2 - dorsum of the paw is (mostly) green
%   3 - palmar aspect is (mostly) pink
%   4 - it's different from the background image  

%%
% sampleVid  = fullfile('/Volumes/RecordingsLeventhal04/SkilledReaching/R0030/R0030-rawdata/R0030_20140430a','R0030_20140430_13-09-15_023.avi');
% sampleSession = fullfile('/Volumes/RecordingsLeventhal3/SkilledReaching/R0044/R0044-rawdata/R0044_20150416a');
sampleSession = fullfile('/Volumes/RecordingsLeventhal04/SkilledReaching/R0104/R0104-rawdata/R0104_20160223a');
cd(sampleSession);
vidList = dir('*.avi');
sampleVid  = fullfile(sampleSession, 'R0104_20160223_12-51-12_005.avi');
% sr_summary = sr_ratList();
sr_summary.ratID = 104;
sr_summary.pawPref = 'right';

cb_path = '/Users/dleventh/Documents/Leventhal_lab_github/SkilledReaching/tattoo_track_testing/intrinsics calibration images';
num_rad_coeff = 2;
est_tan_distortion = false;
estimateSkew = false;
minBeadArea = 0300;
maxBeadArea = 2000;
pointsPerRow = 4;    % for the checkerboard detection
maxBeadEcc = 0.8;
BG_diff_threshold = 20;
minSideOverlap = 0.4;
numBGframes = 20;
gray_paw_limits = [60 125] / 255;

test_ratID = 44;
rat_metadata = create_sr_ratMetadata(sr_summary, test_ratID);

video = VideoReader(sampleVid);
BGimg = extractBGimg( video, 'numbgframes', numBGframes);   % can comment out once calculated the first time during debugging

hsvBounds_beads = [0.00    0.16    0.50    1.00    0.00    1.00
                   0.33    0.16    0.00    0.50    0.00    0.50
                   0.66    0.16    0.50    1.00    0.00    1.00];
boxCalibration = calibrate_sr_box(BGimg, 'cb_path',cb_path,...
                                         'numradialdistortioncoefficients',num_rad_coeff,...
                                         'estimatetangentialdistortion',est_tan_distortion,...
                                         'estimateskew',estimateSkew,...
                                         'minbeadarea',minBeadArea,...
                                         'maxbeadarea',maxBeadArea,...
                                         'hsvbounds',hsvBounds_beads,...
                                         'maxeccentricity',maxBeadEcc,...
                                         'pointsperrow',pointsPerRow);
BGimg_ud = undistortImage(BGimg, boxCalibration.cameraParams);

startVid = 4;
isValidVideo = false(length(vidList),1);
for iVid = startVid : length(vidList)
    if vidList(iVid).bytes < 10000; continue; end
    
    currentVidName = vidList(iVid).name;
    disp(currentVidName)
    currentVidName = fullfile(sampleSession,currentVidName);
    
    video = VideoReader(currentVidName);
    h = video.Height;
    w = video.Width;

    % find the pellet, if there

    triggerTime = identifyTriggerTime( video, BGimg_ud, rat_metadata, boxCalibration, ...
                                       'pawgraylevels',gray_paw_limits);
                                   
	if triggerTime == video.Duration    % no trigger frame was found
        continue;
    end
    isValidVideo(iVid) = true;

    [initDigitMasks, init_mask_bbox, digitMarkers, refImageTime, dig_edge3D] = ...
        initialDigitID_20150910(video, triggerTime, BGimg_ud, rat_metadata, boxCalibration, ...
        'diffthreshold', BG_diff_threshold, ...
        'minsideoverlap',minSideOverlap);
end



%     pawTrajectory_f = track3Dpaw_forward_20151110(video, BGimg_ud, refImageTime, initDigitMasks, init_mask_bbox, digitMarkers, rat_metadata, boxCalibration, ...
%         'diffthreshold', BG_diff_threshold);
% %     pawTrajectory_b = track3Dpaw_backward(video, BGimg_ud, refImageTime, initDigitMasks, init_mask_bbox, digitMarkers, rat_metadata, boxCalibration);
%     
%     pawTrajectory_b = zeros(size(pawTrajectory_f));   % until the backwards routine fully works
%     pawTrajectory = pawTrajectory_f + pawTrajectory_b;
%     
%     matName = strrep(currentVidName,'.avi','.mat');
%     vid_metadata.FrameRate = video.FrameRate;
%     vid_metadata.Duration = video.Duration;
%     vid_metadata.width = video.Width;
%     vid_metadata.height = video.Height;
%     vid_metadata.triggerTime = triggerTime;
%     
%     save(matName,'pawTrajectory','vid_metadata');
%     
% end
% 
%                                      
%                                      
     