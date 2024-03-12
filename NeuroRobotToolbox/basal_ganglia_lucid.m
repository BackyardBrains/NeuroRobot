

% % close all
% clear
% 
nseqs = 500;
% 
% get_images = 1;
% get_torques = 0;
% get_combs = 0;
% get_rewards = 0;
% 
% state_net_name = 'tessier';
% rec_dir_name = '';
% dataset_dir_name = 'C:\SpikerBot ML Datasets\';
% nets_dir_name = strcat(userpath, '\Nets\');
% 
steps_per_sequence = 100;

%%
figure(9)
clf
set(gcf, 'position', [80 80 1320 600], 'color', 'w')
ax1 = axes('position', [0.05 0.2 0.4 0.65]);
im1 = image(zeros(227, 227, 3, 'uint8'));
set(gca, 'xtick', [], 'ytick', [])
tx1 = title('');
ax2 = axes('position', [0.55 0.2 0.4 0.65]);
im2 = image(zeros(227, 227, 3, 'uint8'));
set(gca, 'xtick', [], 'ytick', [])
tx2 = title('');
ax3 = axes('position', [0.3 0.025 0.4 0.05], 'xcolor', 'w', 'ycolor', 'w');
plot([0 10], [0 10], 'color', 'w')
set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
tx3 = text(5, 15, '', 'HorizontalAlignment','center', 'VerticalAlignment', 'middle');
tx4 = text(5, 5, '', 'HorizontalAlignment','center', 'VerticalAlignment', 'middle');


%%
rand_inds = randsample(ntuples-steps_per_sequence, nseqs, 0);
for start_tuple = rand_inds'

    for ntuple = start_tuple:start_tuple + (steps_per_sequence - 1)

        this_ind = ntuple;    
        now_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
        im1.CData = now_im;
        tx1.String = horzcat('Obs N: ', num2str(ntuple));
        
        % this_ind = ntuple + 5;
        % next_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
        % im2.CData = next_im;
        % tx2.String = horzcat('Obs N + 5: ', num2str(ntuple + 5));
    
        this_motor_vector = torque_data(ntuple, :);
        this_action = actions(ntuple);
        tx3.String = horzcat('Action: ', num2str(this_action), ', left: ', num2str(this_motor_vector(2)), ', right: ', num2str(this_motor_vector(1)));
        
        this_reward = rewards(ntuple);
        tx4.String = horzcat('Reward: ', num2str(this_reward));
        drawnow
        pause
    end

end

