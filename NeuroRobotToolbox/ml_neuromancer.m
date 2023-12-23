

clear

state_net_name = 'dixie_repeat';

rec_dir_name = '';
dataset_dir_name = 'C:\SpikerBot ML Datasets\';
nets_dir_name = strcat(userpath, '\Nets\');

agent_fname = horzcat(nets_dir_name, state_net_name, '2cups-ml');
load(agent_fname)

%%

get_images = 0;
ml_get_images
get_torques = 0;
ml_get_torques
get_combs = 0;
ml_get_combs

%%
nsteps = 100;
ntuples = 91264;
image_size = round([227 302] * 0.02);
nsmall = 100;

mode_action = mode(actions);

steps_per_sequence = 50;

%%
figure(2)
clf

mini_inds = randsample(1:(ntuples-steps_per_sequence), nsteps);
data = zeros(nsteps, 1);
for nstep = 1:nsteps
    this_ind = mini_inds(nstep);
    this_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
    this_im_small = imresize(this_im, image_size);
    this_im_g = rgb2gray(this_im_small);
    this_action = getAction(agent, this_im_g);
    this_action = cell2mat(this_action);
    data(nstep) = this_action;
    image(this_im)
    title(num2str(this_action))
    drawnow
    if this_action == mode_action
        pause
    end
end

%%
figure(3)
clf
plot(1:nsteps, repmat(mode_action, nsteps), 'linewidth', 2, 'color', [1 0.5 0])
hold on
plot(data, 'color', [0.2 0.7 0.2])
title('Actions taken')
