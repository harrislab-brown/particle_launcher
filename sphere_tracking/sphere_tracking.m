%% Sphere Tracking from High-Speed Video - function
% Authors: ChatGPT & Daniel North

function [avgv_0_o, x_o, y_o, vx_o, vy_o, calibration_o, frames_o] = sphere_tracking(videoPath, fileName, fps, tubeDiameter_real, sphereRadius_real, deviationThreshold, deviationThresholdDistance, darkObjectThreshold, d_min, d_max, calibration, frames_i)
%% ---------------- FUNCTION INPUTS (shows example for each input) ----------------
% videoPath = '/Users/danielnorth/Library/CloudStorage/OneDrive-BrownUniversity/Desktop/26Dan''s Stuff/THESIS/Launcher V5 proper tube length test videos/';
% fileName = 'vid_2001-12-16_18-55-57.mp4';
% fps = 6200;                       % frames per second
% tubeDiameter_real = 0.0021;         % meters 
% sphereRadius_real = 0.0015 / 2; % sphere radius in m
% deviationThreshold = 0.0005; % acceptable "spray" in meters - given by Chase to be .5 mm of spray @ distance of deviation_threshold_distance (related to target droplet size)
% deviationThresholdDistance = 0.005;
% startFrame = 6;                   % select the frame to start the video at (choose a frame where the sphere is fully visible)
% endFrame = 87;
% darkObjectThreshold = 75; % for sphere detection (adjust as necessary)
% %for output avg. velocity calculation 
% d_min = 0; % m
% d_max = 0.002; % m

%% ---------------- INITIALIZE OUTPUTS (TO PREVENT UNASSIGNED) ------
avgv_0_o = [];
x_o = [];
y_o = [];
vx_o = [];
vy_o = [];

%% ---------------- STORE INPUTS ----------------

% Store inputs so Redo button can relaunch function
inputArgs = {videoPath, fileName, fps, tubeDiameter_real, ...
    sphereRadius_real, deviationThreshold, deviationThresholdDistance, ...
    darkObjectThreshold, d_min, d_max, calibration, frames_i};

%% ---------------- LOAD VIDEO ----------------
videoFile = append(videoPath, fileName);
%videoFile = fileName;
vid = VideoReader(videoFile);
nFrames = vid.NumFrames;
fprintf('Total frames: %d\n', nFrames);
fps_vidtime = vid.NumFrames / vid.Duration; % because the video plays in slo-mo (and not in real time), we need a way to calculate the time in the video playback that corresponds to any given frame

% %% Read start frame for calibration
% frame1 = read(vid, startFrame);

%% ---------------- FRAME RANGE SELECTION ----------------
if isempty(frames_i)
    nFrames = vid.NumFrames;
    
    % Create figure 
    selectFig = figure('Name','Select Frame Range', ...
        'NumberTitle','off', ...
        'WindowStyle','normal');  % floating figure
    
    % Axes for video
    axSelect = axes('Parent',selectFig);
    vid.CurrentTime = 0;
    frame = readFrame(vid);
    hImgSelect = imshow(frame,'Parent',axSelect);
    title('Use slider to select frame. Click "Set Start" or "Set End".');
    
    currentFrame = 1;
    startFrame = 1;
    endFrame = nFrames;
    
    % Slider
    sliderSelect = uicontrol('Style','slider',...
        'Min',1,'Max',nFrames,'Value',1,...
        'Units','normalized',...
        'Position',[0.2 0.02 0.6 0.04],...
        'SliderStep',[1/(nFrames-1) , 50/(nFrames-1)],...
        'Callback',@sliderSelectCallback);
    
    % Start button
    uicontrol('Style','pushbutton',...
        'String','Set Start Frame',...
        'Units','normalized',...
        'Position',[0.05 0.02 0.12 0.05],...
        'Callback',@setStart);
    
    % End button
    uicontrol('Style','pushbutton',...
        'String','Set End Frame',...
        'Units','normalized',...
        'Position',[0.82 0.02 0.12 0.05],...
        'Callback',@setEnd);
    
    % Confirm button
    uicontrol('Style','pushbutton',...
        'String','Confirm',...
        'FontWeight','bold',...
        'BackgroundColor',[0.2 0.7 0.2],...
        'Units','normalized',...
        'Position',[0.4 0.08 0.2 0.06],...
        'Callback',@confirmSelection);
    
    % --- Display for selected frames ---
    
    startText = uicontrol('Style','text',...
        'Units','normalized',...
        'Position',[0.05 0.9 0.25 0.05],...
        'FontSize',11,...
        'FontWeight','bold',...
        'BackgroundColor',[0.95 0.95 0.95],...
        'HorizontalAlignment','left',...
        'String',sprintf('Start Frame: %d', startFrame));
    
    endText = uicontrol('Style','text',...
        'Units','normalized',...
        'Position',[0.7 0.9 0.25 0.05],...
        'FontSize',11,...
        'FontWeight','bold',...
        'BackgroundColor',[0.95 0.95 0.95],...
        'HorizontalAlignment','right',...
        'String',sprintf('End Frame: %d', endFrame));
    
    uiwait(selectFig);   % pause function until Confirm pressed
