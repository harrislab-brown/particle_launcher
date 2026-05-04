%% Sphere Tracking from High-Speed Video - mutliple trial script


close all;

%% --USER INPUTS-- %%

%make sure that the folder this path leads to contains all the videos you
%want to analyze AND the notebook CSV (notebook csv not required to be in
%there but makes it easier)
videoPath = '/Users/danielnorth/Library/CloudStorage/OneDrive-BrownUniversity/Desktop/26Dan''s Stuff/THESIS/L V6 1.5mm particle 158nm spring 4-12-26/';
fps = 6447.744;                       % frames per second

tubeDiameter_real = 0.0021;         % meters (USER INPUT)
sphereRadius_real = 0.0015 / 2; % sphere radius in m
m_sphere = 0.0241e-3; %sphere mass in kg
m_plunger = 2.5246e-3; %plunger+plunger tip mass
m_spring = 0.6725e-3; %spring mass
F_nc = 1.2; %aggregate net constant non-conservative force (match to fit data)
d0 = 13.3e-3; %plunger travel distance in m (measured from CAD)

deviationThreshold = 0.0005; % acceptable "spray" in meters - given by Chase to be .5 mm of spray @ distance of deviation_threshold_distance (related to target droplet size)
deviationThresholdDistance = 0.005;
darkObjectThreshold = 100; % for sphere detection (adjust as necessary)
%for output avg. velocity calculation: 
d_min = 0; % m
d_max = 0.002; % m
springConstant = 158; %in N/m
recalibrateTrials = [1 50]; %if something shifted in the experiment and you need to recalibrate before a certain trial or trials, specify the trial number here. If not applicable, set this = []. The number 1 (for the first trial) needs to be in this array, or there will be an error.
startTrial = 1; %if error occurs and need to pick up in the middle, comment out everything before the for loop and change this variable to the trial you want to restart at (make sure you don't clear the workspace)
plotTitle = 'Particle Launcher V6 | Spring $k = 158 N/m$ | 1.5 mm Steel Spheres | Launch Angle: $0^\circ$ (Down) | 04-12-2026'; %launch angle: 0 is down, 90 is right, 180 is up, 270 is left (counterclockwise)


%%--prompt user to select notebook .csv file--%
[file, path] = uigetfile('*.csv', 'Select Notebook CSV', videoPath);
notebook = readtable(fullfile(path, file), 'NumHeaderLines', 1);

%%--get some parameters about the dataset--%
trials = notebook{:,1}.'; %just a list from 1 to n where n is total # of trials
compressions = unique(notebook{:,3}.'); %a list of all the different spring compressions trialed
compressions_all = notebook{:,3}.'; % non-unique list
subtrialsPerCompression = (size(trials, 2)) / (size(compressions, 2)); %number of trials performed for each compression (must be the same for all compressions)
% velocities = nan(size(trials),1)
% deviations = nan(,1)

%initialize some parameters used in the for loop:
subtrial = 1; 
compressionIndex = 1;

%these will store the velocities and deviations for one compression within
%the for loop
compressionVels = nan(1, subtrialsPerCompression);
compressionDevs = nan(1, subtrialsPerCompression);

%these will store the average velocities/deviations, along with standard
%deviations, for the whole dataset
avgVels = nan(size(compressions, 2),1);
avgDevs = nan(size(compressions, 2),1);
stdVels = nan(size(compressions, 2),1);
stdDevs = nan(size(compressions, 2),1);

% this will store the deviations from each trial, along with corresponding
% compressions, for the scatter plot
deviationVecs = nan(size(trials,2),2);

%--run the mirrored tracking function once on the first video to establish
%tube size, tube axis, and exclusion rectangles:
% firstFile = string(notebook{1, 4});
% [avgv_0, deviation, deviationVec_1, calibrations] = sphere_tracking_mirror(videoPath, firstFile, fps, tubeDiameter_real, sphereRadius_real, deviationThreshold, deviationThresholdDistance, darkObjectThreshold, d_min, d_max, []);

%--loop thru all the trials and run the sphere tracking on each video (and its mirror counterpart)--%%

for trial = trials(startTrial:end)
    fprintf('Trial %i\n', trial);
    vid = string(notebook{trial, 4});
    fileName = vid; % Construct the filename for the current trial
    if ismember(trial, recalibrateTrials) %if we need to recalibrate...
        [avgv_0, deviation, deviationVec, calibrations] = sphere_tracking_mirror(videoPath, fileName, fps, tubeDiameter_real, sphereRadius_real, deviationThreshold, deviationThresholdDistance, darkObjectThreshold, d_min, d_max, []);
    else
        [avgv_0, deviation, deviationVec, calibrations_o] = sphere_tracking_mirror(videoPath, fileName, fps, tubeDiameter_real, sphereRadius_real, deviationThreshold, deviationThresholdDistance, darkObjectThreshold, d_min, d_max, calibrations);
    end
    deviationVecs(trial,:) = deviationVec;
    if subtrial < subtrialsPerCompression %so long as we are within a set of trials for the same compression
        compressionVels(subtrial) = avgv_0;
        compressionDevs(subtrial) = deviation;
        subtrial = subtrial + 1;
    else %once we hit the end of the trials for the compression, we want to average/std. dev all the results and reset for the next compression
        compressionVels(subtrial) = avgv_0;
        compressionDevs(subtrial) = deviation;
        avgVels(compressionIndex) = mean(compressionVels);
        avgDevs(compressionIndex) = mean(compressionDevs);
        stdVels(compressionIndex) = std(compressionVels);
        stdDevs(compressionIndex) = std(compressionDevs);
        compressionIndex = compressionIndex + 1;
        subtrial = 1;
    end
end

%now we just want to plot the averages for velocity and deviation as a function of compression, showing the error bars for standard deviation:

figure;
sgtitle(plotTitle, 'Interpreter', 'latex');

% Plot average velocities with error bars
subplot(3,1,1);
errorbar(compressions, avgVels, stdVels, 'o-');
xlabel('$x$ (mm)', 'Interpreter', 'latex');
ylabel('$v_{avg}$ (m/s)', 'Interpreter', 'latex');
title(sprintf('Average Particle Velocity (%.2f–%.2f mm) vs. Launcher Spring Compression', 1000*d_min, 1000*d_max));
set(gca, 'FontName', 'Times');
grid on;
hold on;

%now the theoretical velocity line:
m = m_plunger + m_sphere + (m_spring/3);
g = 9.81;
k = springConstant;

x = linspace(compressions(1),compressions(end),20); %in mm
x_m = x ./ 1000; %convert to meters

%energies, delta (final - initial) energies
% dPEg = m*g*d0;
% dPEsp = 0.5.*k.*(((x_m-d0).^2)-(x_m.^2));
% KE_i = 0; %sphere starts at rest
% F_nc = 0.6579; %assume constant combined force for non-conservative forces (friction, air resistance)
% W_noncons = F_noncons * d0; %energy losses due to work done by non-cons forces
% 
% 
% 
% v_f = ((-dPEsp - dPEg - W_noncons) ./ (0.5*m)).^(1/2);
% v_f_data = avgVels.';
% %energy_loss = (v_f_data.^2) ./ (v_f.^2);
n = size(x);
v_f = zeros(n);
for i = [1:n(2)]
    if x_m(i) <= d0
        v_f(i) = sqrt((k/m)*(x_m(i)^2) - 2*g*d0 - (F_nc*d0)/m);
    else
        v_f(i) = sqrt((k/m)*((x_m(i)^2)-((x_m(i)-d0))^2) - 2*g*d0 - (F_nc*d0)/m);
    end
end

plot(x, v_f);
legend("Experimental Data", "Theoretical Model",'Interpreter', 'latex', 'Location', 'southeast');

% Plot average deviations with error bars
subplot(3,1,2);
errorbar(compressions, (avgDevs*1000), (stdDevs*1000), 'o-');
xlabel('$x$ (mm)', 'Interpreter', 'latex');
ylabel('Average Deviation (mm)', 'Interpreter', 'latex');
title(sprintf('Average Deviation at %.2f mm vs. Launcher Spring Compression', 1000*deviationThresholdDistance));
set(gca, 'FontName', 'Times');
grid on;

%Scatter plot
subplot(3,1,3);
scatter((deviationVecs(:,1).*1000), (deviationVecs(:,2).*1000));

centers = [0 0; 0 0];  % circle centers
radii   = [(deviationThreshold*1000) (tubeDiameter_real*1000)/2];
colors = {'red' 'blue'};
labels = {'Deviation Threshold', 'Launcher Barrel'};
viscircles([0 0], (deviationThreshold*1000)); %deviation limit
viscircles([0 0], (tubeDiameter_real*1000)/2, 'Color', 'b'); %represents barrel
offsets = [1 0.8]; % adjust as needed
for i = 1:size(centers,1)
    text(centers(i,1)+offsets(1), centers(i,2)+offsets(i), ...
        sprintf(labels{i}), ...
        'Color', colors{i}, 'FontSize',10, 'FontName', 'Times');
end

xlabel('$y$ (mm)', 'Interpreter', 'latex');
ylabel('$z$ (mm)', 'Interpreter', 'latex');
title(sprintf('Deviation Scatter Plot at %.2f mm', 1000*deviationThresholdDistance));
set(gca, 'FontName', 'Times');
xlim([-1.2 1.2]);
ylim([-1.2 1.2]);
axis equal;
grid on;

saveas(gcf, append(videoPath, 'plot.png'));
save(append(videoPath, 'postprocessed_data1.mat'));
