% detect checkerboard calibration images, 20180605

% calImageDir = '/Users/dan/Box Sync/Leventhal Lab/Skilled Reaching Project/Calibration Images';
% calImageDir = '/Users/dleventh/Box Sync/Leventhal Lab/Skilled Reaching Project/Calibration Images';
calImageDir = '/Volumes/Tbolt_01/Skilled Reaching/calibration_images';

camParamFile = '/Users/dan/Documents/Leventhal lab github/SkilledReaching/Manual Tracking Analysis/ConvertMarkedPointsToReal/cameraParameters.mat';
% camParamFile = '/Users/dleventh/Box Sync/Leventhal Lab/Skilled Reaching Project/multiview geometry/cameraParameters.mat';
load(camParamFile);

saveMarkedImages = true;
markRadius = 5;
colorList = {'red','green','blue'};
markOpacity = 1;

% first row red, second row green, third row blue
direct_hsvThresh = [0,0.1,0.9,1,0.9,1;
                    0.33,0.1,0.9,1,0.9,1;
                    0.66,0.1,0.9,1,0.9,1];

mirror_hsvThresh = [0,0.1,0.85,1,0.85,1;
                    0.30,0.05,0.85,1,0.85,1;
                    0.60,0.1,0.85,1,0.85,1];

boardSize = [4 5];
points_per_board = prod(boardSize-1);

cd(calImageDir)

anticipatedBoardSize = [4 5];

imgList = dir('GridCalibration_*.png');
csvList = dir('GridCalibration_*.csv');
% load test image
A = imread(imgList(1).name,'png');
h = size(A,1); w = size(A,2);
% [x,y,w,h]. first row is for direct cube view, second row tpp mirror,
% third row left mirror, fourth row right mirror
rightMirrorLeftEdge = 1700;
ROIs = [700,270,650,705;
        750,1,600,400;
        1,400,350,500;
        rightMirrorLeftEdge,400,w-rightMirrorLeftEdge,500];
    
numBoards = size(ROIs,1) - 1;

mirrorOrientation = {'top','left','right'};
   
cd(calImageDir);

[imFiles_from_same_date, img_dateList] = groupCalibrationImagesbyDate(imgList);
[csvFiles_from_same_date, csv_dateList] = group_csv_files_by_date(csvList);
numDates = length(csv_dateList);

for iDate = 1 : numDates
    
    curDate = csv_dateList{iDate};
    num_csvPerDate = length(csvFiles_from_same_date{iDate});
    
    % find this date in the img_dateList
    img_date_idx = find(strcmp(img_dateList, curDate));
    
    numImgPerDate = length(imFiles_from_same_date{img_date_idx});
    img = cell(1, numImgPerDate);
    
    csvData = cell(1,num_csvPerDate);
    csvNumList = zeros(1,num_csvPerDate);
    for i_csv = 1 : num_csvPerDate
        cur_csvName = csvFiles_from_same_date{iDate}{i_csv};
        C = textscan(cur_csvName,['GridCalibration_' curDate '_%d.csv']);
        csvNumList(i_csv) = C{1};
        csvData{i_csv} = readFIJI_csv(cur_csvName);
    end
    
    % load images, but only ones for which there is a .csv file
    imgNumList = zeros(1,numImgPerDate);
    numImgLoaded = 0;
    if exist('img','var')
        clear img
    end
    for iImg = 1 : numImgPerDate
        curImgName = imFiles_from_same_date{img_date_idx}{iImg};
        C = textscan(curImgName,['GridCalibration_' curDate '_%d.png']);
        imageNumber = C{1};
        if any(csvNumList == imageNumber)
            % load this image
            numImgLoaded = numImgLoaded + 1;
            img{numImgLoaded} = imread(curImgName);
            imgNumList(numImgLoaded) = imageNumber;
        end
    end
    
    [directBorderMask, initDirBorderMask] = findDirectBorders(img, direct_hsvThresh, ROIs);
    [mirrorBorderMask, initMirBorderMask] = findMirrorBorders(img, mirror_hsvThresh, ROIs);
    
    % undistort masks - assume points were marked on the undistorted images
    for ii = 1 : length(directBorderMask)
        for jj = 1 : size(directBorderMask{ii},3)
            directBorderMask{ii}(:,:,jj) = undistortImage(squeeze(directBorderMask{ii}(:,:,jj)), cameraParams);
        end
    end
    for ii = 1 : length(mirrorBorderMask)
        for jj = 1 : size(mirrorBorderMask{ii},3)
            mirrorBorderMask{ii}(:,:,jj) = undistortImage(squeeze(mirrorBorderMask{ii}(:,:,jj)), cameraParams);
        end
    end
    
    % read in corresponding .mat file if it exists
    matFileName = ['GridCalibration_' csv_dateList{iDate} '_auto.mat'];
    foundMatFile = false;
    if exist(matFileName,'file')
        load(matFileName);
        foundMatFile = true;
    else
        % create arrays to hold the marked checkerboard points if not
        % already loaded from the auto-detection .mat file
        directChecks = NaN(prod(boardSize-1),2,size(directBorderMask{1},3),numImgPerDate);
        mirrorChecks = NaN(prod(boardSize-1),2,size(mirrorBorderMask{1},3),numImgPerDate);
    end
    
    % now loop through .csv files
    for i_csv = 1 : num_csvPerDate
        
        % figure out what image index to use
        img_idx = find(imgNumList == csvNumList(i_csv));
        
        % fill out the directChecks and mirrorChecks arrays. Assume that
        % the image number is the correct index to use. Note that
        % previously labeled images should be used in Fiji, so the image
        % should already be undistorted
        [new_directChecks, new_mirrorChecks] = assign_csv_points_to_checkerboards(directBorderMask{img_idx}, ...
                                                mirrorBorderMask{img_idx}, ...
                                                ROIs, csvData{i_csv}, ...
                                                anticipatedBoardSize, ...
                                                mirrorOrientation);
                                            
        % COMMENT OUT LATER
