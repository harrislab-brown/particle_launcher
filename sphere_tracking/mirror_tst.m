videoPath = '/Users/danielnorth/Library/CloudStorage/OneDrive-BrownUniversity/Desktop/26Dan''s Stuff/THESIS/Launcher V5.5 Test Videos 3-23-26/';
fileName = 'lol.mov';
fps = 6448.2848;                       % frames per second
tubeDiameter_real = 0.0021;         % meters 
sphereRadius_real = 0.0015 / 2; % sphere radius in m
deviationThreshold = 0.0005; % acceptable "spray" in meters - given by Chase to be .5 mm of spray @ distance of deviation_threshold_distance (related to target droplet size)
deviationThresholdDistance = 0.005;
darkObjectThreshold = 75; % for sphere detection (adjust as necessary)
%for output avg. velocity calculation 
d_min = 0; % m
d_max = 0.002; % m


[avgv_0, deviation] = sphere_tracking_mirror(videoPath, fileName, fps, tubeDiameter_real, sphereRadius_real, deviationThreshold, deviationThresholdDistance, darkObjectThreshold, d_min, d_max);