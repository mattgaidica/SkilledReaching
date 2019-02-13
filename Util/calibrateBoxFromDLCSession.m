function [boxCal_fromSession,mp_direct,mp_mirror] = calibrateBoxFromDLCSession(fullSessionDir,cameraParams,boxCal,pawPref,ROIs,varargin)

min_valid_p_for_calibration = 1;

if isfield(boxCal,'boxCal_fromSession')
    boxCal = rmfield(boxCal,'boxCal_fromSession');
end
boxCal_fromSession = boxCal;

[~,sessionName,~] = fileparts(fullSessionDir);

% for R0189, 10171002, a reflection in the mirror view is often mistaken
% for the pellet. So don't use the pellet for calibration in that session.
if strcmpi(sessionName,'r0189_20171002a')
    skipPelletForCalibration = true;
else
    skipPelletForCalibration = false;
end

% temp = fieldnames(boxCal);
% for iField = 1 : length(temp)
%     if strcmpi(temp{iField},'boxcal_fromsession')
%         continue
%     else
%         boxCal_fromSession.(temp{iField}) = boxCal.(temp{iField});
%     end
% end

% parameters for find_invalid_DLC_points
maxDistPerFrame = 30;
min_valid_p = 0.85;
min_certain_p = 0.97;
maxDistFromNeighbor_invalid = 70;

imSize = [1024,2040];

for iarg = 1 : 2 : nargin - 5
    switch lower(varargin{iarg})
        case 'min_valid_p_for_calibration'
            min_valid_p_for_calibration = varargin{iarg + 1};
        case 'maxdistperframe'
            maxDistPerFrame = varargin{iarg + 1};
        case 'min_valid_p'
            min_valid_p = varargin{iarg + 1};   % p values below this are considered to indicate poorly determined points (and exclude from subsequent analysis)
        case 'min_certain_p'
            min_certain_p = varargin{iarg + 1};   % p values above this are considered to be well-determined points (and include in subsequent analysis)
        case 'maxneighbordist'
            maxNeighborDist = varargin{iarg + 1};
        case 'imsize'
            imSize = varargin{iarg + 1};
    end
end

switch pawPref
    case 'right'
        cam_matrix_idx = 2;
    case 'left'
        cam_matrix_idx = 3;
end
K = cameraParams.IntrinsicMatrix;

[directViewDir,mirrorViewDir,direct_csvList,mirror_csvList] = getDLC_csvList(fullSessionDir);
[~,curSession,~] = fileparts(fullSessionDir);

boxCal_fromSession.sessionName = curSession;

ratID = curSession(1:5);
ratIDnum = str2double(ratID(2:end));

C = textscan(curSession,[ratID '_%8c']);
sessionDate = C{1};

numMarkedVids = length(direct_csvList);
% ratID, date, etc. for each individual video
directVidTime = cell(1, numMarkedVids);
directVidNum = zeros(numMarkedVids,1);

% find all the direct view videos that are available
cd(directViewDir);
uniqueDateList = {};
for ii = 1 : numMarkedVids   

    [directVid_ratID(ii),directVidDate{ii},directVidTime{ii},directVidNum(ii)] = ...
        extractDLC_CSV_identifiers(direct_csvList(ii).name);

    if isempty(uniqueDateList)
        uniqueDateList{1} = directVidDate{ii};
    elseif ~any(strcmp(uniqueDateList,directVidDate{ii}))
        uniqueDateList{end+1} = directVidDate{ii};
    end
end
       
cd(mirrorViewDir)
mp_direct = zeros(0,2);
mp_mirror = zeros(0,2);
for i_mirrorcsv = 1 : length(mirror_csvList)
    
    [mirror_ratID,mirror_vidDate,mirror_vidTime,mirror_vidNum] = extractDLC_CSV_identifiers(mirror_csvList(i_mirrorcsv).name);

    foundMatch = false;
    for i_directcsv = 1 : numMarkedVids
        if mirror_ratID == ratIDnum && ...      % match ratID
           strcmp(mirror_vidDate, sessionDate) && ...  % match date
           strcmp(mirror_vidTime, directVidTime{i_directcsv}) && ...  % match time
           mirror_vidNum == directVidNum(i_directcsv)                % match vid number
            foundMatch = true;
            break;
        end
    end
    if ~foundMatch
        continue;
    end

    cd(mirrorViewDir)
    [mirror_bp,mirror_pts,mirror_p] = read_DLC_csv(mirror_csvList(i_mirrorcsv).name);
    cd(directViewDir)
    [direct_bp,direct_pts,direct_p] = read_DLC_csv(direct_csvList(i_directcsv).name);
            
    % match body parts between direct and mirror views
    mirror_bpMatch_idx = [];
    direct_bpMatch_idx = [];
    num_direct_bp = length(direct_bp);
    numValid_bp = 0;
    bodyparts = {};
    for i_bp = 1 : num_direct_bp

