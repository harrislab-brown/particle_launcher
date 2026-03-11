%% Sphere Tracking from High-Speed Video - dual video (or 1 video with a 45 degree mirror)
%runs the sphere tracking function twice - once on the normal video, once
%on the mirrored video.
% ** the mirrored video must have the following naming convention: 'm_[name-of-normal-video].mp4'

function [avgv_0_o, deviation] = sphere_tracking_mirror(videoPath, fileName, fps, tubeDiameter_real, sphereRadius_real, deviationThreshold, deviationThresholdDistance, darkObjectThreshold, d_min, d_max)
[avgv_0, x, y, vx, vy] = sphere_tracking(videoPath, fileName, fps, tubeDiameter_real, sphereRadius_real, deviationThreshold, deviationThresholdDistance, darkObjectThreshold, d_min, d_max);
[avgv_0_m, x_m, z, vx_m, vz] = sphere_tracking(videoPath, append('m_', fileName), fps, tubeDiameter_real, sphereRadius_real, deviationThreshold, deviationThresholdDistance, darkObjectThreshold, d_min, d_max);
z = -z; %because mirror image

% Now we compute our own avgv0 based on our THREE components vx vy vz:
velocity = [vx, vy, vz];
speed = vecnorm(velocity, 2, 2);

%calculate avg velocity from d_min to some distance from tube d_max (this serves as the launcher output velocity for the video):
regionIdx = x >= d_min & x <= d_max & ~isnan(speed);
avgv_0_o = mean(speed(regionIdx), 'omitnan');

% And we also compute the magnitude of the total deviation at the deviation distance, factoring in
% both y and z components:

% Remove NaNs
validIdx = ~isnan(x) & ~isnan(y) & ~isnan(z);

% Interpolate y and z deviation at desired distance
y_d = interp1( ...
    x(validIdx), ...
    y(validIdx), ...
    deviationThresholdDistance, ...
    'linear');
z_d = interp1( ...
    x(validIdx), ...
    z(validIdx), ...
    deviationThresholdDistance, ...
    'linear');

%take magnitude of [y z] vector to get total 2D deviation:
deviation = vecnorm([y_d z_d]);

end