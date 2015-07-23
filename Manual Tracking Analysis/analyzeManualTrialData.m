%Titus John
%Leventhal Lab
%7/19/2015
%% About analyze manual trial data
%This program will take in the manual paw data (ie. the xy coordinates)
%for the three given prespectives and spit out analysis 
%Paramaters read in from Paw_Points Tracking Data file

%Each of these is take in for the prespectives Left, Right, Center

%Pellet Center

%Center of Back Surface of Paw

%Thumb Proximal
%Thumb Distal

% Index proximal
% Index middle
% Index distal
% 
% Middle proximal
% Middle middle
% Middle distal
% 
% Ring proximal
% Ring middle
% Ring distal
% 
% Pinky proximal
% Pinky middle
% Pinky distal


%% Master function for calling all the seperate functions written into script


%Feed in the master 
function analyzeManualTrialData(pawPointsData)
    
    [pelletCenter, pawBackCenter, thumbProx, thumbDist, indexProx, indexMid, indexDist, middleProx, middleMid, middleDist, ringProx, ringMid, ringDist, pinkyProx, pinkyMid, pinkyDist] = readDataFromPawPoints (pawPointsData);
    [indexDistLeft, indexDistCenter, indexDistRight,middleDistLeft, middleDistCenter, middleDistRight,ringDistLeft, ringDistCenter, ringDistRight, pinkyDistLeft, pinkyDistCenter, pinkyDistRight] = normalizeData(pelletCenter, pawBackCenter, thumbProx, thumbDist, indexProx, indexMid, indexDist, middleProx, middleMid, middleDist, ringProx, ringMid, ringDist, pinkyProx, pinkyMid, pinkyDist);
    [pawSpreadDistPILeft,pawSpreadDistPICenter,pawSpreadDistPIRight]= calc2DistancePawSpread(pinkyDistLeft, indexDistLeft, pinkyDistCenter, indexDistCenter, pinkyDistRight, indexDistRight);
    plotPawangle(indexDistCenter,middleDistCenter,ringDistCenter,pinkyDistCenter)
    %plot2DisancePawSpread (pawSpreadDistPILeft,pawSpreadDistPICenter,pawSpreadDistPIRight);

end

%% Function to read the data from the rat data array structure into indciudal arrays
function [pelletCenter, pawBackCenter, thumbProx, thumbDist, indexProx, indexMid, indexDist, middleProx, middleMid, middleDist, ringProx, ringMid, ringDist, pinkyProx, pinkyMid, pinkyDist] = readDataFromPawPoints (pawPointsData)

pelletCenter = [];
pawBackCenter = [];

thumbProx = [];
thumbDist = [];

indexProx = [];
indexMid = [];
indexDist= [];

middleProx= [];
middleMid = [];
middleDist= [];

ringProx = [];
ringMid= [];
ringDist = [];

pinkyProx = [];
pinkyMid = [];
pinkyDist = [];





overallCounter = 1;

    for i=1:5
        for j=1:3
            for k=overallCounter:(overallCounter+15) 
                if overallCounter<241
                    
                     %Pellet Center 
                     if mod(overallCounter,16) == 1
                        pelletCenter{i,j} = [pawPointsData(k,7),pawPointsData(k,8)];
                     end
                     %Back of paw
                     if mod(overallCounter,16) == 2
                        pawBackCenter{i,j} = [pawPointsData(k,7),pawPointsData(k,8)];
                     end

                     %Thumb
                     if mod(overallCounter,16) == 3
                        thumbProx{i,j} = [pawPointsData(k,7),pawPointsData(k,8)];
                     end

                     if mod(overallCounter,16) == 4
                        thumbDist{i,j} = [pawPointsData(k,7),pawPointsData(k,8)];
                     end
                     
                     
                     %Index
                     if mod(overallCounter,16) == 5
                        indexProx{i,j} = [pawPointsData(k,7),pawPointsData(k,8)];
                     end
                     
                     if mod(overallCounter,16) == 6
                        indexMid{i,j} = [pawPointsData(k,7),pawPointsData(k,8)];
                     end

                     if mod(overallCounter,16) == 7
                        indexDist{i,j} = [pawPointsData(k,7),pawPointsData(k,8)];
                     end

                     %Middle
                     if mod(overallCounter,16) == 8
                        middleProx{i,j} = [pawPointsData(k,7),pawPointsData(k,8)];
                     end


                     if mod(overallCounter,16) == 9
                        middleMid{i,j} = [pawPointsData(k,7),pawPointsData(k,8)];
                     end

                      if mod(overallCounter,16) == 10
                        middleDist{i,j} = [pawPointsData(k,7),pawPointsData(k,8)];
                      end

                
                     %Ring
                     if mod(overallCounter,16) == 11
                        ringProx{i,j} = [pawPointsData(k,7),pawPointsData(k,8)];
                     end


                     if mod(overallCounter,16) == 12
                        ringMid{i,j} = [pawPointsData(k,7),pawPointsData(k,8)];
                     end


                      if mod(overallCounter,16) == 13
                        ringDist{i,j} = [pawPointsData(k,7),pawPointsData(k,8)];
                      end


                     %Pinky
                     if mod(overallCounter,16) == 14
                        pinkyProx{i,j} = [pawPointsData(k,7),pawPointsData(k,8)];
                     end


                     if mod(overallCounter,16) == 15
                        pinkyMid{i,j} = [pawPointsData(k,7),pawPointsData(k,8)];
                     end


                      if mod(overallCounter,16) == 0
                        pinkyDist{i,j} = [pawPointsData(k,7),pawPointsData(k,8)];
                      end

                    
                    overallCounter = overallCounter + 1;
                end
            end
        end
    end
    
