%dellens@umich.edu
%4/22/2016 beta, very beta
%readBinAvi.m reads binary video files and converts them to .avi files
%used for converting corrupted .bin files from R0104


<<<<<<< HEAD
% clc;    % Clear the command window.
% close all;  % Close all figures (except those of imtool.)
%imtool close all;  % Close all imtool figures.
% clear;  % Erase all existing variables.
% workspace;  % Make sure the workspace panel is showing.
=======
clc;    % Clear the command window.
close all;  % Close all figures (except those of imtool.)
%imtool close all;  % Close all imtool figures.
clear;  % Erase all existing variables.
workspace;  % Make sure the workspace panel is showing.
>>>>>>> origin/master
%fontSize = 22;

%MAC
%fid = '/Users/damienjellens/Documents/TestVideos/R0104_20151217a'; %bad bin files
<<<<<<< HEAD
% fid = '/Users/damienjellens/Documents/TestVideos/R0000_20160225a_goodBin'; %good bin files
%fid = '/Users/damienjellens/Documents/TestVideos/R0112_20160314a'; %good bin files

rootDir = '/Volumes/RecordingsLeventhal04/SkilledReaching/R102-108 unconverted bin vids';
fidProp = dir(rootDir);

=======
fid = '/Users/damienjellens/Documents/TestVideos/R0000_20160225a_goodBin'; %good bin files
%fid = '/Users/damienjellens/Documents/TestVideos/R0112_20160314a'; %good bin files
fidProp = dir(fid);
>>>>>>> origin/master
numberOfVideos = 1;
numberOfFrames = 4;


% Set up the movie structure.
% Preallocate movie, which will be an array of structures.
% First get a cell array with all the frames.
allTheFrames = cell(numberOfFrames,1);
vidHeight = 1024;
vidWidth = 2040;
allTheFrames(:) = {zeros(vidHeight, vidWidth, 3, 'uint8')};
% Next get a cell array with all the colormaps.
allTheColorMaps = cell(numberOfFrames,1);
allTheColorMaps(:) = {zeros(256, 3)};
% Now combine these to make the array of structures.
myMovie = struct('cdata', allTheFrames, 'colormap', allTheColorMaps);
% Create a VideoWriter object to write the video out to a new, different file.
% writerObj = VideoWriter('problem_3.avi');
% open(writerObj);
% Need to change from the default renderer to zbuffer to get it to work right.
% openGL doesn't work and Painters is way too slow.
set(gcf, 'renderer', 'zbuffer');


% Create the movie.
% Get a list of x and y coordinates for every pixel in the x-y plane.
%[x, y] = meshgrid(x1d, y1d);

for fnameIt = 1 : numberOfVideos;
    fnameIt;
    fnameStruc = fidProp(4+fnameIt); %check dir for ordinalimg value of first .bin file, 2 or 3 usually... THIS IS A DUMB WAY TO DO THIS
    fname = (fnameStruc.name);
    %figure
    %hold
    
for frameIndex = 1 : numberOfFrames;
    frameIndex;
    %read individual binary image
    frame_num = frameIndex;
    img = read_sr_binImg(fname,frame_num);
    
    %subplot(13,100,frame_num)
    %figure
    %imshow(img)
    
    %I = imread('mandi.tif');
<<<<<<< HEAD
        imgRGB = demosaic(img,'gbrg');
=======
        imgRGB = demosaic(img,'bggr');
>>>>>>> origin/master
        figure;
        imshow(imgRGB);
        %imgRGB = demosaic(img,'gbrg');
        %figure
        %imshow(imgRGB);
        %imgRGB = demosaic(img,'grbg');
        %figure
        %imshow(imgRGB);
        %imgRGB = demosaic(img,'rggb');
        %figure
        %imshow(imgRGB);
        
        
        
%imshow(I);
%figure
%imshow(imgRGB);

    %apply Bayer decode
    
    %apply colormap
    
    rgb = colormap(jet(2));
    
    %create new frame
    
    colorFrame = im2frame(uint8(imgRGB), rgb);
    %figure
    %imshow(colorFrame)
    
    
% After this loop starts, BE SURE NOT TO RESIZE THE WINDOW AS IT'S SHOWING THE FRAMES, or else you won't be able to save it.

% close(writerObj);

    %frameIndex = 1 : numberOfFrames;
	%z = exp(-(x-t(frameIndex)).^2-(y-t(frameIndex)).^2);
	%cla reset;
	% Enlarge figure to full screen.
