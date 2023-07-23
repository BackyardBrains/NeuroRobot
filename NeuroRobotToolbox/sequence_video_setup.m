
video_fps = 10;
video_compression = 'MPEG-4';

this_ind = 30*2-1;    
left_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
left_im = imresize(left_im, [imdim imdim]);

this_ind = 30*2;        
right_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
right_im = imresize(right_im, [imdim imdim]);

figure(10)
clf
set(gcf, 'position', [200 100 1280/2 720/2], 'color', 'w')
main_ax = axes('position', [0 0 1 1]);
set(gca, 'xtick', [], 'ytick', [])
montage({left_im right_im})
title(horzcat('start state = ', num2str(states(30)), ', steps remaining = ', num2str(0)))

drawnow

vid_writer = VideoWriter(video_file_name, video_compression);
set(vid_writer, 'FrameRate', video_fps);
open(vid_writer);
