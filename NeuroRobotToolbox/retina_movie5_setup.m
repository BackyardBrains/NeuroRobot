
% close all
% clear
nframes = 3447;
video_fps = 30;
video_file_name = 'retina_movie4';
video_compression = 'MPEG-4';

% load('main_frame')

twop_fps = 2.78;

figure(10)
clf
set(gcf, 'position', [10 100 1840 837], 'color', 'w')
main_ax = axes('position', [0 0 1 1]);
colormap('gray')

vid_writer = VideoWriter(video_file_name, video_compression);
set(vid_writer, 'FrameRate', video_fps);
open(vid_writer);
