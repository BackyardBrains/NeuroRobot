

%%%% extcam2robotxy

%% Settings
h = 227;
w = 404;
net_input_size = [h, w];

%% Prepare
robot_xy = [0 0];

%% Initialize webcam video stream
if ~exist('cam', 'var')
    cam = videoinput('winvideo', 1);
    triggerconfig(cam, 'manual');
    cam.TriggerRepeat = Inf;
    cam.FramesPerTrigger = 1;
    cam.ReturnedColorspace = 'rgb';  
end

if strcmp(cam.Running, 'off')
    start(cam)
end

trigger(cam)
prev_frame = getdata(cam, 1); 
prev_uframe = imresize(prev_frame, net_input_size);
trigger(cam)
frame = getdata(cam, 1); 
uframe = imresize(frame, net_input_size);
xframe = imsubtract(rgb2gray(uframe), rgb2gray(prev_uframe));


%% Prepare figure
fig1 = figure(1);
set(fig1, 'position', [420 200 w*2 h*2+20])
set(fig1, 'CloseRequestFcn', 'closereq')
ax1 = axes('position', [0 0.05 1 0.9]);
draw_im = image(uframe);
% draw_im = imagesc(xframe);
hold on
draw_xy = plot(robot_xy(1), robot_xy(2), 'marker', '.', 'markersize', 20, 'color', 'r');
set(ax1, 'xtick', [], 'ytick', [])
title_obj = uicontrol('Style', 'text', 'String', '', 'units', 'normalized', 'position', [0 0.95 1 0.05], ...
    'fontsize', 14, 'horizontalalignment', 'center', 'FontName', 'Comic Book');
button_obj = uicontrol('Style', 'pushbutton', 'String', 'Stop', 'units', 'normalized', 'position', [0 0 1 0.05], ...
    'Callback', 'flag = 1;', 'FontSize', 14, 'FontName', 'Comic Book', 'BackgroundColor', [0.8 0.8 0.8]);


%% Initialize and start runtime timer
if exist('ext_runtime_pulse', 'var') && isvalid(ext_runtime_pulse)
    stop(ext_runtime_pulse)
    delete(ext_runtime_pulse)
end
pause(1)
ext_runtime_pulse = timer('period', 0.33, 'timerfcn', 'ext_runtime_code;', ...
    'stopfcn', 'ext_stop_code', 'executionmode', 'fixedrate');

flag = 0;
nstep = 0;

start(ext_runtime_pulse)