%         img_ud = undistortImage(img{img_idx},cameraParams);
%         figure(1)
%         imshow(img_ud)
%         hold on
%         cList = ['r','g','b'];
%         for ii = 1 : 3
%             toPlot = new_directChecks(:,:,ii);
%             if ~all(isnan(toPlot(:)))
%                 scatter(toPlot(:,1),toPlot(:,2),cList(ii));
%             end
%             toPlot = new_mirrorChecks(:,:,ii);
%             if ~all(isnan(toPlot(:)))
%                 scatter(toPlot(:,1),toPlot(:,2),cList(ii));
%             end
%         end
        % update directChecks and mirrorChecks arrays
        old_directChecks = directChecks;
        old_mirrorChecks = mirrorChecks;
        for iBoard = 1 : size(new_directChecks,3)
            testPoints = squeeze(new_directChecks(:,:,iBoard));
            if all(isnan(testPoints(:)))
                % no marked points were found for this board
                continue;
            end
            directChecks(:,:,iBoard,imgNumList(img_idx)) = testPoints;

            testPoints = squeeze(new_mirrorChecks(:,:,iBoard));
            if all(isnan(testPoints(:)))
                % no marked points were found for this board
                continue;
            end
            mirrorChecks(:,:,iBoard,imgNumList(img_idx)) = testPoints;
                
        end
%         figure(2)
%         imshow(img_ud)
%         hold on
%         for ii = 1 : 3
%             toPlot = directChecks(:,:,ii,imgNumList(img_idx));
%             if ~all(isnan(toPlot(:)))
%                 scatter(toPlot(:,1),toPlot(:,2),cList(ii));
%             end
%             toPlot = mirrorChecks(:,:,ii,imgNumList(img_idx));
%             if ~all(isnan(toPlot(:)))
%                 scatter(toPlot(:,1),toPlot(:,2),cList(ii));
%             end
%         end
            
    end
    
    allMatchedPoints = NaN(points_per_board * numImgPerDate, 2, 2, numBoards);
    for iImg = 1 : numImgPerDate
        for iBoard = 1 : numBoards
            curDirectChecks = squeeze(directChecks(:,:,iBoard,iImg));
            curMirrorChecks = squeeze(mirrorChecks(:,:,iBoard,iImg));
            
            if all(isnan(directChecks(:))) || all(isnan(mirrorChecks(:)))
                % don't have matching points for the direct and mirror view
                continue;
            end 
            matchIdx = matchCheckerboardPoints(curDirectChecks, curMirrorChecks, mirrorOrientation{iBoard});

            matchStartIdx = (iImg-1) * points_per_board + 1;
            matchEndIdx = (iImg) * points_per_board;

            allMatchedPoints(matchStartIdx:matchEndIdx,:,1,iBoard) = curDirectChecks(matchIdx(:,1),:);
            allMatchedPoints(matchStartIdx:matchEndIdx,:,2,iBoard) = curMirrorChecks(matchIdx(:,2),:);
        end
    end
    
    matSaveFileName = ['GridCalibration_' dateList{iDate} '_all.mat'];
    imFileList = imFiles_from_same_date{iDate};
    save(matFileName, 'directChecks','mirrorChecks','allMatchedPoints','cameraParams','imFileList');
    
    if saveMarkedImages
        for iImg = 1 : numImgPerDate
            
            % was there a previously marked image?
            curImgName = imFileList{iImg};
            oldImg = imread(curImgName,'png');
            newImg = undistortImage(oldImg,cameraParams);
            
            for iBoard = 1 : numBoards
                
                if dir_foundValidPoints(iBoard,iImg)
                    curChecks = squeeze(directChecks(:,:,iBoard,iImg));
                    for i_pt = 1 : size(curChecks,1)
                        newImg = insertShape(newImg,'filledcircle',...
                            [curChecks(i_pt,1),curChecks(i_pt,2),markRadius],...
                            'color',colorList{iBoard},'opacity',markOpacity);
                    end
                end
                
                if mir_foundValidPoints(iBoard,iImg)
                    curChecks = squeeze(mirrorChecks(:,:,iBoard,iImg));
                    for i_pt = 1 : size(curChecks,1)
                        newImg = insertShape(newImg,'filledcircle',...
                            [curChecks(i_pt,1),curChecks(i_pt,2),markRadius],...
                            'color',colorList{iBoard},'opacity',markOpacity);
                    end
                end 
            end
            curImgName = imFiles_from_same_date{iDate}{iImg};
            newImgName = strrep(curImgName,'.png','_marked.png');
            imwrite(newImg,newImgName,'png');
        end       
    end
end