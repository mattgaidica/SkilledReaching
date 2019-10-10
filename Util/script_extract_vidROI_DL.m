% script to crop video with the same ROI as the extracted frames

ratList = {'R0158','R0159','R0160','R0161','R0169','R0170','R0171','R0183',...
           'R0184','R0186','R0187','R0189','R0190',...
           'R0191','R0192','R0193','R0194','R0195','R0196','R0197','R0198',...
           'R0216','R0217','R0218','R0219','R0220','R0223','R0225','R0227',...
           'R0228','R0229','R0230'};
       
repeatCalculations = true;   % if cropped video file already exists, don't repeat?

vidRootPath = '/Volumes/SharedX/Neuro-Leventhal/data/Skilled Reaching/SR_Opto_Raw_Data';
sharedX_root_metadata_SavePath = '/Volumes/SharedX/Neuro-Leventhal/data/Skilled Reaching/DLC output/Rats';
labeledBodypartsFolder = '/Volumes/LL EXHD #2/DLC output';
cd(labeledBodypartsFolder)
ratFolders = dir('R*');
numRatFolders = length(ratFolders);

xlDir = '/Users/dan/Box Sync/Leventhal Lab/Skilled Reaching Project/Scoring Sheets';
csvfname = fullfile(xlDir,'rat_info_pawtracking_20190819.csv');
ratInfo = readtable(csvfname);
ratInfo_IDs = [ratInfo.ratID];


triggerTime = 1;    % seconds
frameTimeLimits = [-1,3.3];    % time around trigger to extract frames
    
