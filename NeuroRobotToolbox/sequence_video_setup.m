
video_fps = 20;
video_compression = 'MPEG-4';

if nrun > 10000
    xt = '';
elseif nrun > 1000
    xt = '0';
elseif nrun > 100
    xt = '00';
elseif nrun > 10
    xt = '000';
else
    xt = '0000';
end

video_file_name = strcat('randwalk_sequence_video_state', num2str(start_state), '_run', xt, num2str(nrun));

this_ind = 30*2-1;    
left_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
left_im = imresize(left_im, [imdim imdim]);

this_ind = 30*2;        
right_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
right_im = imresize(right_im, [imdim imdim]);

figure(10)
clf
set(gcf, 'position', [200 100 1280 720], 'color', 'w')
main_ax = axes('position', [0 0 1 1]);
set(gca, 'xtick', [], 'ytick', [])
title(horzcat('start state = ', num2str(states(30)), ', steps remaining = ', num2str(0)))
montage({left_im right_im})
drawnow

vid_writer = VideoWriter(video_file_name, video_compression);
set(vid_writer, 'FrameRate', video_fps);
open(vid_writer);
