function sphereTrackingGUI()
clear; clc; close all;

%% ================= USER INPUTS ===================
videoFile = 'vid_2001-12-16_18-55-57.mp4';   % <-- CHANGE THIS
fps = 6200;                     % camera frame rate
tubeDiameter_mm = 2;           % REAL tube diameter (mm)

%% ===============================================
vid = VideoReader(videoFile);
frame1 = readFrame(vid);
gray1 = rgb2gray(frame1);

%% ===== USER DEFINES TUBE EXIT LINE =====
figure; imshow(frame1);
title('Click RIGHT EDGE of tube exit (x=0 reference)');
[xTube, ~] = ginput(1);

title('Draw polygon around tube to EXCLUDE, double click to finish');
tubeMask = roipoly;

%% ===== PIXEL TO MM CALIBRATION =====
title('Click LEFT and RIGHT edges of tube to measure diameter');
[x1,~] = ginput(1);
[x2,~] = ginput(1);
tubeDiameter_pixels = abs(x2 - x1);
px2mm = tubeDiameter_mm / tubeDiameter_pixels;

close;

%% ===== RESET VIDEO =====
vid = VideoReader(videoFile);
prev = rgb2gray(readFrame(vid));

centroids = [];
radii = [];
frameNum = 0;

%% ===== MAIN LOOP =====
while hasFrame(vid)
    frame = readFrame(vid);
    gray = rgb2gray(frame);

    % Remove tube
    gray(tubeMask) = 255;

    % Motion detection
    diffFrame = imabsdiff(gray, prev);
    prev = gray;

    bw = imbinarize(diffFrame,'adaptive');
    bw = bwareaopen(bw,50);
    bw = imfill(bw,'holes');

    stats = regionprops(bw,'Centroid','EquivDiameter','Area');

    found = false;
    for k = 1:length(stats)
        D = stats(k).EquivDiameter;

        % Sphere size constraint
        if D > 0.2*tubeDiameter_pixels && D < 2*tubeDiameter_pixels
            c = stats(k).Centroid;

            % Must be downstream of tube
            if c(1) > xTube
                found = true;
                break
            end
        end
    end

    if found
        centroids(end+1,:) = c;
        radii(end+1) = D/2;
    else
        centroids(end+1,:) = [NaN NaN];
        radii(end+1) = NaN;
    end

    frameNum = frameNum + 1;
end

%% ===== CONVERT TO DISTANCE =====
t = (0:length(centroids)-1)/fps;

x = (centroids(:,1) - xTube)*px2mm;   % mm from tube exit
y = centroids(:,2)*px2mm;

% deviation from centerline
y0 = mean(y(1:10)); % initial centerline
dev = y - y0;

%% ===== VELOCITY =====
vx = gradient(x,t);   % mm/s

%% ================== FIGURE UI ===================
fig = figure('Name','Sphere Tracking','Position',[100 100 1200 800]);

% Video axes
axVid = subplot(2,2,1);
imshow(frame1); hold on;
hCircle = viscircles([0 0],1,'Color','g');
hLine = xline(xTube,'r','LineWidth',2);
title('Tracked Sphere');

% Velocity plot
axV = subplot(2,2,2);
plot(x,vx,'k','LineWidth',2);
xlabel('Distance from tube exit (mm)');
ylabel('Velocity (mm/s)');
grid on; title('Velocity vs Distance');

% Deviation plot
axD = subplot(2,2,4);
plot(x,dev,'b','LineWidth',2);
xlabel('Distance from tube exit (mm)');
ylabel('Deviation (mm)');
grid on; title('Deviation from Centerline');

%% ===== FRAME SLIDER =====
uicontrol('Style','slider','Min',1,'Max',length(x),'Value',1,...
    'Position',[200 20 800 20],'Callback',@updateFrame);

%% ===== FRAME UPDATE FUNCTION =====
vid2 = VideoReader(videoFile);
frames = {};
while hasFrame(vid2)
    frames{end+1} = readFrame(vid2);
end

function updateFrame(src,~)
    f = round(src.Value);
    axes(axVid);
    imshow(frames{f}); hold on;

    if ~isnan(centroids(f,1))
        viscircles(centroids(f,:),radii(f),'Color','g');
    end
    xline(xTube,'r','LineWidth',2);
    title(sprintf('Frame %d',f));
end

end