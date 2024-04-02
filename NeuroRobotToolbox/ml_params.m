
%% Get vals

if ml_speed_select.Value == 1 % Fast
    nsmall = 10000;
    bof_branching = 500;
    nmedium = 10000;
    init_n_unique_states = 900;
    min_size = 30;
elseif ml_speed_select.Value == 2 % Medium
    nsmall = 10000;
    bof_branching = 500;
    nmedium = 20000;
    init_n_unique_states = 900;
    min_size = 30;
elseif ml_speed_select.Value == 3 % Slow
    nsmall = 10000;
    bof_branching = 500;
    nmedium = 40000;
    init_n_unique_states = 900;
    min_size = 30;
end

disp(horzcat('nsmall = ', num2str(nsmall)))
disp(horzcat('nmedium = ', num2str(nmedium)))
disp(horzcat('bof_branching = ', num2str(bof_branching)))
disp(horzcat('init_n_unique_states = ', num2str(init_n_unique_states)))
disp(horzcat('min_size = ', num2str(min_size)))

