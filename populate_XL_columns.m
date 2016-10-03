xl_directory = '/Users/dan/Box Sync/Leventhal Lab/Skilled Reaching Project/R118_136_analysis';
% xl_file = 'R118_R136_vidTimes.csv';
% xl_file = fullfile(xl_directory, xl_file);

trialRow = 7;

root_SRdir = '/Volumes/RecordingsLeventhal04/SkilledReaching/';

opto_SR_rats = getOptoSR_rats();

for i_rat = 1 : length(opto_SR_rats)
    
    ratID = opto_SR_rats(i_rat).ratID;
    
    text_file = sprintf('R%03d_vidTimes.txt',ratID);
    text_file = fullfile(xl_directory,text_file);
    
    startDateStr = opto_SR_rats(i_rat).startDate;
    endDateStr = opto_SR_rats(i_rat).endDate;
    
    startDateNum = datenum(startDateStr,'mm-dd-yyyy');
    endDateNum = datenum(endDateStr,'mm-dd-yyyy');
    
    ratID_str = sprintf('R%04d',ratID);
    rawDataDir = fullfile(root_SRdir, ratID_str, [ratID_str '-rawdata']);
    
    if ~exist(rawDataDir,'dir'); continue; end
    
    cd(rawDataDir);
    
    dirList = dir;
    
    sessionDates = cell(1,1);
    numValidDates = 0;
    
    numArrayToWrite = 1 : 100;%finalVidNumber(end);
    numArrayToWrite = numArrayToWrite';
	headerCellArray = {'Trial'};
    for iDir = 1 : length(dirList)
        if length(dirList(iDir).name) < 15; continue; end
        
        curDate = dirList(iDir).name(7:14);
        curDateNum = datenum(curDate,'yyyymmdd');
        curDateStr = datestr(curDateNum,'mm-dd-yyyy');
        
        if curDateNum < startDateNum || curDateNum > endDateNum
            continue;
        end
        
        if any(strcmpi(sessionDates, curDate))    % all the folders for this date should have already been checked
            continue;
        end
        numValidDates = numValidDates + 1;
        sessionDates{numValidDates} = curDate;
            
        % find all sessions that occurred on the current date
        numSessionsPerDate = 0;
        for ii = 1 : length(dirList)
            if length(dirList(ii).name) < 15; continue; end
            if strcmpi(dirList(ii).name(7:14), curDate)
                numSessionsPerDate = numSessionsPerDate + 1;
                sessionDateIdx(numSessionsPerDate) = ii;
            end
        end
        
        
        numValidVids = 0;
        vidTimeStr = cell(1,1);%blanks(8);
        finalVidNumberStr = blanks(3);
        vidSession = [];
        vidNumber = [];
        lastSessionVidNum = zeros(numSessionsPerDate,1);
        for ii = 1 : numSessionsPerDate
            
            curSessionDir = fullfile(rawDataDir, dirList(sessionDateIdx(ii)).name);
            cd(curSessionDir);
            
            vidList = dir('*.avi');
            
            if isempty(vidList); continue; end
            
            for iVid = 1 : length(vidList)
                if vidList(iVid).bytes < 10000; continue; end
                if strcmp(vidList(iVid).name(1:2),'._'); continue; end
                
                numValidVids = numValidVids + 1;
                tempTimeStr = vidList(iVid).name(16:23);
                tempTimeStr = strrep(tempTimeStr,'-',':');
                
                vidNumberStr = vidList(iVid).name(25:27);
                vidNumber(numValidVids,1) = str2double(vidNumberStr);
                vidTimeStr{numValidVids} = tempTimeStr;
                vidSession(numValidVids) = ii;
                                    
            end
%             if ii == 1
%                 lastSessionVidNum(ii) = vidNumber(numValidVids);
%                 finalVidNumber = vidNumber;
%             else
%                 lastSessionVidNum(ii) = lastSessionVidNum(ii-1) + vidNumber(numValidVids);
%                 finalVidNumber = [finalVidNumber;vidNumber + lastSessionVidNum(ii-1)];
%             end
            
        end
        
        if numValidVids == 0; continue; end
        
        % now have a full list of video numbers and times; only use the
        % unique times
        
        % now construct the matrices to write into the xl spreadsheet
