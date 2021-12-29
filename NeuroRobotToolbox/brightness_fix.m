% rak_cam = videoinput('winvideo', 1);
% triggerconfig(rak_cam, 'manual');
% rak_cam.TriggerRepeat = Inf;
% rak_cam.FramesPerTrigger = 1;
% rak_cam.ReturnedColorspace = 'rgb';
% start(rak_cam)
trigger(rak_cam)
large_frame = getdata(rak_cam, 1);
tic
% large_frame_2 = imadjust(large_frame,[0 0 0; 0.7 0.7 0.7],[]);
% large_frame_2 = imlocalbrighten(large_frame);
large_frame_2 = histeq(large_frame, 64*4);
toc
clf
subplot(4,1,1)
image(large_frame)
subplot(4,1,2)
histogram(large_frame(:))
subplot(4,1,3)
image(large_frame_2)
subplot(4,1,4)
histogram(large_frame_2(:))