% 	set(gcf, 'Units', 'Normalized', 'Outerposition', [0, 0, 1, 1]);
	%surf(x,y,z);
	%axis('tight')
	%zlim([0, 1]);
	%caption = sprintf('Frame #%d of %d, t = %.1f', frameIndex, numberOfFrames, t(frameIndex));
	%title(caption, 'FontSize', 15);
	%drawnow;
	thisFrame = getframe(gca); %gca?
    %thisFrame = imgRGB;
    %thisFrame = colorFrame;
    %gca
	% Write this frame out to a new video file.
%  	writeVideo(writerObj, thisFrame);

	myMovie(frameIndex) = thisFrame;
    close all
end




end


% See if they want to replay the movie.
%message = sprintf('Done creating movie\nDo you want to play it?');
%button = questdlg(message, 'Continue?', 'Yes', 'No', 'Yes');
%drawnow;	% Refresh screen to get rid of dialog box remnants.
%close(hFigure);
%if strcmpi(button, 'Yes')
%	hFigure = figure;
	% Enlarge figure to full screen.
	% set(gcf, 'Units', 'Normalized', 'Outerposition', [0, 0, 1, 1]);
%	title('Playing the movie we created', 'FontSize', 15);
	% Get rid of extra set of axes that it makes for some reason.
%	axis off;
	% Play the movie.
%	movie(myMovie);
%	close(hFigure);
%end


% See if they want to save the movie to an avi file on disk.
%promptMessage = sprintf('Do you want to save this movie to disk?');
%titleBarCaption = 'Continue?';
%button = questdlg(promptMessage, titleBarCaption, 'Yes', 'No', 'Yes');
%if strcmpi(button, 'yes')
	% Get the name of the file that the user wants to save.
	% Note, if you're saving an image you can use imsave() instead of uiputfile().
    
	startingFolder = pwd;
    folder = startingFolder;
	%defaultFileName = {'*.avi';'*.mp4';'*.mj2'}; %fullfile(startingFolder, '*.avi');
	%[baseFileName, folder] = uiputfile(defaultFileName, 'Specify a file');
    %[baseFileName, folder] = fullfile(startingFolder,fname);
    %filepart(baseFileN
	%if baseFileName == 0
		% User clicked the Cancel button.
	%	return;
	%end
    %fileparts(fname)
	fullFileName = fullfile(folder, fname);
	% Create a video writer object with that file name.
	% The VideoWriter object must have a profile input argument, otherwise you get jpg.
	% Determine the format the user specified:
	[folder, baseFileName, ext] = fileparts(fullFileName);
	
    %switch lower(ext)
	%	case '.jp2'
	%		profile = 'Archival';
	%	case '.mp4'
	%		profile = 'MPEG-4';
	%	otherwise
			% Either avi or some other invalid extension.
			profile = 'Motion JPEG avi';
            %fps = 300;
            
           %  Specifying a profile sets default values for video properties such 
    %as VideoCompressionMethod. Possible values:
     % 'Archival'         - Motion JPEG 2000 file with lossless compression
      %'Motion JPEG AVI'  - Compressed AVI file using Motion JPEG codec.
                          % (default)
      %'Motion JPEG 2000' - Compressed Motion JPEG 2000 file
      %'MPEG-4'           - Compressed MPEG-4 file with H.264 encoding 
                           %(Windows 7 and Mac OS X 10.7 only)
      %'Uncompressed AVI' - Uncompressed AVI file with RGB24 video.
      %'Indexed AVI'      - Uncompressed AVI file with Indexed video.
      %'Grayscale AVI'    - Uncompressed AVI file with Grayscale video.
      
      
	%end
	writerObj = VideoWriter(baseFileName, profile);
	open(writerObj);
	% Write out all the frames.
	numberOfFrames = length(myMovie);
	for frameNumber = 1 : numberOfFrames
	   writeVideo(writerObj, myMovie(frameNumber));
    end
    %obj = VideoWriter(baseFileName)
	close(writerObj);
	% Display the current folder panel so they can see their newly created file.
	%cd(folder);
	%filebrowser;
	%message = sprintf('Finished creating movie file\n      %s.\n\nDone with demo!', fullFileName);
	%uiwait(helpdlg(message));
close all;

%else
%	uiwait(helpdlg('Done with demo!'));
%end
<<<<<<< HEAD
=======


>>>>>>> origin/master
