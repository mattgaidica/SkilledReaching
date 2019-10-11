% script to crop video with the same ROI as the extracted frames

ratList = {'R0158','R0159','R0160','R0161','R0169','R0170','R0171','R0183',...
           'R0184','R0186','R0187','R0189','R0190',...
           'R0191','R0192','R0193','R0194','R0195','R0196','R0197','R0198',...
           'R0216','R0217','R0218','R0219','R0220','R0223','R0225','R0227',...
           'R0228','R0229','R0230'};
       
repeatCalculations = true;   % if cropped video file already exists, don't repeat?

vidRootPath = '/Volumes/SharedX/Neuro-Leventhal/data/Skilled Reaching/SR_Opto_Raw_Data';
sharedX_root_metadata_SavePath = '/Volumes/SharedX/Neuro-Leventhal/data/Skilled Reaching/DLC output/Rats';
cropped_vidSaveRootPath = fullfile('/Volumes','LL EXHD #2','Skilled Reaching');
labeledBodypartsFolder = '/Volumes/LL EXHD #2/DLC output';
cd(labeledBodypartsFolder)
ratFolders = dir('R*');
numRatFolders = length(ratFolders);

xlDir = '/Users/dan/Box Sync/Leventhal Lab/Skilled Reaching Project/Scoring Sheets';
csvfname = fullfile(xlDir,'rat_info_pawtracking_20190819.csv');
ratInfo = readtable(csvfname);
ratInfo_IDs = [ratInfo.ratID];

useSessionsFrom_DLCoutput_folder = true;
sessions_to_analyze = getSessionsToAnalyze();

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
        if ischar(thisRatInfo.tattooDate{1})
            tattooDateString = thisRatInfo.tattooDate{1};
            tattooDate = datetime(tattooDateString);
        elseif isdatetime(thisRatInfo.tattooDate{1})
            tattooDate = thisRatInfo.tattooDate{1};
        end
    elseif isdatetime(thisRatInfo.tattooDate)
        tattooDate = thisRatInfo.tattooDate;
    if ischar(thisRatInfo.tattooDate)
        tattooDateString = thisRatInfo.tattooDate;
        tattooDate = datetime(tattooDateString);
    end
    tattooDateString = datestr(tattooDate,'yyyymmdd');
    
    if iscell(thisRatInfo.digitColors)
        digitColors = thisRatInfo.digitColors{1};
    else
        digitColors = thisRatInfo.digitColors;
    end
    
    % DL modifications for using the ratInfo table
    validRatInfo = findSubTable(ratInfo,'pawPref',selectPawPref,'digitColors',digitColors);
    numValidRats = size(validRatInfo,1);

    if exist('sessionsToExtract','var')
        clear sessionsToExtract
    end
    if useSessionsFrom_DLCoutput_folder
        DLCout_folder = fullfile(labeledBodypartsFolder,ratID);
        cd(DLCout_folder);

        sessionDirectories = listFolders([ratID '_2*']);
        for ii = 1 : length(sessionDirectories)
            sessionsToExtract(ii).ratID = ratID;
            sessionsToExtract(ii).session = sessionDirectories{ii}(7:end);
            sessionsToExtract(ii).sessionDate = sessionDirectories{ii}(7:end-1);
        end

    else
        % use sessions defined by the sessions table
        % WORKING HERE TO IDENTIFY SESSIONSTOEXTRACT FROM sessionTable
        % load the sessions table
        cd(ratFolder);
        sessionCSV = [ratID '_sessions.csv'];
        sessionTable = readSessionInfoTable(sessionCSV);

        sessions_for_analysis = extractSpecificSessions(sessionTable,sessions_to_analyze);
        
        for ii = 1 : size(sessions_for_analysis,1)
            
            sessionsToExtract(ii).ratID = ratID;
            sessionsToExtract(ii).sessionDate = sessionTable(ii,:).date;
        end
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
    
        sessionDateString = datestr(sessionsToExtract(iSess).sessionDate,'yyyymmdd');
        
        if isempty(tattooDateString)
            selectTattoo = 'no';
        else
            if tattooDate < sessionsToExtract(iSess).sessionDate
                selectTattoo = 'no';
            else
                selectTattoo = 'yes';
            end
        end
        
        if strcmpi(selectTattoo,'yes')
            cropped_vidSavePath = fullfile(cropped_vidSaveRootPath,[ratID '_cropped'],[selectPawPref, '_paw_tattooed_', digitColors]);
        else
            cropped_vidSavePath = fullfile(cropped_vidSaveRootPath,[ratID '_cropped'],[selectPawPref, '_paw_markerless']);
        end 

        if ~exist(cropped_vidSavePath,'dir')
            mkdir(cropped_vidSavePath);
        end

        viewList = {'direct','left','right'};
        viewSavePath = cell(1,3);
        for iView = 1 : length(viewList)
            viewSavePath{iView} = fullfile(cropped_vidSavePath, [viewList{iView} '_view']);
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