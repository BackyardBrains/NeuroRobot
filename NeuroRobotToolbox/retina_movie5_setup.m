
% close all
% clear
nframes = 3447;
video_fps = 30;
video_file_name = 'retina_movie4';
video_compression = 'MPEG-4';

% load('main_frame')

twop_fps = 2.78;
stim_start_times_in_sec = [10 70 130 190 250 310 370 430 490 550 630 690 750 810 870 930 990 1050 1110 1170];
nstims = 20;
stim_times_in_frames = [];
for nstim = 1:nstims
    start_time = round((stim_start_times_in_sec(nstim) + 0) * twop_fps) + 1;
    end_time = round(start_time + (60 * twop_fps) - 1);
    stim_times_in_frames = [stim_times_in_frames; start_time end_time];
end
stim_str{1} = 'leftward bright bar';
stim_str{2} = 'rightward bright bar';
stim_str{3} = 'upward bright bar';
stim_str{4} = 'downward bright bar';
stim_str{5} = 'small bright leftward spot';
stim_str{6} = 'small bright rightward spot';
stim_str{7} = 'medium bright leftward spot';
stim_str{8} = 'medium bright rightward spot';
stim_str{9} = 'large bright leftward spot';
stim_str{10} = 'large bright rightward spot';
stim_str{11} = 'leftward dark bar';
stim_str{12} = 'rightward dark bar';
stim_str{13} = 'upward dark bar';
stim_str{14} = 'downward dark bar';
stim_str{15} = 'small dark leftward spot';
stim_str{16} = 'small dark rightward spot';
stim_str{17} = 'medium dark leftward spot';
stim_str{18} = 'medium dark rightward spot';
stim_str{19} = 'large dark leftward spot';
stim_str{20} = 'large dark rightward spot';

figure(10)
clf
set(gcf, 'position', [10 100 1840 837], 'color', 'w')
main_ax = axes('position', [0 0 1 1]);
colormap('gray')

vid_writer = VideoWriter(video_file_name, video_compression);
set(vid_writer, 'FrameRate', video_fps);
open(vid_writer);
