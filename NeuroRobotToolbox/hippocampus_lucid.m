
%% Lucid dream Hippocampus

close all
clear

localdata_dir_name = 'C:\SpikerBot\livingroom-cairo-1\';
shared_data_dir_name = '.\Brains\';
rec_dir_name = '';

image_dir = dir(fullfile(strcat(localdata_dir_name, rec_dir_name), '**\*large_frame_x.jpg'));
serial_dir = dir(fullfile(strcat(localdata_dir_name, rec_dir_name), '**\*serial.txt'));
torque_dir = dir(fullfile(strcat(localdata_dir_name, rec_dir_name), '**\*torque.txt'));

save(strcat(localdata_dir_name, 'image_dir'), 'image_dir')
save(strcat(localdata_dir_name, 'serial_dir'), 'serial_dir')
save(strcat(localdata_dir_name, 'torque_dir'), 'torque_dir')

% load(strcat(shared_data_dir_name, 'image_dir'))
% load(strcat(shared_data_dir_name, 'serial_dir'))
% load(strcat(shared_data_dir_name, 'torque_dir'))

% load(strcat(shared_data_dir_name, 'livingroom_net'))
% load(strcat(shared_data_dir_name, 'livingroom_labels'))

nimages = size(image_dir, 1);
ndists = size(serial_dir, 1);
ntorques = size(torque_dir, 1);
ntuples = nimages;
disp(horzcat('nimages: ', num2str(nimages)))
disp(horzcat('ndists:',  num2str(ndists)))
disp(horzcat('ntorques:' , num2str(ntorques)))
disp(horzcat('ntuples: ', num2str(ntuples)))

% unique_states = unique(labels);
% n_unique_states = length(unique_states);
% disp(horzcat('n unique states: ', num2str(n_unique_states)))


%% Prepare
figure(6)
clf
set(gcf, 'position', [80 80 1320 600], 'color', 'w')
ax1 = axes('position', [0.05 0.1 0.4 0.85]);
im1 = image(zeros(240, 320, 3, 'uint8'));
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
rand_inds = randsample(ntuples/2, 1);

for ntuple = rand_inds:rand_inds+100

    im = imread(strcat(image_dir(ntuple).folder, '\',  image_dir(ntuple).name));
    im1.CData = im;

    torque_fname = horzcat(torque_dir(ntuple).folder, '\', torque_dir(ntuple).name);
    raw_torques = readtable(torque_fname);

    if ~isempty(raw_torques)
        torque_str = char(raw_torques.Var1);
        semis = strfind(torque_str, ';');
        l_str = torque_str(3:semis(1)-1);
        r_str = torque_str(semis(1)+3:semis(2)-1);   
        l_int = str2double(l_str);
        r_int = str2double(r_str);
        this_motor_vector = [l_int r_int];
        tx3.String = horzcat('Torque, left: ', num2str(this_motor_vector(2)), ', right: ', num2str(this_motor_vector(1)));

    end
    
    % ntuple = randsample(ntuples, 1);
    % 
    % this_ind = ntuple*2-1;    
    % left_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
    % left_im_small = imresize(left_im, [imdim imdim]);
    % im1.CData = left_im;
    % 
    % % [left_state, left_score] = classify(net, left_im_small);
    % % left_state = find(unique_states == left_state);
    % % left_score = left_score(left_state);
    % % tx1.String = horzcat('Left state: ', num2str(left_state), ' (', char(labels(left_state)), '), confidence: ', num2str(left_score));
    % 
    % this_ind = ntuple*2;    
    % right_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
    % im2.CData = right_im;
    % 
    % % [right_state, right_score] = classify(net, right_im_small);
    % % right_state = find(unique_states == right_state);
    % % right_score = right_score(right_state);
    % % tx2.String = horzcat('Right state: ', num2str(right_state), ' (', char(labels(right_state)), '), confidence: ', num2str(right_score));
    % 
    % %     best_score = state_info(left_state, 2);
    % %     best_ind = state_info(left_state, 3);
    % %     this_im = imread(imageIndex.ImageLocation{best_ind});
    % %     im2.CData = this_im;
    % %     tx2.String = horzcat('Max selfsim tuple: ', num2str(best_ind), ' from state ', num2str(left_state), ' (', labels(states(left_state)), '), whose avg selfsim is: ', num2str(best_score));
    % 
    % % if left_state == right_state
    % %     this_state = left_state;
    % % elseif left_score >= right_score
    % %     this_state = left_state;
    % % else
    % %     this_state = right_state;
    % % end
    % 
    % serial_fname = horzcat(serial_dir(ntuple).folder, '\', serial_dir(ntuple).name);
    % load(serial_fname)
    % this_distance = str2double(serial_data{3});
    % this_distance(this_distance == Inf) = 4000;   
    % tx3.String = horzcat('Distance: ', num2str(this_distance));
    % % tx3.String = horzcat('State: ', num2str(this_state), ' (', char(labels(this_state)), ')');
    
    drawnow

    pause

end

