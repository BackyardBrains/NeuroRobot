
nsmall = 5000;
nmedium = 5000;
init_n_unique_states = 300;
min_size = 30;
trim_size = 20;
redo_state_clustering = 0;
ml_l1 = 32;
ml_l2 = 32;
ml_l3 = 16;
ml_bs = 64;
ml_me = 10;
n_unique_actions = 10;
redo_action_clustering = 0;
ml_rl_d = 0.95;
ml_rl_me = 2000;
ml_rl_mspe = 100;

if nsettings
    settings_fname = horzcat(available_settings(nsettings).folder, '\', available_settings(nsettings).name);
    disp(horzcat('Loading settings: ', settings_fname))
    try
        raw_settings = readtable(settings_fname);
        nparams = size(raw_settings, 1);
        for nparam = 1:nparams
            expression = char(strcat(raw_settings{nparam, 2}, '=', num2str(raw_settings{nparam, 3})));
            eval(expression);
        end
    catch
        disp('Cannot read settings')
    end
end

disp(horzcat('nsmall = ', num2str(nsmall)))
disp(horzcat('nmedium = ', num2str(nmedium)))
disp(horzcat('init n unique states = ', num2str(init_n_unique_states)))
disp(horzcat('min size = ', num2str(min_size)))
disp(horzcat('trim size = ', num2str(trim_size)))
disp(horzcat('redo state clustering = ', num2str(redo_state_clustering)))
disp(horzcat('redo_action_clustering = ', num2str(ml_l1)))
disp(horzcat('ml_l2 = ', num2str(ml_l2)))
disp(horzcat('ml_l3 = ', num2str(ml_l3)))
disp(horzcat('ml_bs = ', num2str(ml_bs)))
disp(horzcat('ml_me = ', num2str(ml_me)))
disp(horzcat('n_unique_actions = ', num2str(n_unique_actions)))
disp(horzcat('redo action clustering = ', num2str(redo_action_clustering)))
disp(horzcat('ml_rl_d = ', num2str(ml_rl_d)))
disp(horzcat('ml_rl_me = ', num2str(ml_rl_me)))
disp(horzcat('ml_rl_mspe = ', num2str(ml_rl_mspe)))

