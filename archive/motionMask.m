function [out] = motionMask(video,hsvBounds)
%
% usage:
%
%
%
% INPUTS:
%
% OUTPUTS:
%

figure(1);

vidName = fullfile(video.Path, video.Name);
video = VideoReader(vidName);
image = readFrame(video);

detector = vision.ForegroundDetector(...
   'NumTrainingFrames', 100, ...
   'InitialVariance', 30*30, ...
   'MinimumBackgroundRatio', 0.8, ...
   'AdaptLearningRate',true, ...
   'LearningRate', 0.005, ...
   'NumGaussians',3); % initial standard deviation of 30
blob = vision.BlobAnalysis(...
   'CentroidOutputPort', false, 'AreaOutputPort', false, ...
   'BoundingBoxOutputPort', true, ...
   'MinimumBlobAreaSource', 'Property', 'MinimumBlobArea', 200);

% shapeInserter = vision.ShapeInserter('BorderColor','White');
numImages = 0;
while video.CurrentTime < video.Duration
    image  = readFrame(video);
numImages = numImages + 1
%     hsv = rgb2hsv(image);
% 
%     h = hsv(:,:,1);
%     s = hsv(:,:,2);
%     v = hsv(:,:,3);
% 
%     % bound the hue element using all three bounds
%     h(h < hsvBounds(1) | h > hsvBounds(2)) = 0;
%     h(s < hsvBounds(3) | s > hsvBounds(4)) = 0;
%     h(v < hsvBounds(5) | v > hsvBounds(6)) = 0;

%     rgb = hsv2rgb(h);

    fgMask = step(detector, image);
    imshow(fgMask);
%     bbox = step(blob, fgMask);
%     out = step(shapeInserter, image, bbox);
%     imshow(out);
end