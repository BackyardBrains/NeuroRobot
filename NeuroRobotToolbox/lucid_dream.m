
%% Lucid dream

clear
% clc

imdim = 100;
reward_states = [1 7 8 19 24];
data_dir_name = 'C:\Users\Christopher Harris\Dataset 1\';

load(strcat(data_dir_name, 'labels.mat'))
unique_states = unique(labels);
n_unique_states = length(unique_states);

% image_dir = dir(fullfile(data_dir_name, '**\Rec*\*.png'));
% torque_dir = dir(fullfile(data_dir_name, '**\Rec*\*torques.mat'));
image_dir = dir(fullfile(data_dir_name, '**\Agent*\*.png'));
torque_dir = dir(fullfile(data_dir_name, '**\Agent*\*torques.mat'));
ntorques = size(torque_dir, 1);
nimages = size(image_dir, 1);
ntuples = size(torque_dir, 1);

load(strcat(data_dir_name, 'torque_data2'))
load(strcat(data_dir_name, 'randomwalk_net'))

%%
figure(2)
clf
ax1 = subplot(1,2,1);
im1 = image(zeros(imdim, imdim, 3, 'uint8'));
set(gca, 'xtick', [], 'ytick', [])
tx1 = title('Left image');
ax2 = subplot(1,2,2);
im2 = image(zeros(imdim, imdim, 3, 'uint8'));
set(gca, 'xtick', [], 'ytick', [])
tx2 = title('Right image');

%%
for ntuple = 36192:ntuples

    this_ind = ntuple*2-1;    
    left_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
    left_im = imresize(left_im, [imdim imdim]);

    this_ind = ntuple*2;
            
    right_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
    right_im = imresize(right_im, [imdim imdim]);

    im1.CData = left_im;
    im2.CData = right_im;

    [left_state, left_score] = classify(net, left_im);
    [right_state, right_score] = classify(net, right_im);        
        
    left_state = find(unique_states == left_state);
    right_state = find(unique_states == right_state);

    left_score = left_score(left_state);
    right_score = right_score(right_state);

    this_motor_vector = torque_data(ntuple, :);

    clc
    disp(horzcat('nstep: ', num2str(ntuple)))
    disp(horzcat('left state: ', num2str(left_state), ', confidence: ', num2str(left_score)))
    disp(horzcat('right state: ', num2str(right_state), ', confidence: ', num2str(right_score)))
    disp(horzcat('torques: ', num2str(round(this_motor_vector))))

    tx1.String = horzcat('left state: ', num2str(left_state), ', confidence: ', num2str(left_score));
    tx2.String = horzcat('right state: ', num2str(right_state), ', confidence: ', num2str(right_score));

    drawnow

end