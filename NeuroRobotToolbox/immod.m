
%% Initialize camera
rak_cam = videoinput('winvideo', 1);
triggerconfig(rak_cam, 'manual');
rak_cam.TriggerRepeat = Inf;
rak_cam.FramesPerTrigger = 1;
rak_cam.ReturnedColorspace = 'rgb';
start(rak_cam)

%% Take and process picture
trigger(rak_cam)
large_frame = getdata(rak_cam, 1);        
[rak_cam_h, rak_cam_w, ~] = size(large_frame);
clf
subplot(2,1,1)
image(large_frame)
subplot(2,1,2)
x = rgb2gray(large_frame);
mean2(x)
histogram(large_frame(:))