

axes(olearn_late_load_status_ax)
cla
txx = text(0.03, 0.5, 'Loading...');
drawnow

% load(strcat(nets_dir_name, net_name, '-ml'))
% load(strcat(nets_dir_name, net_name, '-labels'))

% openfig(strcat(nets_dir_name, net_name, '-examples.fig'))

load(horzcat(nets_dir_name, net_name, '-states'))
load(horzcat(nets_dir_name, net_name, '-torque_data'))
load(strcat(nets_dir_name, net_name, '-actions'))

load(strcat(nets_dir_name, net_name, '-mdp'))


txx.String = 'Done';