end

%% Plot ball stick models of the data
function plotBallStick
    for i= 1:5
        for j =1:3
        pawBackCenter_xy = cell2mat(pawBackCenter{1,1});
      
        indexProx_xy = cell2mat(indexProx{i,j});
        middleProx_xy = cell2mat(middleProx{i,j});
        ringProx_xy = cell2mat(ringProx{i,j});
        pinkyProx_xy = cell2mat(pinkyProx{i,j});
        
    
        indexMid_xy = cell2mat(indexMid{i,j});
        middleMid_xy = cell2mat(middleMid{i,j});
        ringMid_xy = cell2mat(ringMid{i,j});
        pinkyMid_xy = cell2mat(pinkyMid{i,j});
        
        indexDist_xy = cell2mat(indexDist{i,j});
        middleDist_xy = cell2mat(middleDist{i,j});
        ringDist_xy = cell2mat(ringDist{i,j});
        pinkyDist_xy = cell2mat(pinkyDist{i,j});

 
       
        
        figure(1)
        hold on
        scatter(pawBackCenter_xy(1),pawBackCenter_xy(2))
        
        
        scatter(indexProx_xy(1), indexProx_xy(2),'r')
        scatter(middleProx_xy(1), middleProx_xy(2),'r')
        scatter(ringProx_xy(1), ringProx_xy(2),'r')
        scatter(pinkyProx_xy(1), pinkyProx_xy(2),'r')
        
        line([pawBackCenter_xy(1),indexProx_xy(1)],[pawBackCenter_xy(2),indexProx_xy(2)],'color','r')
        line([pawBackCenter_xy(1),middleProx_xy(1)],[pawBackCenter_xy(2),middleProx_xy(2)],'color','r')
        line([pawBackCenter_xy(1),ringProx_xy(1)],[pawBackCenter_xy(2),ringProx_xy(2)],'color','r')
        line([pawBackCenter_xy(1),pinkyProx_xy(1)],[pawBackCenter_xy(2),pinkyProx_xy(2)],'color','r')
        
        scatter(indexMid_xy(1), indexMid_xy(2),'b')
        scatter(middleMid_xy(1), middleMid_xy(2),'b')
        scatter(ringMid_xy(1), ringMid_xy(2),'b')
        scatter(pinkyMid_xy(1), pinkyMid_xy(2),'b')
        
        
        line([indexMid_xy(1),indexProx_xy(1)],[indexMid_xy(2),indexProx_xy(2)],'color','b')
        line([middleMid_xy(1),middleProx_xy(1)],[middleMid_xy(2),middleProx_xy(2)],'color','b')
        line([ringMid_xy(1),ringProx_xy(1)],[ringMid_xy(2),ringProx_xy(2)],'color','b')
        line([pinkyMid_xy(1),pinkyProx_xy(1)],[pinkyMid_xy(2),pinkyProx_xy(2)],'color','b')
        
        scatter(indexDist_xy(1), indexDist_xy(2),'g')
        scatter(middleDist_xy(1), middleDist_xy(2),'g')
        scatter(ringDist_xy(1), ringDist_xy(2),'g')
        scatter(pinkyDist_xy(1), pinkyDist_xy(2),'g')
        
        line([indexMid_xy(1),indexDist_xy(1)],[indexMid_xy(2),indexDist_xy(2)],'color','g')
        line([middleMid_xy(1),middleDist_xy(1)],[middleMid_xy(2),middleDist_xy(2)],'color','g')
        line([ringMid_xy(1),ringDist_xy(1)],[ringMid_xy(2),ringDist_xy(2)],'color','g')
        line([pinkyMid_xy(1),pinkyDist_xy(1)],[pinkyMid_xy(2),pinkyDist_xy(2)],'color','g')


        
        end
    end
end


