function standardized_trajectory = standardizeSingleTrajectory(interp_trajectory,max_z,n)

% function to take a single reaching trajectory, beginning at some maximum
% z-value (to make sure artificial differences aren't introduced by
% different starting points), and divide the trajectory into n evenly
% spaced points

traj_to_segment = interp_trajectory(interp_trajectory(:,3) <= max_z,:);

standardized_trajectory = interparc(n,traj_to_segment(:,1),traj_to_segment(:,2),traj_to_segment(:,3),'pchip');

end