%         idxToEliminate = false(numValidVids,1);
%         updatedTimeStrArray = cell(length(vidTimeStr),1);
%         updatedVidNums = zeros(size(vidNumber));
        for ii = 1 : numValidVids
            % comnpare current date and vid number to all others, make sure there's only one time/number combo in the list
            testCellArray = vidTimeStr;
            testCellArray{ii} = 'test';
            repeatedTimes = strcmpi(testCellArray, vidTimeStr{ii});
            isTimeRepeated = any(repeatedTimes);
            if isTimeRepeated
                vidTimeStr{ii} = '';
                vidNumber(ii) = 0;
%                 testNum = vidNumber(ii);
%                 testNumArray = vidNumber;
%                 testNumArray(ii) = 0;
%                 testNumArray = testNumArray(repeatedTimes);
%                 isNumRepeated = any(testNumArray == testNum);
%                 
%                 if isNumRepeated    % the same video is listed twice; eliminate the one at this index
%                     vidTimeStr{ii} = '';
%                     vidNumber(ii) = 0;
%                 end
            end
        end
%         vidTimeStr = updatedTimeStrArray;
%         vidNumber = updatedVidNums;
        idxToEliminate = (vidNumber == 0);
        
        if any(idxToEliminate)
            updatedTimeStrArray = {};
            vidNumber = vidNumber(~idxToEliminate);
            numUpdatedTimes = 0;
            for ii = 1 : numValidVids
                if ~idxToEliminate(ii)
                    numUpdatedTimes = numUpdatedTimes + 1;
                    updatedTimeStrArray{numUpdatedTimes} = vidTimeStr{ii};
                end
            end
            vidTimeStr = updatedTimeStrArray;
        end
        numValidVids = length(vidNumber);
        
        % sort videos by timestamp
        vidTimeNum = zeros(numValidVids,1);
        for ii = 1 : numValidVids
            vidTimeNum(ii) = datenum(vidTimeStr{ii},'HH:MM:SS');
        end
        [sortedTime, idx] = sort(vidTimeNum);
        vidNumber = vidNumber(idx);
        
        oldVidTimeStr = vidTimeStr;
        for ii = 1 : numValidVids
            vidTimeStr{ii} = oldVidTimeStr{idx(ii)};
        end

        finalVidNumber = vidNumber;
        lastSessionEndNumber = 0;
        for ii = 1 : length(vidNumber)-1
            if vidNumber(ii+1) <= vidNumber(ii)    % this must be a point where the computer crashed
                lastSessionEndNumber = lastSessionEndNumber + vidNumber(ii);
            end
            finalVidNumber(ii+1) = lastSessionEndNumber + vidNumber(ii+1);
        end    
        
        % WORKING HERE - NOW NEED TO CREATE THE LISTS TO CUT AND PASTE INTO
        % EXCEL, AND SAVE THEM AS .CSV FILES THAT CAN BE LOADED BY EXCEL
        finalVidTimeStr = cell(100,1);%blanks(8);
        for ii = 1 : finalVidNumber(end)
            vidNumIdx = (vidNumber == ii);
%             vidNum = 
            if ~any(vidNumIdx)
                finalVidTimeStr{ii} = blanks(8);
            else
                finalVidTimeStr{ii} = vidTimeStr{vidNumIdx};
            end
        end
        
        if numValidDates == 1
            finalCell = mat2cell(numArrayToWrite,[length(numArrayToWrite)],[1]);
        else
            for ii = 1 : 100
                finalCell{ii,numValidDates} = finalVidTimeStr{ii};
            end
            headerCellArray{1,numValidDates} = curDateStr;
        end
        
%         sheetName = sprintf('R%03d',ratID);
%         if numValidDates == 1
%             trialHeaderCell = sprintf('A%d',trialRow);
%             trialListCell = sprintf('A%d',trialRow + 1);
%             xlswrite(xl_file,'Trial',sheetName,trialHeaderCell);
%             xlswrite(xl_file,numArrayToWrite,sheetName,trialListCell);
%         end
%         dateCell = [num2letters(numValidDates + 1), num2str(trialRow+1)];
    end
    
    T = cell2table(finalCell,'VariableNames',headerCellArray);
end