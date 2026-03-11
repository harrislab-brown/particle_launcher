%% ============================================================
% HIGH-SPEED SPHERE TRACKING WITH SUBPIXEL CIRCLE FITTING
% MATLAB R2025a
% ============================================================

clear; clc; close all;

%% ---------------- USER INPUT ----------------
videoFile = 'vid_2001-12-16_18-55-57.mp4';
fps = 6200;
tubeDiameter_real = 0.002;  % meters (didnt measure actual tube yet)
startFrame = 1;

%% ---------------- LOAD VIDEO ----------------
vid = VideoReader(videoFile);
nFrames = floor(vid.Duration * fps);
fprintf('Frames: %d\n', nFrames);

vid.CurrentTime = 0;
frame1 = readFrame(vid);
gray1 = rgb2gray(frame1);

%% ---------------- CALIBRATION ----------------
figure; imshow(frame1); 
figure; imshow(frame1);
title('Draw polygon around tube to EXCLUDE it, double-click to finish');
tubeMask = roipoly;
title('Click tube center, then tube edge');
[xc, yc] = ginput(2);
tubeCenter = [xc(1), yc(1)];
tubeEdge   = [xc(2), yc(2)];

tubeDiameter_pixels = 2*norm(tubeEdge - tubeCenter);
pixel_to_meter = tubeDiameter_real / tubeDiameter_pixels;

fprintf('Scale = %.3e m/pixel\n', pixel_to_meter);

%% ---------------- TUBE AXIS DETECTION ----------------
edges = edge(gray1,'Canny');
[H,T,R] = hough(edges);
P = houghpeaks(H,5);
lines = houghlines(edges,T,R,P,'FillGap',200,'MinLength',100);

% choose longest line
maxLen = 0;
for k=1:length(lines)
    len = norm(lines(k).point1 - lines(k).point2);
    if len > maxLen
        bestLine = lines(k);
        maxLen = len;
    end
end
p1 = bestLine.point1; 
p2 = bestLine.point2;
tubeAxis = (p2 - p1)/norm(p2 - p1);

%% ---------------- STORAGE ----------------
centers = nan(nFrames,2);
radii   = nan(nFrames,1);
distFromTube = nan(nFrames,1);
deviation = nan(nFrames,1);

%% ---------------- KALMAN FILTER ----------------
kalman = configureKalmanFilter('ConstantVelocity', ...
                               [tubeCenter(1) tubeCenter(2)], ... % initial position
                               [1 1], ...  % initial position error
                               [1 1], ...  % motion noise
                               1);         % measurement noise
%% ---------------- PROCESS FRAMES ----------------
vid.CurrentTime = 0;
for i = 1:nFrames
    if ~hasFrame(vid), break; end
    frame = readFrame(vid);
    gray = rgb2gray(frame);
    gray(tubeMask) = 255;  % force tube to white background

    % Dark sphere segmentation
    bw = imbinarize(gray,'adaptive','ForegroundPolarity','dark');
    bw = bwareafilt(bw,1);        % keep largest blob
    bw = imfill(bw,'holes');
    bw = imerode(bw, strel('disk',2));

    % Edge extraction
    e = edge(bw,'Canny');
    [y,x] = find(e);

    if numel(x) > 30
        % Subpixel circle fit
        [cx,cy,R] = circleFitLSQ(x,y);
        c = correct(kalman,[cx cy]);
        centers(i,:) = c;
        radii(i) = R;

        % Geometry
        rvec = c - tubeCenter;
        s = dot(rvec, tubeAxis);
        proj = s*tubeAxis;
        perp = rvec - proj;

        distFromTube(i) = s * pixel_to_meter;
        deviation(i)   = norm(perp) * pixel_to_meter;
    else
        predict(kalman);
    end
end

%% ---------------- SMOOTH ----------------
distFromTube = fillmissing(distFromTube,'linear');
distFromTube = smoothdata(distFromTube,'sgolay',31);
deviation    = smoothdata(deviation,'sgolay',31);

%% ---------------- VELOCITY ----------------
dt = 1/fps;
velocity = gradient(distFromTube, dt);

%% ---------------- UNCERTAINTY ----------------
pixelNoise = 0.1; % subpixel fit
sigma_x = pixelNoise * pixel_to_meter;
sigma_v = sigma_x / dt;

%% ---------------- EXPORT ----------------
writematrix([distFromTube velocity deviation],'sphere_results.csv');

%% ---------------- PLOTS ----------------
valid = ~isnan(distFromTube);

figure;
subplot(2,1,1)
plot(distFromTube(valid), velocity(valid),'LineWidth',2)
xlabel('Distance from tube exit (m)')
ylabel('Velocity (m/s)')
grid on

subplot(2,1,2)
plot(distFromTube(valid), deviation(valid),'LineWidth',2)
xlabel('Distance from tube exit (m)')
ylabel('Deviation (m)')
grid on

sgtitle('Sphere Ballistics Data');

%% ---------------- VIDEO OVERLAY ----------------
vid.CurrentTime = 0;
figure;
for i = 1:nFrames
    if ~hasFrame(vid), break; end
    frame = readFrame(vid);
    imshow(frame); hold on;

    % centerline
    t = linspace(-3000,3000,2);
    pts = tubeCenter + t'*tubeAxis;
    plot(pts(:,1), pts(:,2),'r','LineWidth',2);

    % sphere
    if ~isnan(centers(i,1))
        viscircles(centers(i,:), radii(i),'Color','g');
    end
    title(sprintf('Frame %d',i));
    hold off;
    drawnow;
end

fprintf('Position uncertainty: %.2e m\n', sigma_x);
fprintf('Velocity uncertainty: %.2f m/s\n', sigma_v);

%% ============================================================
% SUBPIXEL CIRCLE FIT FUNCTION
% ============================================================
function [xc,yc,R] = circleFitLSQ(x,y)
    % Algebraic least squares circle fit
    x = x(:); y = y(:);
    A = [2*x 2*y ones(size(x))];
    b = x.^2 + y.^2;
    c = A\b;
    xc = c(1);
    yc = c(2);
    R = sqrt(c(3) + xc^2 + yc^2);
end