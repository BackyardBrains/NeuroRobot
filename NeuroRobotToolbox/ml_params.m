
%% Get vals
ntuples = numel(dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*serial_data.mat')));
disp(horzcat('ntuples: ', num2str(ntuples)))

if ml_speed_select.Value == 1 % Fast
    nsmall = 2000;
    bof_branching = 200;
    nmedium = 2000;
    init_n_unique_states = 100;
    min_size = 40;    
elseif ml_speed_select.Value == 2 % Medium
    nsmall = 5000;
    bof_branching = 400;
    nmedium = 5000;
    init_n_unique_states = 125;
    min_size = 75;
elseif ml_speed_select.Value == 3 % Slow
    nsmall = 8000;
    bof_branching = 500;
    nmedium = 8000;
    init_n_unique_states = 150;
    min_size = 100;
end

disp(horzcat('nsmall = ', num2str(nsmall)))
disp(horzcat('nmedium = ', num2str(nmedium)))
disp(horzcat('bof_branching = ', num2str(bof_branching)))
disp(horzcat('init_n_unique_states = ', num2str(init_n_unique_states)))
disp(horzcat('min_size = ', num2str(min_size)))

