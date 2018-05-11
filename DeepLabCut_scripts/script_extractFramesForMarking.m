% script to randomly select videos, crop them, and store frames for marking
% paws in Fiji (or whatever else we decide to use)

rootPath = fullfile('/Volumes','Tbolt_01','Skilled Reaching');

script_ratInfo_for_deepcut;
numRats = length(ratInfo);

% hard code coordinates for cropping direct view, left mirror, right mirror

triggerFrame = 300;

% ultimately, randomly select videos and times for cropping out images to
% make a stack

% first step will be to make a list of tattooed and non-tattooed sessions

for iRat = 1 : numRats
    numRatSessions = length(ratInfo(iRat).sessionList);
    
    for iRatSession = 1 : numRatSessions
        ratSessionFolder = fullfile(rootPath,ratInfo(iRat).IDstring,ratInfo(iRat).sessionList{iSession});
        cd(ratSessionFolder);

        vidList = dir([ratInfo(iRat).IDstring ,'*.avi']);
        
        % pick a video at random
        currentVidNumber = ceil(rand(1,1) * ratInfo(iRat).numVids(iSession));
        vidName = vidList(currentVidNumber).name;
        
        video = videoReader(vidName);
        
    end
    
end