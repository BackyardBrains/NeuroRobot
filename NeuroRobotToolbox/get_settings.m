
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
xyo_l1 = 16;
xyo_l2 = 16;
xyo_l3 = 16;
xyo_l4 = 200;
xyo_l5 = 200;
xyo_minbatch = 256;
xyo_maxeps = 8;
xyo_drop = 2;

if nsettings
    settings_fname = horzcat(available_settings(nsettings).folder, '\', available_settings(nsettings).name);
    disp(horzcat('Loading settings: ', settings_fname))
    try
        raw_settings = readtable(settings_fname);
        nparams = size(raw_settings, 1);
        for nparam = 1:nparams
            expression = char(strcat(raw_settings{nparam, 2}, '=', num2str(raw_settings{nparam, 3}), ';'));
            eval(expression);
        end        
    catch
        disp('Cannot read settings')
    end
end
