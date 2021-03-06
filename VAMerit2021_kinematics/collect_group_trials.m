function group_kinematics = collect_group_trials(sessionDirectories, current_sessions, ratSummary, current_session_idxs, ratRootFolder)

current_dates = current_sessions.date;

num_sessions = size(current_sessions,1);

group_kinematics.segmented_pd_trajectories = zeros(100,3,1);
group_kinematics.segmented_dig_trajectories = zeros(100,3,4,1);
group_kinematics.max_pd_v = [];

group_kinematics.pdEndPts = zeros(1,3);
group_kinematics.dig_endPoints = zeros(1,4,3);

group_kinematics.end_aperture = [];
group_kinematics.end_orientation = [];

group_kinematics.aperture_traj = zeros(1, 401);
group_kinematics.orientation_traj = zeros(1, 401);

group_kinematics.dig_covar = zeros(3,3,4);
group_kinematics.dig_gen_var = zeros(1,4);

group_kinematics.pd_covar = [];
group_kinematics.pd_gen_var = [];

group_kinematics.grasp_duration = [];
group_kinematics.reach_duration = [];

group_kinematics.grasp_end_orientation = [];
group_kinematics.grasp_end_aperture = [];

group_kinematics.post_reach_aperture = zeros(1,50);
group_kinematics.post_reach_orientation = zeros(1,50);

total_trials = 0;
num_valid_sessions = 0;
for i_session = 1 : num_sessions
    
    date_string = datestr(current_dates(i_session), 'yyyymmdd');
    session_folder_idx = contains(sessionDirectories, date_string);
    session_folder = fullfile(ratRootFolder, sessionDirectories{session_folder_idx});
    
    cd(session_folder)
    processed_reaches_file = dir('*_processed_reaches.mat');

    load(processed_reaches_file.name);
    
    num_trials = length(reachData);
    for i_trial = 1 : num_trials
        current_reach = reachData(i_trial);
        
        if isempty(current_reach.segmented_pd_trajectory)
            continue
        end
        total_trials = total_trials + 1;

        group_kinematics.segmented_pd_trajectories(:,:,total_trials) = current_reach.segmented_pd_trajectory;
        group_kinematics.segmented_dig_trajectories(:,:,:,total_trials) = current_reach.segmented_dig_trajectory;
        group_kinematics.max_pd_v(total_trials) = current_reach.max_pd_v(1);
        
        group_kinematics.pdEndPts(total_trials, :) = current_reach.pdEndPoints(1,:);
        group_kinematics.dig_endPoints(total_trials,:,:) = squeeze(current_reach.dig_endPoints(1,:,:));
        
        group_kinematics.grasp_duration(total_trials) = current_reach.graspEnds(1) - current_reach.graspStarts(1);
        group_kinematics.reach_duration(total_trials) = current_reach.reachEnds(1) - current_reach.slotBreachFrame(1);
        
        if ~isempty(current_reach.grasp_orientation)
            if ~isempty(current_reach.grasp_orientation{1})
                group_kinematics.grasp_end_orientation(total_trials) = current_reach.grasp_orientation{1}(end);
            end
        end
        if ~isempty(current_reach.grasp_aperture)
            if ~isempty(current_reach.grasp_aperture{1})
                group_kinematics.grasp_end_aperture(total_trials) = current_reach.grasp_aperture{1}(end);
            end
        end
        
        if ~isempty(current_reach.aperture)
            if ~isempty(current_reach.aperture{1})
                group_kinematics.end_aperture(total_trials) = current_reach.aperture{1}(end);
            end
        end
        if ~isempty(current_reach.orientation)
            if ~isempty(current_reach.orientation{1})
                group_kinematics.end_orientation(total_trials) = current_reach.orientation{1}(end);
            end
        end
        
        group_kinematics.post_reach_aperture(total_trials, :) = current_reach.post_reach_aperture(1,:);
        group_kinematics.post_reach_orientation(total_trials, :) = current_reach.post_reach_orientation(1,:);

    end

    % calculate aperture and orientation trajectories
    if ~isempty(ratSummary.interp_aperture_traj{current_session_idxs(i_session)})
        num_valid_sessions = num_valid_sessions + 1;
    end
    
    if num_valid_sessions == 1
        group_kinematics.aperture_traj = ratSummary.interp_aperture_traj{current_session_idxs(i_session)};
        group_kinematics.orientation_traj = ratSummary.interp_orientation_traj{current_session_idxs(i_session)};
    else
        trials_to_add = size(ratSummary.interp_aperture_traj{current_session_idxs(i_session)},1);
        group_kinematics.aperture_traj(end+1:end+trials_to_add,:) = ratSummary.interp_aperture_traj{current_session_idxs(i_session)};
        group_kinematics.orientation_traj(end+1:end+trials_to_add,:) = ratSummary.interp_orientation_traj{current_session_idxs(i_session)};
    end
    
    % covariance matrix of pd and digit endpoints
    group_kinematics.pd_covar = cov(group_kinematics.pdEndPts);
    group_kinematics.pd_gen_var = det(group_kinematics.pd_covar);
    

    for i_digit = 1 : 4
        group_kinematics.dig_covar(:,:,i_digit) = cov(squeeze(group_kinematics.dig_endPoints(:,i_digit,:)),'omitrows');
        group_kinematics.dig_gen_var(i_digit) = det(squeeze(group_kinematics.dig_covar(:,:,i_digit)));
    end
    

    
end