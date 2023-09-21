
axes(ml_out2)
cla
txx = text(0.03, 0.5, 'Loading...');
drawnow

net_name = 'statenet';

load(strcat(nets_dir_name, net_name, '-net-ml'))
load(strcat(nets_dir_name, net_name, '-labels'))
load(horzcat(nets_dir_name, net_name, '-states'))
load(horzcat(nets_dir_name, net_name, '-torque_data'))
load(strcat(nets_dir_name, net_name, '-actions'))
load(strcat(nets_dir_name, net_name, '-mdp'))

load(strcat(nets_dir_name, net_name, '-examples.fig'))

txx.String = 'Done';