
% Train an RCNN to detect robots by manually capturing and labelling
% pictures (currently configured to work with any RAK module)


%% Close and clear
close all
% clear
delete(imaqfind)
delete(timerfind)


%% Settings
pulse_period = 0.1;
frame_dir = 'C:\Users\Christopher Harris\Desktop\Pictures\';

%% Prepare
dir_info = dir(frame_dir);
ii = size(dir_info, 1);

%% RCNN
if ~exist('rcnn', 'var')
    disp('loading rcnn...')
    load('rcnn')
    disp('done')
end

%% Sigmoid figure
figure(2)
clf
% subplot(2,2,1)
plot(0.01:0.01:1, sigmoid(0.01:0.01:1, 0.65, 50) * 50)
xlabel('score')
ylabel('cnn out')

%% Figure
figure(1)
clf
set(gcf, 'position', [300 50 740 700])
ax_frame = axes('position', [0.02 0.1 0.96 0.86]);
show_frame = image(zeros(720, 720, 3));
set(gca, 'xtick', [], 'ytick', [])
capture_now = 0;
button_capture = uicontrol('Style', 'pushbutton', 'String', 'Capture', 'units', 'normalized', 'position', [0.02 0.02 0.47 0.06]);
set(button_capture, 'Callback', 'capture_now = 1;', 'FontSize', 12, 'FontName', 'Arial', 'FontWeight', 'bold', 'BackgroundColor', [0.8 0.8 0.8])
button_stop = uicontrol('Style', 'pushbutton', 'String', 'Stop', 'units', 'normalized', 'position', [0.51 0.02 0.47 0.06]);
set(button_stop, 'Callback', 'stop(ground_truth_pulse);', 'FontSize', 12, 'FontName', 'Arial', 'FontWeight', 'bold', 'BackgroundColor', [0.8 0.8 0.8])
fig_title = title('score = 0');
    
%% RAK
if ~exist('RAK5206.mexw64', 'file')
    disp('Building mex')
    rak_mex_build
end
rak_cam = RAK5206_matlab('192.168.100.1', '80');
rak_cam.start();
disp('rak_cam started')
ground_truth_pulse = timer('period', pulse_period, 'timerfcn', '[ii, capture_now] = ground_truth_pulse_code(rak_cam, show_frame, capture_now, ii, frame_dir, fig_title, rcnn);', 'stopfcn', 'disp("ground truth pulse stopped"); close(1);', 'executionmode', 'fixedrate');
start(ground_truth_pulse)

