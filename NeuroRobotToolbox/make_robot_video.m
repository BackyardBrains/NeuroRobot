
video_fps = 10;
video_compression = 'MPEG-4';

% dataset_dir_name = 'C:\SpikerBot ML Datasets\';
dataset_dir_name = strcat(userpath, '\Datasets\');

rec_dir_name = '';
image_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*_x.png'));
ntuples = numel(image_dir);

nruns = 20;
ntuples_per_run = 300;

start_ind = 1;    
im = imread(strcat(image_dir(start_ind).folder, '\',  image_dir(start_ind).name));

figure(10)
clf
set(gcf, 'position', [300 200 1280/2 720/2], 'color', 'w')
main_ax = axes('position', [0 0 1 1]);
cdraw = image(im);
set(gca, 'xtick', [], 'ytick', [])
title(horzcat('ntuple = ', num2str(start_ind)))

drawnow

for nrun = 1:nruns
    this_start_ind = randsample(ntuples-ntuples_per_run, 1);

    if nrun >= 10
        x = '0';
    else
        x = '00';
    end

    video_file_name = strcat(dataset_dir_name, 'video_exploration_', x, num2str(nrun));
    vid_writer = VideoWriter(video_file_name, video_compression);
    set(vid_writer, 'FrameRate', video_fps);
    open(vid_writer);

    for ntuple = this_start_ind:this_start_ind + ntuples_per_run - 1
    
        im = imread(strcat(image_dir(ntuple).folder, '\',  image_dir(ntuple).name));
    
        cdraw.CData = im;
        title(horzcat('ntuple = ', num2str(ntuple)))
        writeVideo(vid_writer, getframe(10));
        drawnow
    
        pause(0.01)

    end

    close(vid_writer);

end

