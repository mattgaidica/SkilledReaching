% script to randomly select videos, crop them, and store frames for marking
% paws in Fiji (or whatever else we decide to use)


% need to set up a destination folder to put the stacks of videos of each
% type - left vs right pawed, tattooed vs not

rootPath = fullfile('/Volumes','Tbolt_01','Skilled Reaching');
triggerTime = 1;    % seconds
frameTimeLimits = [-1/6,1/3];    % time around trigger to extract frames
numFramesttoExtract = 200;

% which types of videos to extract? left vs right paw, tat vs no tat
selectPawPref = 'right';
selectTattoo = 'yes';

savePath = fullfile('/Volumes','Tbolt_01','Skilled Reaching','deepLabCut_training_frames',[selectPawPref, '_paw_', selectTattoo, '_tattoo']);
% if ~exist(savePath,'dir')
%     mkdir(savePath);
% end

viewList = {'left_view','direct_view','right_view'};

viewSavePath = cell(1,length(viewList));

numFramesExtracted = zeros(1, length(viewList));
for iView = 1 : length(viewList)
    viewSavePath{iView} = fullfile(savePath, viewList{iView});
    if ~exist(viewSavePath{iView},'dir')
        mkdir(viewSavePath{iView});
    else
        cd(viewSavePath{iView});
        frameList = dir('*.png');
        numFramesExtracted(iView) = length(frameList);
    end
end

if ~all(numFramesExtracted == numFramesExtracted(1))
    % different number of frames for each view
    disp('different numbers of frames for each view')
    return;
end

script_ratInfo_for_deepcut;
numRats = length(ratInfo);

% first row for direct view, second row left view, third row right view
% format [a,b,c,d] where (a,b) is the upper left corner and (c,d) is
% (width,height)

ROI = [750,450,550,550;
       1,450,450,450;
       1650,450,390,450];


% hard code coordinates for cropping direct view, left mirror, right mirror
triggerFrame = 300;
frameRange = [200,500];

% ultimately, randomly select videos and times for cropping out images to
% make a stack

% first step will be to make a list of tattooed and non-tattooed sessions

frameStack_tat_left = cell(1,3);
frameStack_tat_right = cell(1,3);
frameStack_notat_left = cell(1,3);
frameStack_notat_right = cell(1,3);

numValidRats = 0;
for iRat = 1 : numRats
    if strcmpi(ratInfo(iRat).pawPref, selectPawPref)
        numValidRats = numValidRats + 1;
        validRatInfo(numValidRats) = ratInfo(iRat);
    end
end

numFramesExtracted = numFramesExtracted(1);
while numFramesExtracted < numFramesttoExtract

    % select a rat at random
    validRatIdx = floor(rand * numValidRats) + 1;
    numRatSessions = length(validRatInfo(validRatIdx).sessionList);
    
    numValidSessions = 0;
    firstTattooDate = validRatInfo(validRatIdx).firstTattooedSession;
    if isempty(firstTattooDate)
        % rat hasn't been tattooed yet, so all sessions are without
        % tattoooing. pick a date way in the future
        firstTattooDateNum = datenum('20501231','yyyymmdd');
    else
        firstTattooDateNum = datenum(firstTattooDate,'yyyymmdd');
    end
    
    validSessionList = {};
    for iRatSession = 1 : numRatSessions
        currentSessionDate = validRatInfo(validRatIdx).sessionList{iRatSession}(7:end-1);
        currentSessionDateNum = datenum(currentSessionDate,'yyyymmdd');
        
        switch selectTattoo
            case 'no'
                if currentSessionDateNum < firstTattooDateNum
                    numValidSessions = numValidSessions + 1;
                    validSessionList{numValidSessions} = validRatInfo(validRatIdx).sessionList{iRatSession};
                end
            otherwise
                if currentSessionDateNum >= firstTattooDateNum
                    numValidSessions = numValidSessions + 1;
                    validSessionList{numValidSessions} = validRatInfo(validRatIdx).sessionList{iRatSession};
                end
        end
    end
    if numValidSessions == 0
        continue;
    end
    
    % select a session at random
    validSessionIdx = floor(rand * numValidSessions) + 1;

    ratSessionFolder = fullfile(rootPath,validRatInfo(validRatIdx).IDstring,validSessionList{validSessionIdx});
    cd(ratSessionFolder);

    vidList = dir([validRatInfo(validRatIdx).IDstring,'*.avi']);
    if isempty(vidList); continue; end
    % every now and then, an empty folder
        
    % pick a video at random
    currentVidNumber = floor(rand * length(vidList)) + 1;
    vidName = vidList(currentVidNumber).name;
    vidNameNumber = vidName(end-6:end-4);

    video = VideoReader(vidName);

    cur_img = readRandomFrame( video, 'triggertime', 1, 'frametimelimits', frameTimeLimits);
    curFrame = round(video.CurrentTime * video.FrameRate) - 1;
    curFrameStr = sprintf('%03d',curFrame);

    clear video
        
    % crop out bits
    cropped_img = cell(1,3);
    cropBaseName = [validSessionList{validSessionIdx} '_vid' vidNameNumber '_frame' curFrameStr];
    
    for iView = 1 : 3
        cropped_img{iView} = cur_img(ROI(iView,2) : ROI(iView,2) + ROI(iView,4), ...
                                     ROI(iView,1) : ROI(iView,1) + ROI(iView,3), :);
                                 
        cropFrameName = fullfile(viewSavePath{iView},[cropBaseName '_' viewList{iView} '.png']);
        imwrite(cropped_img{iView},cropFrameName,'png');
    end
    cd(viewSavePath{iView})
    frameList = dir('*.png');
    numFramesExtracted = length(frameList);

end

% now rename the images to 001, 002, etc.
for iView = 1 : length(viewSavePath)
    rootpath = viewSavePath{iView};

    cd(rootpath)

    pngList = dir('*.png');
    metadata_name = [selectPawPref, '_paw_', selectTattoo, '_tattoo_metadata.mat'];
    renameStartIdx = 1;
    if exist(metadata_name,'file')
        old_metadata = load(metadata_name);
        oldPngList = old_metadata.pngList;
        pngList(1:length(oldPngList)) = oldPngList;
        renameStartIdx = length(oldPngList) + 1;
        % this should preserve the file names if new files are added for
        % additional training
    end
    
    save(metadata_name,'pngList','ROI','viewList');
    % will be needed to reconstruct the points in the full image for 3D
    % reconstruction later

    for ii = renameStartIdx : length(pngList)
        
        % files previously renamed should still be in the right order
        newName = sprintf('%03d.png',ii);
        oldName = pngList(ii).name;

        movefile(oldName,newName);
    end
    
end