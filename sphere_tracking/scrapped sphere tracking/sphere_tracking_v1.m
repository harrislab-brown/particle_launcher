%% Sphere Tracking from High-Speed Video
% Author: ChatGPT & Daniel North

clear; clc; close all;

%% ---------------- USER INPUT ----------------
videoFile = 'vid_2001-12-16_18-55-57.mp4';   % video file name & path
fps = 6200;                       % frames per second
tubeDiameter_real = 0.002;         % meters (USER INPUT)
sphereRadius_real = 0.0015 / 2; % sphere radius in m
startFrame = 6;                   % select the frame to start the video at (choose a frame where the sphere is fully visible)
endFrame = 82;
darkObjectThreshold = 75; %for sphere detection (adjust as necessary)

%% ---------------- LOAD VIDEO ----------------
vid = VideoReader(videoFile);
nFrames = vid.NumFrames;
fprintf('Total frames: %d\n', nFrames);
fps_vidtime = vid.NumFrames / vid.Duration; %because the video plays in slo-mo (and not in real time), we need a way to calculate the time in the video playback that corresponds to any given frame

%% Read start frame for calibration
frame1 = read(vid, startFrame);

%% ---------------- CALIBRATION ----------------
%% User clicks tube center and tube edge
figure; imshow(frame1); title('Click one corner of tube at outlet, then the other corner');
[xc, yc] = ginput(2);
tubeEdgeUpper = [xc(1), yc(1)];
tubeEdgeLower   = [xc(2), yc(2)];
tubeCenter = (tubeEdgeLower(:) + tubeEdgeUpper(:)).'/2;

tubeDiameter_pixels = 1*norm(tubeEdgeUpper - tubeEdgeLower);
meter_per_pixel = tubeDiameter_real / tubeDiameter_pixels;
%also get sphere radius in pixels here:
sphereRadius = (sphereRadius_real) / meter_per_pixel; % convert sphere radius from mm to meters in pixel scale

fprintf('Pixel-to-meter scale: %.6e m/pixel\n', meter_per_pixel);

%% Define tube axis (centerline)
figure; imshow(frame1); title('Click two points defining tube axis direction (select two points on either edge of tube)');
[xline, yline] = ginput(2);
p1 = [xline(1), yline(1)];
p2 = [xline(2), yline(2)];
tubeAxis = p2 - p1;
tubeAxis = tubeAxis / norm(tubeAxis); % unit vector

%% Select exclusion region (to exclude tube from analysis)
figure; imshow(frame1); title('Draw a rectangle around the tube. The rectangle must not extend past the video frame.');
hRect = imrect;                % user draws rectangle
exclusionPos = round(hRect.getPosition()); % [x y width height]
close;

%% Reset video
vid.CurrentTime = startFrame / fps_vidtime;

%% ---------------- STORAGE ----------------
centers = nan(nFrames,2);
distFromTube = nan(nFrames,1);
deviation = nan(nFrames,1);
velocity = nan(nFrames,1);

%% ---------------- PROCESS FRAMES ----------------
frameIdx = 1;
while hasFrame(vid) && frameIdx+startFrame <= endFrame
    % --- INITIALIZE FRAME ---
    frame = readFrame(vid);
    gray = rgb2gray(frame);
    
    % --- CREATE MASK TO EXCLUDE TUBE ---
    mask = true(size(gray));  % initially include everything
    x1 = exclusionPos(1); y1 = exclusionPos(2);
    w = exclusionPos(3); h = exclusionPos(4);
    mask(y1:y1+h, x1:x1+w) = false; % set exclusion rectangle to false

    % --- THRESHOLD TO DETECT DARK OBJECTS ---
    bw = gray < darkObjectThreshold;          % adjust threshold if needed
    bw = bw & mask;                % apply exclusion mask

    % --- REMOVE SMALL NOISE ---
    bw = bwareaopen(bw, 50);
    
    % % Edge detection
    % edges = edge(gray,'Canny');
    % 
    % % Hough circle detection (sphere)
    % [centersDetected, radii] = imfindcircles(edges,[10 200],'Sensitivity',0.9);
    
    % --- FIND SPHERE CENTROID ---
    stats = regionprops(bw, 'Centroid', 'Area');
    [~, idx] = max([stats.Area]);   % assume largest dark object is the sphere
    c = stats(idx).Centroid; % c stores the x y position of the sphere

    %c = centersDetected(1,:);
    centers(frameIdx,:) = c;
    
    % Vector from tube origin to sphere
    r = c - tubeCenter;
    
    % Distance along tube axis
    %distFromTube(frameIdx) = dot(r, tubeAxis) * pixel_to_meter;
    distFromTube(frameIdx) = (c(1) - tubeCenter(1)) * meter_per_pixel;
    
    % Perpendicular deviation
    %proj = dot(r, tubeAxis)*tubeAxis;
    %perp = r - proj;
    %deviation(frameIdx) = norm(perp)*pixel_to_meter;
    deviation(frameIdx) = (c(2) - tubeCenter(2)) * meter_per_pixel;
    frameIdx = frameIdx + 1;
end

%% ---------------- VELOCITY ----------------
dt = 1/fps;
velocity = gradient(distFromTube, dt);

%% ---------------- PLOTS ----------------
valid = ~isnan(distFromTube);
frames = startFrame:nFrames;
realtime = frames./fps;

figure;
subplot(3,1,1)
plot(realtime(valid), velocity(valid),'LineWidth',2)
xlabel('Time (s)')
ylabel('Velocity (m/s)')
grid on
title('Sphere Velocity vs. Time')

subplot(3,1,2)
plot(realtime(valid), -deviation(valid),'LineWidth',2)
xlabel('Time(s)')
ylabel('Deviation from centerline (m)')
grid on
title('Sphere Deviation vs. Time')

%% ---------------- VIDEO DISPLAY ----------------
vid.CurrentTime = startFrame / fps_vidtime;
idx = 1;
%figure;
subplot(3,1,3)
while hasFrame(vid) && idx+startFrame <= endFrame
    frame = readFrame(vid);
    %idx = round(vid.CurrentTime*fps);
    imshow(frame); hold on;

    % Draw tube axis
    t = linspace(-1000,1000,2);
    linePts = tubeCenter + t'*tubeAxis;
    plot(linePts(:,1), linePts(:,2),'r-','LineWidth',2);
    
    % Draw tracked sphere
    % if idx<=nFrames && ~isnan(centers(idx,1))
    %     plot(centers(idx,1), centers(idx,2),'go','MarkerSize',10,'LineWidth',2);
    % end
    viscircles(centers(idx,:), sphereRadius, 'Color', 'g', 'LineWidth', 2);


    hold off;
    title(sprintf('Frame %d',idx+startFrame));
    drawnow;
    idx = idx+1;
end