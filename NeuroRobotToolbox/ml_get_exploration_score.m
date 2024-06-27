
clear


%%

% dataset_dir_name = strcat(userpath, '\Datasets\');
dataset_dir_name = 'C:\SpikerBot\LivingroomArena\';
nets_dir_name = strcat(userpath, '\Nets\');
state_net_name = 'LivingroomArenaNet';

rec_dir_name = '';

image_dir = imageDatastore(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*large_frame_x.png'));
ext_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*ext_data.mat'));

ntuples = size(ext_dir, 1);

% nrec = str2double(rec_dir_name(4));

ml_get_objective_xyo


%%
x_raw = robot_xys(:,1);
y_raw = robot_xys(:,2);
o_raw = thetas;

figure(1)
clf
plot(x_raw, y_raw)
xlim([1 700])
ylim([1 500])

% xyo = [x_raw y_raw o_raw];
% save(horzcat('xyo', num2str(nrec), '.mat'), 'xyo')


%%
load(strcat(nets_dir_name, state_net_name, '-ml'))
load(strcat(nets_dir_name, state_net_name, '-labels'))
n_unique_states = length(labels);

ntuples = 4000;
data = zeros(ntuples, 1);
for ntuple = 1:ntuples
    if ~rem(ntuple, round(ntuples/20))
        disp(horzcat('Processing image ', num2str(ntuple), ' of ', num2str(ntuples), ' (nrec ', num2str(nrec), ')'))
    end 
    this_im = imread(image_dir.Files{ntuple});
    [this_state, this_score] = classify(net, this_im);
    this_state = find(labels == this_state);
    data(ntuple) = this_state;
end

% save(horzcat('data', num2str(nrec)), 'data')

% %%
% nsteps = 1000;
% start_tuple = randsample(ntuples-nsteps, 1);
% data = zeros(nsteps, 1);
% these_tuples = start_tuple : start_tuple + nsteps - 1;
% counter = 0;
% for ntuple = these_tuples
%     counter = counter + 1;
%     if ~rem(counter, round(nsteps/20))
%         disp(horzcat('Processing image ', num2str(counter), ' of ', num2str(nsteps)))
%     end    
%     this_im = imread(image_dir.Files{ntuple});
%     [this_state, this_score] = classify(net, this_im);
%     this_state = find(labels == this_state);
%     data(counter) = this_state;
% end
% disp('Inference complete')


%%
fig_pos = [71 71 932 552];

fig1 = figure(1);
clf
set(gcf, 'position', fig_pos, 'color', 'w')

h = histogram(data, 'binwidth', 1, 'binlimits', [0.9 n_unique_states + 1.1]);
y = h.Values;
y = y - min(y);
coverage = sum(y > 0) / n_unique_states;
redundancy = mean(y(y > 0)) / sum(y > 0);
disp(horzcat('Rec ', num2str(nrec), ', Coverage: ', num2str(coverage), ...
    ', redundancy: ', num2str(redundancy)))

set(gca, 'xtick', 1:n_unique_states)
title(horzcat('Brain ', num2str(nrec)))
xlabel('State')
ylabel('Count')