%% ============================================================
% ROBUST SPHERE TRACKING WITH GUI SLIDER + INITIAL MARKING FRAME
% MATLAB R2025a
% ============================================================
function sphereTrackingGUI()
clear; clc; close all;

%% ================== USER INPUT ============================
videoFile = 'vid_2001-12-16_18-55-57.mp4';   % CHANGE
fps = 6200;
tubeDiameter_real = 0.002;         % meters

%% ================== LOAD VIDEO ===========================
vid = VideoReader(videoFile);
nFrames = floor(vid.Duration * fps);
vid.CurrentTime = 0;
frame1 = readFrame(vid);
gray1 = rgb2gray(frame1);

%% ================== CALIBRATION ==========================
figure; imshow(frame1);
title('Click tube center, then tube edge');
[xc,yc] = ginput(2);
tubeCenter = [xc(1) yc(1)];
tubeEdge   = [xc(2) yc(2)];

tubeDiameter_pixels = 2*norm(tubeEdge - tubeCenter);
pixel_to_meter = tubeDiameter_real / tubeDiameter_pixels;

%% Tube exit
figure; imshow(frame1);
title('Click RIGHT edge of tube (x=0)');
[x_exit,y_exit] = ginput(1);
tubeExit = [x_exit y_exit];

%% Tube axis
figure; imshow(frame1);
title('Click two points along tube axis (left → right)');
[xl,yl] = ginput(2);
tubeAxis = [xl(2)-xl(1), yl(2)-yl(1)];
tubeAxis = tubeAxis / norm(tubeAxis);

%% ================== SPHERE TEMPLATE ======================
prompt = {'Enter frame number where sphere is clearly visible:'};
dlgtitle = 'Sphere Initial Marking';
dims = [1 40];
definput = {'10'};
answer = inputdlg(prompt,dlgtitle,dims,definput);
startFrame = str2double(answer{1});
if isnan(startFrame) || startFrame < 1 || startFrame > nFrames
    error('Invalid start frame');
end

% Read the chosen frame
vid.CurrentTime = (startFrame-1)/fps;
frameSphere = readFrame(vid);
graySphere = rgb2gray(frameSphere);

figure; imshow(frameSphere);
title('Draw box around sphere');
rect = round(getrect);
template = imcrop(graySphere, rect);

%% ================== STORAGE =============================
centers = nan(nFrames,2);
distFromTube = nan(nFrames,1);
deviation = nan(nFrames,1);

%% ================== TRACKING SETTINGS ===================
searchRadius = 150;      % pixels
corrThreshold = 0.5;     % correlation acceptance

%% ================== PROCESS FRAMES ======================
vid.CurrentTime = (startFrame-1)/fps;
prevPos = tubeExit + 50*tubeAxis; % initial guess

for i = startFrame:nFrames
    if ~hasFrame(vid), break; end
    frame = readFrame(vid);
    gray = rgb2gray(frame);

    % --- SEARCH WINDOW ---
    x0 = round(prevPos(1)-searchRadius);
    y0 = round(prevPos(2)-searchRadius);
    w  = 2*searchRadius; h = 2*searchRadius;
    x0 = max(1,x0); y0 = max(1,y0);
    x1 = min(size(gray,2), x0+w);
    y1 = min(size(gray,1), y0+h);
    roi = gray(y0:y1, x0:x1);

    % --- TEMPLATE MATCH ---
    c = normxcorr2(template, roi);
    [ypeak,xpeak] = find(c == max(c(:)),1);
    score = max(c(:));

    cx = NaN; cy = NaN;

    if score > corrThreshold
        yoff = ypeak - size(template,1);
        xoff = xpeak - size(template,2);
        cx = x0 + xoff + size(template,2)/2;
        cy = y0 + yoff + size(template,1)/2;
    end

    % --- FALLBACK: CENTROID IF TEMPLATE FAILS ---
    if isnan(cx)
        bw = imbinarize(gray,'adaptive','ForegroundPolarity','dark');
        bw = bwareafilt(bw,1);
        stats = regionprops(bw,'Centroid');
        if ~isempty(stats)
            cx = stats.Centroid(1);
            cy = stats.Centroid(2);
        else
            continue
        end
    end

    cpos = [cx cy];
    prevPos = cpos;
    centers(i,:) = cpos;

    % --- DISTANCE FROM TUBE EXIT ---
    rvec = cpos - tubeExit;
    s = dot(rvec, tubeAxis);
    if s < 0, continue; end

    distFromTube(i) = s * pixel_to_meter;

    proj = s*tubeAxis;
    perp = rvec - proj;
    deviation(i) = norm(perp)*pixel_to_meter;
end

%% ================== SMOOTH DATA ========================
distFromTube = fillmissing(distFromTube,'linear');
distFromTube = smoothdata(distFromTube,'sgolay',31);
deviation    = smoothdata(deviation,'sgolay',31);

%% ================== VELOCITY ============================
dt = 1/fps;
velocity = gradient(distFromTube, dt);
velocity = smoothdata(velocity,'sgolay',31);

%% ================== SINGLE FIGURE GUI ===================
f = figure('Name','Sphere Tracking GUI','Position',[100 100 1200 800]);

% Video axis
axVid = subplot(2,2,[1 3]);
imshow(frameSphere); hold on;

% Velocity plot
axV = subplot(2,2,2);
plot(distFromTube, velocity,'LineWidth',2);
xlabel('Distance (m)'); ylabel('Velocity (m/s)');
grid on;

% Deviation plot
axD = subplot(2,2,4);
plot(distFromTube, deviation,'LineWidth',2);
xlabel('Distance (m)'); ylabel('Deviation (m)');
grid on;

%% SLIDER
uicontrol('Style','slider',...
    'Min',1,'Max',nFrames,'Value',startFrame,...
    'Units','normalized',...
    'Position',[0.1 0.01 0.8 0.04],...
    'Callback',@updateFrame);

%% ================== CALLBACK FUNCTION ===================
function updateFrame(src, ~)
    i = round(src.Value);
    vid = VideoReader(videoFile);
    vid.CurrentTime = (i-1)/fps;
    frame = readFrame(vid);
    axes(axVid);
    imshow(frame); hold on;

    % Tube axis
    t = linspace(-2000,2000,2);
    pts = tubeExit + t'*tubeAxis;
    plot(pts(:,1), pts(:,2),'r','LineWidth',2);

    % Tube exit
    plot(tubeExit(1), tubeExit(2),'ro','MarkerSize',12);

    % Sphere
    if ~isnan(centers(i,1))
        plot(centers(i,1), centers(i,2),'go','MarkerSize',10,'LineWidth',2);
    end

    title(sprintf('Frame %d',i));
    hold off;
end

end