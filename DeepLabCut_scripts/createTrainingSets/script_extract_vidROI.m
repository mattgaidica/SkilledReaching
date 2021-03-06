% script to crop video with the same ROI as the extracted frames

% script to randomly select videos, crop them, and store frames for marking
% paws in Fiji (or whatever else we decide to use)


% need to set up a destination folder to put the stacks of videos of each
% type - left vs right pawed, tattooed vs not
%%
rootPath = fullfile('/Volumes','Tbolt_01','Skilled Reaching');
triggerTime = 1;    % seconds
frameTimeLimits = [-1/2,1];    % time around trigger to extract frames
numVidsttoExtract = 30;

% which types of videos to extract? left vs right paw, tat vs no tat
selectPawPref = 'left';
selectTattoo = 'yes';
digitColors = 'gpybr';   % order of colors on the digits (digits 1-4 and dorsum of paw).
                         % g = green, p = purple, b = blue, y = yellow, r = red

if strcmpi(selectTattoo,'yes')
    savePath = fullfile('/Volumes','Tbolt_01','Skilled Reaching','deepLabCut_testing_vids',[selectPawPref, '_paw_tattooed_', digitColors]);
else
    savePath = fullfile('/Volumes','Tbolt_01','Skilled Reaching','deepLabCut_testing_vids',[selectPawPref, '_paw_markerless']);
end

% if ~exist(savePath,'dir')
%     mkdir(savePath);
% end

viewList = {'left','direct','right'};
viewSavePath = cell(1,3);
for iView = 1 : length(viewList)
    viewSavePath{iView} = fullfile(savePath, [viewList{iView} '_view']);
    if ~isfolder(viewSavePath{iView})
        mkdir(viewSavePath{iView});
    end
end

script_ratInfo_for_deepcut;
numRats = length(ratInfo);

% first row for direct view, second row left view, third row right view
% format [a,b,c,d] where (a,b) is the upper left corner and (c,d) is
% (width,height)

ROI = [750,450,550,550;
       1,550,450,350;
       1650,550,390,350];

% ultimately, randomly select videos and times for cropping out images to
% make a stack

% first step will be to make a list of tattooed and non-tattooed sessions

numValidRats = 0;
for iRat = 1 : numRats
    if strcmpi(ratInfo(iRat).pawPref, selectPawPref) && ...
       strcmpi(ratInfo(iRat).digitColors, digitColors)
        numValidRats = numValidRats + 1;
        validRatInfo(numValidRats) = ratInfo(iRat);
    end
end

%%
numVidsExtracted = 0;
while numVidsExtracted < numVidsttoExtract

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
    destVidName = cell(1,length(viewSavePath));
    for iView = 1 : length(viewSavePath)
        destVidName{iView} = fullfile(viewSavePath, [vidName(1:end-4),'_',viewList{iView}]);
    end

    cropVideo(vidName,destVidName,frameTimeLimits,triggerTime,ROI);
    
    numVidsExtracted = numVidsExtracted + 1;

end
%%
% save metadata files
if strcmpi(selectTattoo,'yes')
    fname = [selectPawPref, '_paw_tattooed_', digitColors, '_metadata.mat'];
else
    fname = [selectPawPref, '_paw_markerless_metadata.mat'];
end
for i_vidDest = 1 : length(viewSavePath)
    cd(viewSavePath{iView});
    save(fname,'triggerTime','frameTimeLimits','viewList','ROI');
end