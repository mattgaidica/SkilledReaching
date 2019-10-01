function reachData = initializeReachDataStruct()

reachData.reachEnds = [];
reachData.graspEnds = [];
reachData.reachStarts = [];
reachData.graspStarts = [];
reachData.reach_to_grasp = [];
reachData.pdEndPoints = [];
reachData.slotBreachFrame = [];
reachData.firstDigitKinematicsFrame = [];
reachData.pd_trajectory = {};
reachData.pd_v = {};
reachData.dig2_trajectory = {};
reachData.dig2_v = {};
reachData.dig2_endPoints = [];
reachData.orientation = {};
reachData.aperture = {};
reachData.trialScores = [];