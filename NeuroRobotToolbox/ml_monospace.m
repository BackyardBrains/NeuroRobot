


% state_net_name = 'livingroom-14k-2';
state_net_name = 'office-20k-3';
workspace_dir_name = 'C:\Users\chris\OneDrive\Documents\MATLAB\Workspace\';
nets_dir_name = 'C:\Users\chris\OneDrive\Documents\MATLAB\Nets\';
image_ds = imageDatastore(fullfile(strcat(workspace_dir_name, state_net_name), '**\*.png'));
n_unique_states = 22;
n_images_per_state = 50;
nexamples = 6;
n_unique_actions = 10;

% livingroom-14k-2
bookshelf = [1 2 8 14 17];
corner1 = [18 20];
sofa = [6 16];
corner2 = [12 13];
window = [5 7];
redwall = [3 9 11];
xforward = [2 4];
xright = [3 6];
xleft = [7 8];
xbackward = 5;

% office-20k-3
station1 = 16;
corner1 = 8;
windows = [4 5 10];
corner2 = [6 13 21];
door = [10 15 20];
corner3 = 17;
room = [2 7 14];
winwall = [1 3 12 18 19 22];
xleft = [1 8];
xforward = [2 4];
xbackward = 6;
xright = [7 10];

load(strcat(nets_dir_name, state_net_name, '-states'))
load(strcat(nets_dir_name, state_net_name, '-torque_data'))
load(strcat(nets_dir_name, state_net_name, '-actions'))
load(strcat(nets_dir_name, state_net_name, '-mdp'))
ntuples = size(torque_data, 1);
disp(horzcat('loaded ntuples: ', num2str(ntuples)))

ml_promontage
ml_visualize_mdp
ml_get_combs_quick
ml_actioncloud


%%
s1 = door;
a = xleft;

v = mean(mdp.T(s1,:,a), [1 3]);

figure(1)
clf
xinds = 1:n_unique_states;
xinds(s1) = [];
v1 = v;
v1(xinds) = 0;
bar(v1)
hold on
xinds = 1:n_unique_states;
v(s1) = 0;
bar(v)

