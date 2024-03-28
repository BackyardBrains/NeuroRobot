
%% Get vals

if ml_speed_select.Value == 1 % Fast
    nsmall = 2000;
    bof_branching = 500;
    nmedium = 2000;
    init_n_unique_states = 200;
    min_size = 50;
elseif ml_speed_select.Value == 2 % Medium
    nsmall = 4000;
    bof_branching = 500;
    nmedium = 4000;
    init_n_unique_states = 240;
    min_size = 60;
elseif ml_speed_select.Value == 3 % Slow
    nsmall = 8000;
    bof_branching = 500;
    nmedium = 8000;
    init_n_unique_states = 200;
    min_size = 70;
end

disp(horzcat('nsmall = ', num2str(nsmall)))
disp(horzcat('nmedium = ', num2str(nmedium)))
disp(horzcat('bof_branching = ', num2str(bof_branching)))
disp(horzcat('init_n_unique_states = ', num2str(init_n_unique_states)))
disp(horzcat('min_size = ', num2str(min_size)))

