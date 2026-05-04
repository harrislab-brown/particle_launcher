% m_sphere = 0.0241e-3; %sphere mass in kg
% m_plunger = 2.5246e-3; %plunger+plunger tip mass
% m_spring = 0.6725e-3; %spring mass
% F_nc = 1.48; %aggregate net constant non-conservative force (match to fit data)
% d0 = 13.3e-3; %plunger travel distance in m (measured from CAD)

%now we just want to plot the averages for velocity and deviation as a function of compression, showing the error bars for standard deviation:
% Plot average velocities with error bars

figure;
sgtitle(plotTitle, 'Interpreter', 'latex');
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
% F_nc = 1.2;
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
        v_f(i) = sqrt((k/m)*(x_m(i)^2) + 2*g*d0 - (F_nc*d0)/m);
    else
        v_f(i) = sqrt((k/m)*((x_m(i)^2)-((x_m(i)-d0))^2) + 2*g*d0 - (F_nc*d0)/m);
    end
end

%plot(x, v_f);
%legend("Experimental Data", "Theoretical Model",'Interpreter', 'latex', 'Location', 'southeast');

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

