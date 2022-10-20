
%% Lucid dream
% Demo Sleep:Hippocampus

imdim = 100;
localdata_dir_name = 'C:\Users\Christopher Harris\Dataset 1\';
shared_data_dir_name = '.\Brains\';
rec_dir_name = 'PreTraining\';

% image_dir = dir(fullfile(strcat(data_dir_name, rec_dir_name), '**\*.png'));
% torque_dir = dir(fullfile(strcat(data_dir_name, rec_dir_name), '**\*torques.mat'));
% save(strcat(shared_data_dir_name, 'image_dir'), 'image_dir')
% save(strcat(shared_data_dir_name, 'torque_dir'), 'torque_dir')

load(strcat(shared_data_dir_name, 'image_dir'))
load(strcat(shared_data_dir_name, 'torque_dir'))
load(strcat(shared_data_dir_name, 'livingroom_net'))
load(strcat(shared_data_dir_name, 'livingroom_labels'))

nimages = size(image_dir, 1);
ntuples = nimages/2;
disp(horzcat('ntuples: ', num2str(ntuples)))
unique_states = unique(labels);
n_unique_states = length(unique_states);
disp(horzcat('n unique states: ', num2str(n_unique_states)))


%% Prepare
figure(6)
clf
set(gcf, 'position', [80 80 1320 600], 'color', 'w')
ax1 = axes('position', [0.05 0.1 0.4 0.85]);
im1 = image(zeros(227, 227, 3, 'uint8'));
set(gca, 'xtick', [], 'ytick', [])
tx1 = title('');
ax2 = axes('position', [0.55 0.1 0.4 0.85]);
im2 = image(zeros(227, 227, 3, 'uint8'));
set(gca, 'xtick', [], 'ytick', [])
tx2 = title('');
ax3 = axes('position', [0.3 0.025 0.4 0.05], 'xcolor', 'w', 'ycolor', 'w');
plot([0 10], [0 10], 'color', 'w')
set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
tx3 = text(5, 5, '', 'HorizontalAlignment','center', 'VerticalAlignment', 'middle');


%%
ntuple = randsample(ntuples, 1);

this_ind = ntuple*2-1;    
left_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
left_im_small = imresize(left_im, [imdim imdim]);
[left_state, left_score] = classify(net, left_im_small);
left_state = find(unique_states == left_state);
left_score = left_score(left_state);
im1.CData = left_im;
tx1.String = horzcat('Left state: ', num2str(left_state), ' (', char(labels(left_state)), '), confidence: ', num2str(left_score));

this_ind = ntuple*2;    
right_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
right_im_small = imresize(right_im, [imdim imdim]);
[right_state, right_score] = classify(net, right_im_small);
right_state = find(unique_states == right_state);
right_score = right_score(right_state);
im2.CData = right_im;
tx2.String = horzcat('Right state: ', num2str(right_state), ' (', char(labels(right_state)), '), confidence: ', num2str(right_score));

%     best_score = state_info(left_state, 2);
%     best_ind = state_info(left_state, 3);
%     this_im = imread(imageIndex.ImageLocation{best_ind});
%     im2.CData = this_im;
%     tx2.String = horzcat('Max selfsim tuple: ', num2str(best_ind), ' from state ', num2str(left_state), ' (', labels(states(left_state)), '), whose avg selfsim is: ', num2str(best_score));

if left_state == right_state
    this_state = left_state;
elseif left_score >= right_score
    this_state = left_state;
else
    this_state = right_state;
end

tx3.String = horzcat('State: ', num2str(this_state), ' (', char(labels(this_state)), ')');