%% Normalize Data to fixed point
function   [indexDistLeft, indexDistCenter, indexDistRight,middleDistLeft, middleDistCenter, middleDistRight,ringDistLeft, ringDistCenter, ringDistRight, pinkyDistLeft, pinkyDistCenter, pinkyDistRight] = normalizeData(pelletCenter, pawBackCenter, thumbProx, thumbDist, indexProx, indexMid, indexDist, middleProx, middleMid, middleDist, ringProx, ringMid, ringDist, pinkyProx, pinkyMid, pinkyDist)
     for i= 1:5
            for j =1:3
            pawBackCenter_xy{i,j} = cell2mat(pawBackCenter{i,j});

            indexProx_xy{i,j} = cell2mat(indexProx{i,j});
            middleProx_xy{i,j} = cell2mat(middleProx{i,j});
            ringProx_xy{i,j} = cell2mat(ringProx{i,j});
            pinkyProx_xy{i,j} = cell2mat(pinkyProx{i,j});


            indexMid_xy{i,j} = cell2mat(indexMid{i,j});
            middleMid_xy{i,j} = cell2mat(middleMid{i,j});
            ringMid_xy{i,j} = cell2mat(ringMid{i,j});
            pinkyMid_xy{i,j} = cell2mat(pinkyMid{i,j});

            indexDist_xy{i,j} = cell2mat(indexDist{i,j});
            middleDist_xy{i,j} = cell2mat(middleDist{i,j});
            ringDist_xy{i,j} = cell2mat(ringDist{i,j});
            pinkyDist_xy{i,j} = cell2mat(pinkyDist{i,j});

        end
     end
             temp = cell2mat(ringDist_xy);
             ringDistLeft(:,1)  = temp(:,1);
             ringDistLeft(:,2) = temp(:,2);
             ringDistCenter(:,1) = temp(:,3);
             ringDistCenter(:,2) = temp(:,4);
             ringDistRight(:,1) = temp(:,5);
             ringDistRight(:,2) = temp(:,6);

             temp = cell2mat(middleDist_xy);
             middleDistLeft(:,1)  = temp(:,1);
             middleDistLeft(:,2) = temp(:,2);
             middleDistCenter(:,1) = temp(:,3);
             middleDistCenter(:,2) = temp(:,4);
             middleDistRight(:,1) = temp(:,5);
             middleDistRight(:,2) = temp(:,6);



             temp = cell2mat(indexDist_xy);
             indexDistLeft(:,1)  = temp(:,1);
             indexDistLeft(:,2) = temp(:,2);
             indexDistCenter(:,1) = temp(:,3);
             indexDistCenter(:,2) = temp(:,4);
             indexDistRight(:,1) = temp(:,5);
             indexDistRight(:,2) = temp(:,6);



             temp = cell2mat(pinkyDist_xy);
             pinkyDistLeft(:,1)  = temp(:,1);
             pinkyDistLeft(:,2) = temp(:,2);
             pinkyDistCenter(:,1) = temp(:,3);
             pinkyDistCenter(:,2) = temp(:,4);
             pinkyDistRight(:,1) = temp(:,5);
             pinkyDistRight(:,2) = temp(:,6);
 
end
 
%% This Function is for measuring the spread between the distal knucles of the index finger and pink
function [pawSpreadDistPILeft,pawSpreadDistPICenter,pawSpreadDistPIRight] = calc2DistancePawSpread(pinkyDistLeft, indexDistLeft, pinkyDistCenter, indexDistCenter, pinkyDistRight, indexDistRight)

     pawSpreadDistPILeft = [];
     pawSpreadDistPICenter = [];
     pawSpreadDistPIRight = [];
  
    for i =1:5
        pawSpreadDistPILeft(i) = sqrt((pinkyDistLeft(i,1)-indexDistLeft(i,1))^2+(pinkyDistLeft(i,2)-indexDistLeft(i,2))^2);
        pawSpreadDistPICenter(i) = sqrt((pinkyDistCenter(i,1)-indexDistCenter(i,1))^2+(pinkyDistCenter(i,2)-indexDistCenter(i,2))^2);        pawSpreadDistPIRight(i) = sqrt((pinkyDistRight(i,1)-indexDistRight(i,1))^2+(pinkyDistRight(i,2)-indexDistRight(i,2))^2);
    end

end

function plotPawangle(indexDistCenter,middleDistCenter,ringDistCenter,pinkyDistCenter)
    
    


    
    for i=1:5
        figure(i) 
        hold on
        scatter(indexDistCenter(i,1), indexDistCenter(i,2),'r')
        scatter(middleDistCenter(i,1), middleDistCenter(i,2),'b')
        scatter(ringDistCenter(i,1),ringDistCenter(i,2),'g')
        scatter(pinkyDistCenter(i,1),pinkyDistCenter(i,1),'m')
    end

end

function calc3DistancePawSpread
    

end

function plot2DisancePawSpread (pawSpreadDistPILeft,pawSpreadDistPICenter,pawSpreadDistPIRight)
    for i =1:5
        hold on
        scatter(i,pawSpreadDistPICenter(i),'b')
    end
        
end

function plot3DistancePawSpread (pa