else
    startFrame = frames_i(1);
    endFrame = frames_i(2);
end
frames_o = [startFrame endFrame];

%% After confirmation
vid.CurrentTime = (startFrame-1) / fps_vidtime;
frame1 = readFrame(vid);

%% ---------------- CALIBRATION ----------------
if isempty(calibration)
    %% User clicks tube edge and tube edge
    figure; imshow(frame1); title('Click one corner of tube at outlet, then the other corner.');
    [xc, yc] = ginput(2);
    tubeEdgeUpper = [xc(1), yc(1)];
    tubeEdgeLower   = [xc(2), yc(2)];
    tubeCenter = (tubeEdgeLower(:) + tubeEdgeUpper(:)).'/2;
    
    tubeDiameter_pixels = 1*norm(tubeEdgeUpper - tubeEdgeLower);
    meter_per_pixel = tubeDiameter_real / tubeDiameter_pixels;
    %also get sphere radius in pixels here:
    sphereRadius = (sphereRadius_real) / meter_per_pixel; % convert sphere radius from mm to meters in pixel scale
    
    %store scale outputs:
    scale_o = [tubeCenter, meter_per_pixel, sphereRadius];
    
    fprintf('Pixel-to-meter scale: %.6e m/pixel\n', meter_per_pixel);
    
    %% Define tube axis (centerline)
    figure; imshow(frame1); title('Click two points defining tube axis direction (select two points on either edge of tube).');
    [xline, yline] = ginput(2);
    p1 = [xline(1), yline(1)];
    p2 = [xline(2), yline(2)];
    tubeAxis = p2 - p1;
    tubeAxis = tubeAxis / norm(tubeAxis); % unit vector
    %store output:
    tubeAxis_o = tubeAxis;
    
    %% Select exclusion region (to exclude tube, mirrored tube+sphere from analysis)
    figure; imshow(frame1);
    title({'Click and drag to draw exclusion rectangles to isolate sphere of interest.'; ...
           'Rectangles must not overlap or extend beyond video frame.'; ...
           'Rectangles can be moved and resized after they are drawn. Double-click rectangle to confirm.'});
    
    exclusionRects = [];   % store all rectangles
    
    while true
        hRect = imrect;
        
        pos = wait(hRect);     % wait until user double-clicks rectangle
        
        if isempty(pos)
            break
        end
        
        exclusionRects = [exclusionRects; round(pos)];
        
        % draw permanent rectangle so user sees it
        rectangle('Position',pos,'EdgeColor','r','LineWidth',2);
        
        % ask if user wants another
        choice = questdlg('Add another exclusion region?', ...
                          'Continue?', ...
                          'Yes','Done','Yes');
                      
        if strcmp(choice,'Done')
            break
        end
    end
    
    exclusionRects_o = exclusionRects;
    
    close;
    
    %% Store calibration info (in case you have a bunch of vids from the same exact perspective and don't want to have to redefine tube axis, exclusion rectangles, etc. every time)
    calibration_o = {exclusionRects_o, scale_o, tubeAxis_o};
else
    %extract the calibration data if given as input:
    exclusionRects = cell2mat(calibration{1,1}(1));
    scale = cell2mat(calibration{1,1}(2));
    tubeAxis = cell2mat(calibration{1,1}(3));
    tubeCenter = [scale(1), scale(2)];
    meter_per_pixel = scale(3);
    sphereRadius = scale(4);

    calibration_o = calibration;
end


%% Reset video
vid.CurrentTime = startFrame / fps_vidtime;



%% ---------------- STORAGE ----------------
centers = nan(nFrames,2);
distFromTube = nan(nFrames,1);
deviation = nan(nFrames,1);
speed = nan(nFrames,1);

%% ---------------- PROCESS FRAMES ----------------
frameIdx = 1;
while hasFrame(vid) && frameIdx+startFrame <= endFrame
    % --- INITIALIZE FRAME ---
    frame = readFrame(vid);
    gray = rgb2gray(frame);
    
    % --- CREATE MASK TO EXCLUDE TUBE ---
    mask = true(size(gray));
    [imgH, imgW] = size(gray);
    
    for k = 1:size(exclusionRects,1)
    
        x1 = exclusionRects(k,1);
        y1 = exclusionRects(k,2);
        w  = exclusionRects(k,3);
        h  = exclusionRects(k,4);
    
        % Compute bounds
        xStart = max(1, x1);
        yStart = max(1, y1);
        xEnd   = min(imgW, x1 + w);
        yEnd   = min(imgH, y1 + h);
    
        % Only apply if rectangle is still valid
        if xStart <= xEnd && yStart <= yEnd
            mask(yStart:yEnd, xStart:xEnd) = false;
        end
    
    end

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
    deviation(frameIdx) = (c(2) - tubeCenter(2)) * meter_per_pixel * -1; %-1 b/c axes are flipped in matlab I think
    frameIdx = frameIdx + 1;
end
distFromTube_mm = distFromTube * 1000;
deviation_mm = deviation * 1000;

%% ---------------- VELOCITY ----------------
dt = 1/fps;
vx = gradient(distFromTube, dt);
vy = gradient(deviation, dt);
velocity = [vx, vy];
speed = vecnorm(velocity, 2, 2);

%calculate avg velocity from d_min to some distance from tube d_max (this serves as the launcher output velocity for the video):
regionIdx = distFromTube >= d_min & distFromTube <= d_max & ~isnan(speed);
avgv_0 = mean(speed(regionIdx), 'omitnan');

% %% ---------------- DEVIATION @ THRESHOLD DISTANCE ----------------
% 
% % Remove NaNs
% validIdx = ~isnan(distFromTube) & ~isnan(deviation);
% 
% % Interpolate deviation at desired distance
% deviation_at_d = interp1( ...
%     distFromTube(validIdx), ...
%     deviation(validIdx), ...
%     deviationThresholdDistance, ...
%     'linear');
% 
% fprintf('Deviation at %.3f mm = %.4f mm\n',deviationThresholdDistance*1000, deviation_at_d*1000);

%% ---------------- DEVIATION @ THRESHOLD DISTANCE ----------------
% Only consider valid, non-NaN points
validIdx = ~isnan(distFromTube) & ~isnan(deviation);

% Remove duplicates in distFromTube
[distUnique, ia] = unique(distFromTube(validIdx), 'stable');
deviationUnique = deviation(validIdx);
deviationUnique = deviationUnique(ia);

% Now safely interpolate
deviation_at_d = interp1(distUnique, deviationUnique, deviationThresholdDistance, 'linear');

fprintf('Deviation at %.3f mm = %.4f mm\n', deviationThresholdDistance*1000, deviation_at_d*1000);

%% ================= GUI FIGURE =================
% fig = figure('Name','Sphere Tracking GUI','NumberTitle','off','Position',[100 100 1200 800]);
% 
% % Axes layout
% axVel = subplot(3,2,1);
% axDev = subplot(3,2,3);
% axVid = subplot(3,2,[2 4 6]);
close all; % close the calibration figures
fig = figure('Name','Particle Launcher Sphere Tracking','NumberTitle','off',...
             'Position',[100 100 1200 900]);

% Create a panel as a border
hPanel = uipanel('Units','normalized', ...
    'Position',[0.68 0.915 0.28 0.07], ...   % [x y width height] in figure
    'BackgroundColor',[0.95 0.95 0.95], ...
    'BorderType','line');                     % this is the border

% Create the text inside the panel
avgVelText = uicontrol('Parent', hPanel, ...
    'Style','text', ...
    'Units','normalized', ...
    'Position',[0 0 1 1], ...                % fill the panel
    'FontSize',12, ...
    'FontWeight','bold', ...
    'BackgroundColor',[0.95 0.95 0.95], ... % same as panel for seamless
    'ForegroundColor',[0 0 0], ...
    'HorizontalAlignment','center', ...
    'String', sprintf('Average Speed (%.2f–%.2f mm): %.3f m/s \n Deviation @ %.2f mm: %.3f mm',... 
    (d_min*1000), (d_max*1000), avgv_0, deviationThresholdDistance*1000, deviation_at_d*1000));


% Axes stacked vertically
axVel = subplot(4,1,1);
axDist = subplot(4,1,2);
axDev = subplot(4,1,3);
axVid = subplot(4,1,4);

% Ensure outputs are set if user manually closes the figure
set(fig, 'CloseRequestFcn', @closeFigureCallback);

%% ================= PLOTS =================
valid = ~isnan(distFromTube);
frames = startFrame:(startFrame+frameIdx-2);
realtime = frames./fps;

% Velocity plot
axes(axVel);
hVelPlot = plot(realtime(valid), speed(valid),'LineWidth',2);
hold on;
hVelMarker = plot(realtime(1), speed(1),'ro','MarkerSize',8,'LineWidth',2);
xlabel('Time (s)'); ylabel('Speed (m/s)');
grid on; title('2D Speed vs. Video Time');

% Displacement plot (distance from tube outlet along tube axis
axes(axDist);
hDispPlot = plot(realtime(valid), distFromTube_mm(valid),'LineWidth',2);
hold on;
thresholdDistanceLine = repmat(deviationThresholdDistance, 1, numel(realtime));
thresholdDistanceLine_mm = thresholdDistanceLine * 1000;
plot(realtime, thresholdDistanceLine_mm,'m--','LineWidth',2);
hDistMarker = plot(realtime(1), distFromTube_mm(1),'ro','MarkerSize',8,'LineWidth',2);
xlabel('Time (s)'); ylabel('Displacement (mm)');
grid on; title('Horizontal Displacement Relative to Barrel Tip vs. Video Time');
legend('', 'Deviation Threshold Distance', '');

% Deviation plot
axes(axDev);
hDevPlot = plot(realtime(valid), deviation_mm(valid),'LineWidth',2);
hold on;
thresholdLine = repmat(deviationThreshold, 1, numel(realtime));
thresholdLine_mm = thresholdLine * 1000;
plot(realtime, thresholdLine_mm,'r--','LineWidth',2);
plot(realtime, -thresholdLine_mm,'r--','LineWidth',2);
hDevMarker = plot(realtime(1), deviation_mm(1),'ro','MarkerSize',8,'LineWidth',2);
xlabel('Time (s)'); ylabel('Deviation (mm)');
grid on; title('Vertical Deviation Relative to Barrel Centerline vs. Video Time');
legend('', 'Deviation Thresholds', '','');

%% ================= VIDEO INITIAL FRAME =================
vid.CurrentTime = startFrame / fps_vidtime;
frame = readFrame(vid);
axes(axVid);
hImg = imshow(frame);
hold on;

% Tube axis line
t = linspace(-1000,1000,2);
linePts = tubeCenter + t'*tubeAxis;
plot(linePts(:,1), linePts(:,2),'r-','LineWidth',2);

% Sphere circle
hCircle = viscircles(centers(1,:), sphereRadius,'Color','g','LineWidth',2);

hold off;
title('Tracked Sphere');

%% ================= SLIDER =================
slider = uicontrol('Style','slider',...
    'Min',1,'Max',length(frames),'Value',1,...
    'Units','normalized','Position',[0.2 0.02 0.5 0.04],...
    'Callback',@sliderCallback);

%% ================= PLAY BUTTON =================
isPlaying = false;
btn = uicontrol('Style','togglebutton','String','Play',...
    'Units','normalized','Position',[0.05 0.02 0.1 0.04],...
    'Callback',@playCallback);

%% ================= REDO & DONE BUTTONS =================

% --- REDO BUTTON (red) ---
redoBtn = uicontrol('Style','pushbutton',...
    'String','Redo',...
    'Units','normalized',...
    'Position',[0.87 0.02 0.1 0.05],...
    'FontWeight','bold',...
    'BackgroundColor',[0.8 0.2 0.2],...   % red
    'ForegroundColor',[1 1 1],...
    'Callback',@redoCallback);

% --- DONE BUTTON (green) ---
doneBtn = uicontrol('Style','pushbutton',...
    'String','Done',...
    'Units','normalized',...
    'Position',[0.75 0.02 0.1 0.05],...
    'FontWeight','bold',...
    'BackgroundColor',[0.2 0.7 0.2],...   % green
    'ForegroundColor',[1 1 1],...
    'Callback',@doneCallback);

%% ================= WAIT =================
% so long as GUI is still open, don't end the function (so that it
% doesnt end with outputs unassigned)
waitfor(fig);

%% ================= CALLBACK FUNCTIONS =================
    function sliderSelectCallback(src,~)
        currentFrame = round(get(src,'Value'));
        vid.CurrentTime = (currentFrame-1) / fps_vidtime;
        frame = readFrame(vid);
        set(hImgSelect,'CData',frame);
        title(sprintf('Frame %d', currentFrame));
    end

    function setStart(~,~)
        startFrame = currentFrame;
        set(startText,'String',sprintf('Start Frame: %d', startFrame));
    end

    function setEnd(~,~)
        endFrame = currentFrame;
        set(endText,'String',sprintf('End Frame: %d', endFrame));
    end

    function confirmSelection(~,~)
        if endFrame <= startFrame
            errordlg('End Frame must be greater than Start Frame');
            return
        end
        uiresume(selectFig);
        close(selectFig);
    end
    
    function sliderCallback(~,~)
        idx = round(get(slider,'Value'));
        updateFrame(idx);
    end

    function playCallback(src,~)
        isPlaying = get(src,'Value');
        if isPlaying
            set(src,'String','Pause');
            while isPlaying && ishandle(fig)
                idx = round(get(slider,'Value'));
                idx = idx + 1;
                if idx > length(frames)
                    idx = 1;
                end
                set(slider,'Value',idx);
                updateFrame(idx);
                drawnow;
                pause(1/fps); % real-time playback speed
                isPlaying = get(src,'Value');
            end
        else
            set(src,'String','Play');
        end
    end

    function redoCallback(~,~)
        close(fig);           % close current GUI
        [avgv_0_o, x_o, y_o, vx_o, vy_o] = sphere_tracking(inputArgs{:});   % relaunch function, ensuring we capture the outputs
    end

    function doneCallback(~,~)
        % return outputs and close the GUI
        avgv_0_o = avgv_0;
        x_o = distFromTube;
        y_o = deviation;
        vx_o = vx;
        vy_o = vy;
        close(fig);   
    end

    function closeFigureCallback(~,~)
        % Assign safe defaults if user closes window manually
        avgv_0_o = avgv_0;
        x_o = distFromTube;
        y_o = deviation;
        vx_o = vx;
        vy_o = vy;
        delete(fig);
    end

%% ================= FRAME UPDATE FUNCTION =================
    function updateFrame(idx)
        % Update video frame
        vid.CurrentTime = frames(idx) / fps_vidtime;
        frame = readFrame(vid);
        set(hImg,'CData',frame);

        % Update sphere circle
        delete(hCircle);
        axes(axVid);
        hCircle = viscircles(centers(idx,:), sphereRadius,'Color','g','LineWidth',2);

        % Update plot markers
        t = realtime(idx);
        set(hVelMarker,'XData',t,'YData',speed(idx));
        set(hDistMarker,'XData',t,'YData',distFromTube_mm(idx));
        set(hDevMarker,'XData',t,'YData',deviation_mm(idx));

        %update velocity:
        %set(avgVelText,'String',sprintf('Avg Velocity (0–5 mm): %.3f m/s', avgVel_0_5mm));
    end

 end