%         if ~any(strcmpi(mirror_bp, direct_bp{i_bp}))
%             % accept 'leftpaw' and 'leftpawdorsum' or 'righpaw' and
%             % 'rightpawdorsum' as the same thing
%             continue;
%         end
%         numValid_bp = numValid_bp + 1;
%         try
%         mirror_bpMatch_idx(numValid_bp) = find(strcmpi(mirror_bp, direct_bp{i_bp}));
%         catch
%             keyboard
%         end
        % hard coding for now that bodypart labels are in the same order in
        % the direct and mirror views, should fix this later to make the
        % algorithm more robust to human error
        
        numValid_bp = numValid_bp + 1;
        
        mirror_bpMatch_idx(numValid_bp) = i_bp;
        direct_bpMatch_idx(numValid_bp) = i_bp;
        bodyparts{numValid_bp} = direct_bp{i_bp};
    end

    [invalid_mirror, ~] = find_invalid_DLC_points(mirror_pts, mirror_p,mirror_bp,pawPref,...
        'maxdistperframe',maxDistPerFrame,'min_valid_p',min_valid_p,'min_certain_p',min_certain_p,'maxneighbordist',maxDistFromNeighbor_invalid);
    [invalid_direct, ~] = find_invalid_DLC_points(direct_pts, direct_p,direct_bp,pawPref,...
        'maxdistperframe',maxDistPerFrame,'min_valid_p',min_valid_p,'min_certain_p',min_certain_p,'maxneighbordist',maxDistFromNeighbor_invalid);
            
    direct_pts_ud = reconstructUndistortedPoints(direct_pts,ROIs(1,:),cameraParams,~invalid_direct);
    mirror_pts_ud = reconstructUndistortedPoints(mirror_pts,ROIs(2,:),cameraParams,~invalid_mirror);
    
    valid_direct = (direct_p >= min_valid_p_for_calibration) & ~isnan(direct_pts_ud(:,:,1)) & ~invalid_direct;
    valid_mirror = (mirror_p >= min_valid_p_for_calibration) & ~isnan(mirror_pts_ud(:,:,1)) & ~invalid_mirror;

    validPoints = (valid_direct & valid_mirror);

    for i_bp = 1 : num_direct_bp
        
        if strcmpi(direct_bp{i_bp},'pellet') && skipPelletForCalibration
            % for R0189, 10171002, a reflection in the mirror view is often mistaken
            % for the pellet. So don't use the pellet for calibration in that session.
            continue
        end
        if ~any(validPoints(i_bp,:));continue;end
        
        new_direct = squeeze(direct_pts_ud(i_bp,validPoints(i_bp,:),:));
        new_mirror = squeeze(mirror_pts_ud(mirror_bpMatch_idx(i_bp),validPoints(mirror_bpMatch_idx(i_bp),:),:));
        
        if iscolumn(new_direct);new_direct = new_direct';end
        if iscolumn(new_mirror);new_mirror = new_mirror';end
        
        mp_direct = [mp_direct;new_direct];
        mp_mirror = [mp_mirror;new_mirror];
        
    end
    
end

[F,~] = refineFundMatrixMirror(mp_direct,mp_mirror,imSize);
% F = fundMatrix_mirror(mp_direct, mp_mirror);

E = K * F * K';
[rot,t] = EssentialMatrixToCameraMatrix(E);
[cRot,cT,~] = SelectCorrectEssentialCameraMatrix_mirror(...
    rot,t,mp_mirror',mp_direct',K');
Ptemp = [cRot,cT];
Pn = Ptemp';

boxCal_fromSession.F(:,:,cam_matrix_idx) = F;
boxCal_fromSession.E(:,:,cam_matrix_idx) = E;
boxCal_fromSession.Pn(:,:,cam_matrix_idx) = Pn;

end
        
        
    
    