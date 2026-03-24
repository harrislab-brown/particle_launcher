%now we just want to plot the averages for velocity and deviation as a function of compression, showing the error bars for standard deviation:
% Plot average velocities with error bars

figure;
sgtitle('Particle Launcher V5.5 | Spring $k = 200 N/m$ | 03-23-2026', 'Interpreter', 'latex');
subplot(3,1,1);
errorbar(compressions, avgVels, stdVels, 'o-');
xlabel('$x$ (mm)', 'Interpreter', 'latex');
ylabel('$v_{avg}$ (m/s)', 'Interpreter', 'latex');
title(sprintf('Average Particle Velocity (%.2f–%.2f mm) vs. Launcher Spring Compression', 1000*d_min, 1000*d_max));
set(gca, 'FontName', 'Times');
grid on;

% Plot average deviations with error bars
subplot(3,1,2);
errorbar(compressions, (avgDevs*1000), (stdDevs*1000), 'o-');
xlabel('$x$ (mm)', 'Interpreter', 'latex');
ylabel('Average Deviation (mm)', 'Interpreter', 'latex');
title(sprintf('Average Deviation at %.2f mm vs. Launcher Spring Compression', 1000*deviationThresholdDistance));
set(gca, 'FontName', 'Times');
grid on;

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