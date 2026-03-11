%% Sphere Detection with Exclusion Region
clc; clear; close all;

% --- USER INPUT ---
videoFile = 'vid_2001-12-16_18-55-57.mp4';  % change to your video file
sphereRadius = 20;             % approximate radius of the sphere in pixels

% --- READ VIDEO ---
vidObj = VideoReader(videoFile);
vidObj.CurrentTime = 0.75;
frame = readFrame(vidObj);     % read first frame

% --- DISPLAY FRAME TO SELECT EXCLUSION REGION ---
figure; imshow(frame); hold on;
title('Draw a rectangle to exclude from detection, double-click when done');

hRect = imrect;                % user draws rectangle
exclusionPos = round(hRect.getPosition()); % [x y width height]
close;

% --- CONVERT TO GRAYSCALE ---
grayFrame = rgb2gray(frame);

% --- CREATE MASK TO EXCLUDE REGION ---
mask = true(size(grayFrame));  % initially include everything
x1 = exclusionPos(1); y1 = exclusionPos(2);
w = exclusionPos(3); h = exclusionPos(4);
mask(y1:y1+h, x1:x1+w) = false; % set exclusion rectangle to false

% --- THRESHOLD TO DETECT DARK OBJECTS ---
bw = grayFrame < 75;          % adjust threshold if needed
bw = bw & mask;                % apply exclusion mask

% --- REMOVE SMALL NOISE ---
bw = bwareaopen(bw, 50);

% --- FIND SPHERE CENTROID ---
stats = regionprops(bw, 'Centroid', 'Area');
[~, idx] = max([stats.Area]);   % assume largest dark object is the sphere
center = stats(idx).Centroid;

% --- DISPLAY FIRST FRAME WITH DETECTION ---
figure;
imshow(frame); hold on;
viscircles(center, sphereRadius, 'Color', 'g', 'LineWidth', 2);
title('Detected Sphere (with exclusion region)');