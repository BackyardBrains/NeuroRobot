

%%
try
    axes(ml_train3_status)
    cla
    tx7 = text(0.03, 0.5, horzcat('Getting tuples...'), 'FontSize', bfsize + 4);
    drawnow
catch
end

disp('Getting tuples')

load(strcat(nets_dir_name, state_net_name, '-ml'))
load(strcat(nets_dir_name, state_net_name, '-labels'))

n_unique_states = length(labels);
disp(horzcat('n unique states: ', num2str(n_unique_states)))

% read ml_data_type here and load correctly, this is the adapted v1
% process, original process and adapted v2 not currently implemented
ml_data_type = 0;

try
    image_dir = imageDatastore(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*large_frame_x.jpg'));    
    torque_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*torque.txt'));
    serial_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*serial.txt'));
    ml_data_type = 1;
    disp('Datasets found and indexed (adapted type 1)')
catch
end

try
    image_dir = imageDatastore(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*large_frame_x.png'));
    serial_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*serial_data.mat'));
    torque_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*torques.mat'));
    ml_data_type = 2;
    disp('Datasets found and indexed (original type)')
catch
end

ntorques = size(torque_dir, 1);
nimages = size(image_dir, 1);
ntuples = ntorques;
disp(horzcat('ntuples: ', num2str(ntuples)))


%% States
get_states
save(horzcat(nets_dir_name, state_net_name, '-states'), 'states')

figure(13)
clf
set(gcf, 'position', [201 241 800 420], 'color', 'w')

histogram(states)
title('States')


%% Torques
get_torques
save(horzcat(nets_dir_name, state_net_name, '-torque_data'), 'torque_data')

