
%% Lucid dream
% Demo Sleep:Basal Ganglia

% image_dir = dir(fullfile(strcat(data_dir_name, rec_dir_name), '**\*.png'));
% torque_dir = dir(fullfile(strcat(data_dir_name, rec_dir_name), '**\*torques.mat'));
% save(strcat(data_dir_name, 'image_dir'), 'image_dir')
% save(strcat(data_dir_name, 'torque_dir'), 'torque_dir')
load(strcat(data_dir_name, 'image_dir'))
load(strcat(data_dir_name, 'torque_dir'))

ntorques = size(torque_dir, 1);
nimages = size(image_dir, 1);
ntuples = size(torque_dir, 1);
disp(horzcat('ntuples: ', num2str(ntuples)))

load(strcat(data_dir_name, 'livingroom_net'))

load(strcat(data_dir_name, 'labels.mat'))
unique_states = unique(labels);
n_unique_states = length(unique_states);
disp(horzcat('n unique states: ', num2str(n_unique_states)))


%% Prepare
figure(6)
clf
set(gcf, 'position', [80 80 1320 530], 'color', 'w')
ax1 = subplot(1,2,1);
im1 = image(zeros(227, 227, 3, 'uint8'));
set(gca, 'xtick', [], 'ytick', [])
tx1 = title('');
ax2 = subplot(1,2,2);
im2 = image(zeros(227, 227, 3, 'uint8'));
set(gca, 'xtick', [], 'ytick', [])
tx2 = title('');


%%
for n = 1:100

%     ntuple = start at random ind and proceed sequentially, hopefully
%     showing how action and states are entangled

    this_ind = ntuple*2-1;    
    left_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
    left_im_small = imresize(left_im, [imdim imdim]);
    [left_state, left_score] = classify(net, left_im_small);
    left_state = find(unique_states == left_state);
    left_score = left_score(left_state);
    im1.CData = left_im;
    tx1.String = horzcat('Rand tuple: ', num2str(ntuple), ', state: ', num2str(left_state), ', conf: ', num2str(left_score));

    best_score = state_info(left_state, 2);
    best_ind = state_info(left_state, 3);
    this_im = imread(imageIndex.ImageLocation{best_ind});
    im2.CData = this_im;
    tx2.String = horzcat('Max selfsim tuple: ', num2str(best_ind), ' from state ', num2str(left_state), ', whose mean selfsim is: ', num2str(best_score));

%     this_motor_vector = torque_data(ntuple, :);
    
%     clc 
%     disp(horzcat('ntuple: ', num2str(ntuple)))
%     disp(horzcat('torques: ', num2str(round(this_motor_vector))))

    drawnow
    pause

end

