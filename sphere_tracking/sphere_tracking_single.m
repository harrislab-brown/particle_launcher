%% Sphere Tracking from High-Speed Video - single trial script


close all;
% videoPath = '/Users/danielnorth/Library/CloudStorage/OneDrive-BrownUniversity/Desktop/26Dan''s Stuff/THESIS/Launcher V5 proper tube length test videos/';
% fileName = 'vid_2001-12-16_18-55-57.mp4';
videoPath = '/Users/danielnorth/Library/CloudStorage/OneDrive-BrownUniversity/Desktop/26Dan''s Stuff/THESIS/';
fileName = 'lol.mov';
fps = 6447.744;                       % frames per second
tubeDiameter_real = 0.00148;         % meters (USER INPUT)
sphereRadius_real = 0.00099 / 2; % sphere radius in m
deviationThreshold = 0.0005; % acceptable "spray" in meters - given by Chase to be .5 mm of spray @ distance of deviation_threshold_distance (related to target droplet size)
deviationThresholdDistance = 0.005;
% startFrame = 6;                   % select the frame to start the video at (choose a frame where the sphere is fully visible)
% endFrame = 87;
darkObjectThreshold = 80; % for sphere detection (adjust as necessary)
%for output avg. velocity calculation 
d_min = 0; % m
d_max = 0.002; % m
%[avgv_0, x, y, vx, vy, calibration, frames] = sphere_tracking(videoPath, fileName, fps, tubeDiameter_real, sphereRadius_real, deviationThreshold, deviationThresholdDistance, darkObjectThreshold, d_min, d_max, [], []);
[avgv_0, deviation, deviationVec, calibrations] = sphere_tracking_mirror(videoPath, fileName, fps, tubeDiameter_real, sphereRadius_real, deviationThreshold, deviationThresholdDistance, darkObjectThreshold, d_min, d_max, [])
%waitfor(findall(0,'Type','figure'));
%sphere_tracking(videoPath, fileName, fps, tubeDiameter_real, sphereRadius_real, deviationThreshold, deviationThresholdDistance, startFrame, endFrame, darkObjectThreshold, d_min, d_max);
