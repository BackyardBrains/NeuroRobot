
%% Get vals

if ml_speed_select.Value == 1 % Fast
    nsmall = 1000;
    bof_branching = 200;
    nmedium = 1000;
    init_n_unique_states = 100;
    min_size = 25;
elseif ml_speed_select.Value == 2 % Medium
    nsmall = 5000;
    bof_branching = 500;
    nmedium = 5000;
    init_n_unique_states = 150;
    min_size = 45;
elseif ml_speed_select.Value == 3 % Slow
    nsmall = 7500;
    bof_branching = 500;
    nmedium = 7500;
    init_n_unique_states = 200;
    min_size = 65;
end

disp(horzcat('nsmall = ', num2str(nsmall)))
disp(horzcat('nmedium = ', num2str(nmedium)))
disp(horzcat('bof_branching = ', num2str(bof_branching)))
disp(horzcat('init_n_unique_states = ', num2str(init_n_unique_states)))
disp(horzcat('min_size = ', num2str(min_size)))

