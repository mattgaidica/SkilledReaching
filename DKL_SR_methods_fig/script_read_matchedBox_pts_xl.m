% script to read in matching box points from excel files

kinematics_rootDir = '/Users/dleventh/Box Sync/Leventhal Lab/Skilled Reaching Project/Matlab Kinematics/PlotGrossTrajectory';
xl_directory = '/Users/dleventh/Box Sync/Leventhal Lab/Skilled Reaching Project/SR_box_matched_points';

sr_ratInfo = get_sr_RatList();

cd(xl_directory);

for i_rat = 1 : length(sr_ratInfo)
    
    ratID = sr_ratInfo(i_rat).ID;
    
    xlName = [ratID '_matched_points.xlsx'];
    
    [status,sheets] = xlsfinfo(xlName);

    numSheets = length(sheets);
    
    for iSheet = 1 : numSheets
        
        temp = xlsread(xlName, sheets{iSheet});
        
    end
end