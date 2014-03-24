function testColorBlob(videoFile,hsvBounds)
    video = VideoReader(videoFile);
    
    newVideo = VideoWriter('r_processed.avi', 'Motion JPEG AVI');
    newVideo.Quality = 90;
    newVideo.FrameRate = 30;
    open(newVideo);
    
    for i=1:video.NumberOfFrames
        disp(i)
        image = read(video,i);
        hsv = rgb2hsv(image);

        h = hsv(:,:,1);
        s = hsv(:,:,2);
        v = hsv(:,:,3);

        % bound the hue element using all three bounds
        h(h < hsvBounds(1) | h > hsvBounds(2)) = 0;
        h(s < hsvBounds(3) | s > hsvBounds(4)) = 0;
        h(v < hsvBounds(5) | v > hsvBounds(6)) = 0;

        mask = bwdist(h) < 3;
        mask = imfill(mask, 'holes');
        mask = imerode(mask, strel('disk',1));
        
        % find "center of gravity"
        bwmask = bwdist(~mask);
        [maxGravityValue,~] = max(bwmask(:));
        
        if(maxGravityValue > 0)
            [centerGravityColumns,centerGravityRows] = find(bwmask == maxGravityValue);
            centerGravityRow = mean(centerGravityRows);
            centerGravityColumn = mean(centerGravityColumns);

            % draw lines between blobs and centroid
            networkMask = zeros(size(image,1),size(image,2),3);
            
            CC = bwconncomp(mask);
            L = labelmatrix(CC);
            props = regionprops(L,'Centroid');
            regions = size(props,1);

            for i=1:regions
                networkMask = insertShape(networkMask,'Line',[centerGravityRow centerGravityColumn...
                    props(i).Centroid],'Color','White');
            end
            networkMask = im2bw(rgb2gray(networkMask));
            networkMask = imdilate(networkMask,strel('disk',2));
            
            CC = bwconncomp(networkMask|mask);
            L = labelmatrix(CC);
            props = regionprops(L,'ConvexHull');
            

            hull = props.ConvexHull;
            [northPole,southPole] = poles(hull);
            image = insertShape(image,'FilledCircle',[centerGravityRow centerGravityColumn 8]);
            if(abs(mean(northPole-southPole)) > 10)
                image = insertShape(image,'Line',[centerGravityRow centerGravityColumn northPole;...
                    centerGravityRow centerGravityColumn southPole]);
                image = insertShape(image,'FilledCircle',[northPole 3]);
                image = insertShape(image,'FilledCircle',[southPole 3]);
            end
%             [maxArea,maxIndex] = max([props.Area]);
%             maxCentroid = props(maxIndex).Centroid;

            imshow(image)

            % remove center of paw to resdistribute blobs

            % perform blob analysis again

            % connect all centroids to center of gravity

            % get convex hull of entire image



                writeVideo(newVideo,image);


            %hold on
            %plot(colsOfMaxes,rowsOfMaxes,'*')
%                 centerMask = zeros(size(mask,1),size(mask,2));
%                 centerMask(round(maxCentroid(2)),round(maxCentroid(1))) = 1;
%                 centerMask = bwdist(centerMask) < 35;
%                 mask(centerMask > 0) = 0;

        end
        %imshow(mask)
    end
    close(newVideo);
end