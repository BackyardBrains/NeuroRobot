
%% Get speed
if ml_speed_select.Value == 1 % Slow
    learn_speed = 2;
elseif ml_speed_select.Value == 2 % Medium
    learn_speed = 0.5;
elseif ml_speed_select.Value == 3 % Fast
    learn_speed = 0.1;    
end

%% Load
axes(ml_load_status)
cla
txx = text(0.03, 0.5, 'Loading...');
drawnow

net_name = 'windowArenaNet';

try
    openfig(strcat(nets_dir_name, net_name, '-examples.fig'))
    load(strcat(nets_dir_name, net_name, '-torque_data'))
    load(strcat(nets_dir_name, net_name, '-actions'))
    load(strcat(nets_dir_name, net_name, '-mdp'))
catch
    ml_load_button.BackgroundColor = [1 0 0];
    pause(0.5)
    ml_load_button.BackgroundColor = [0.94 0.94 0.94];
    error('Cannot find prepared training data')
end

txx.String = 'Ready to train decision network';