for i_rat = 30 : numRatFolders
    
    ratID = ratFolders(i_rat).name;
    ratFolder = fullfile(labeledBodypartsFolder,ratFolders(i_rat).name);
    
    sharedX_rat_metadata_savePath = fullfile(sharedX_root_metadata_SavePath,ratID);
    local_rat_metadata_savePath = fullfile(labeledBodypartsFolder,ratID);

    ratIDnum = str2double(ratID(2:end));
    thisRatInfo = ratInfo(ratInfo_IDs == ratIDnum,:);

    % is this rat tattooed? if so, what colors? on which date was it
    % tattooed?
    if iscell(thisRatInfo.pawPref)
        selectPawPref = thisRatInfo.pawPref{1};
    elseif iscategorical(thisRatInfo.pawPref)
        selectPawPref = char(thisRatInfo.pawPref);
    else
        selectPawPref = thisRatInfo.pawPref;
    end
    
    if iscell(thisRatInfo.tattooDate)
        tattooDate = thisRatInfo.tattooDate{1};
    else
        tattooDate = thisRatInfo.tattooDate;
    end

    if iscell(thisRatInfo.digitColors)
        digitColors = thisRatInfo.digitColors{1};
    else
        digitColors = thisRatInfo.digitColors;
    end

    % load the sessions table
    cd(ratFolder);
    sessionCSV = [ratID '_sessions.csv'];
    sessionTable = readSessionInfoTable(sessionCSV);
    
    % DL modifications for using the ratInfo table
    validRatInfo = findSubTable(ratInfo,'pawPref',selectPawPref,'digitColors',digitColors);
    numValidRats = size(validRatInfo,1);

    if useSessionsFrom_DLCoutput_folder
        DLCout_folder = fullfile(labeledBodypartsFolder,ratID);
        cd(DLCout_folder);

        sessionDirectories = listFolders([ratID '_2*']);
        for ii = 1 : length(sessionDirectories)
            sessionsToExtract(ii).ratID = ratID;
            sessionsToExtract(ii).session = sessionDirectories{ii}(7:end);
        end

    else
        % use sessions defined by the sessions table
        % WORKING HERE TO IDENTIFY SESSIONSTOEXTRACT FROM sessionTable
        
        
        
    end

    switch ratID
        case 'R0227'
            startSess = 1;
            endSess = length(sessionsToExtract);
            ROI = [750,450,550,550;
                  1,450,450,400;
                  1650,435,390,400];
        case 'R0216'
            ROI = [750,350,550,600;
                   1,400,450,450;
                   1650,400,390,450];
            startSess = 1;
            endSess = length(sessionsToExtract);
        otherwise
            ROI = [750,450,550,550;
                  1,450,450,400;
                  1650,435,390,400];
            startSess = 1;
            endSess = length(sessionsToExtract);
    end
    
    for iSess = startSess:endSess

        vid_savePath
        sharedX_metadata_savePath = fullfile(sharedX_rat_metadata_savePath
        local_metadata_savePath = fullfile(local_rat_metadata_savePath
            
    
    selectTattoo = 'yes';
    if strcmpi(selectTattoo,'yes')
        savePath = fullfile('/Volumes','LL EXHD #2','Skilled Reaching',[ratID '_cropped'],[selectPawPref, '_paw_tattooed_', digitColors]);
    else
        savePath = fullfile('/Volumes','LL EXHD #2','Skilled Reaching',[ratID '_cropped'],[selectPawPref, '_paw_markerless']);
    end 

    if ~exist(savePath,'dir')
        mkdir(savePath);
    end

    viewList = {'direct','left','right'};
    viewSavePath = cell(1,3);
    for iView = 1 : length(viewList)
        viewSavePath{iView} = fullfile(savePath, [viewList{iView} '_view']);
        if ~isfolder(viewSavePath{iView})
            mkdir(viewSavePath{iView});
        end
    end
    
            fullSessionName = [sessionsToExtract(iSess).ratID '_' sessionsToExtract(iSess).session];
            vidSessionFolder = fullfile(vidRootPath,sessionsToExtract(iSess).ratID,fullSessionName);
            sharedX_sessionFolder = fullfile(sharedX_savePath,fullSessionName);
            local_sessionFolder = fullfile(local_savePath,fullSessionName);
            cd(vidSessionFolder);

            vidList = dir([sessionsToExtract(iSess).ratID,'*.avi']);
            if isempty(vidList); continue; end

            numVidsExtracted = 0;
                  
            for vid = 1:length(vidList)
                frameTimeLimits = [-1,3.3]; 
                vidName = vidList(vid).name;
                vidNameNumber = vidName(end-6:end-4);
                destVidName = cell(1,length(viewSavePath));
                for iView = 1 : length(viewSavePath)
                    destVidName{iView} = fullfile(viewSavePath{iView}, [vidName(1:end-4),'_',viewList{iView}, '.mp4']);
                end

                % check if destination vid already exists. If set to not
                % repeat calculations and cropped vid already exists, skip
                if ~repeatCalculations
                    if exist(destVidName{iView},'file')
                        continue;
                    end
                end

                fprintf('working on %s\n', vidName);

                video=VideoReader(vidName);

                if video.Duration < frameTimeLimits(2)+ triggerTime
                    frameTimeLimits = [-1 video.Duration-1.01];
                else
                    frameTimeLimits = frameTimeLimits;
                end             
                frameRate = video.FrameRate;
                frameSize = [video.height,video.width];
%                 cropVideo(vidName,destVidName,frameTimeLimits,triggerTime,ROI);

                [fp,fn,fext] = fileparts(vidName);

                for iView = 1 : length(viewSavePath)
                    metadata_name = [fn '_' viewList{iView} '_metadata.mat'];
                    if ~exist(viewSavePath{iView},'dir')
                        mkdir(viewSavePath{iView});
                    end
                    view_direction = viewList{iView};
                    viewROI = ROI(iView,:);

                    full_metadata_name{1} = fullfile(viewSavePath{iView},metadata_name);
                    sharedX_viewPath = fullfile(sharedX_sessionFolder,[fullSessionName '_' viewList{iView}]);
                    local_viewPath = fullfile(local_sessionFolder,[fullSessionName '_' viewList{iView}]);
                    full_metadata_name{2} = fullfile(sharedX_viewPath,metadata_name);
                    full_metadata_name{3} = fullfile(local_viewPath,metadata_name);
                    for ii = 1 : 3
                        [cur_path,~,~] = fileparts(full_metadata_name{ii});
                        if ~exist(cur_path,'dir')
                            mkdir(cur_path)
                        end
                        save(full_metadata_name{ii},'triggerTime','frameTimeLimits','view_direction','viewROI','frameRate','frameSize');
                    end

                end
            end
        end 