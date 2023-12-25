
%% Get vals
ml_get_learn_speed

ntuples = numel(dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*serial_data.mat')));
disp(horzcat('ntuples: ', num2str(ntuples)))
disp(horzcat('learn speed: ', num2str(learn_speed)))

nsmall = round((0.001 * ntuples + 1000) * learn_speed * 2);
bof_branching = round((0.0003 * ntuples + 200) * learn_speed);
nmedium = round((0.005 * ntuples + 3000) * learn_speed);
init_n_unique_states = max([10 round(0.0005 * ntuples * learn_speed) + 10 * learn_speed]);
min_size = max([5 round((0.00015 * ntuples * learn_speed) + 5 * learn_speed)]);

disp(horzcat('nsmall = ', num2str(nsmall)))
disp(horzcat('nmedium = ', num2str(nmedium)))
disp(horzcat('bof_branching = ', num2str(bof_branching)))
disp(horzcat('init_n_unique_states = ', num2str(init_n_unique_states)))
disp(horzcat('min_size = ', num2str(min_size)))

