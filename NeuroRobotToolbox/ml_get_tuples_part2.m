

%% Actions
n_unique_actions = 10;

load(horzcat(nets_dir_name, state_net_name, '-torque_data'))
ntuples = size(torque_data, 1);

actions = kmeans(torque_data, n_unique_actions);
motor_combs = zeros(n_unique_actions, 2);
counter = 0;
while ~(sum(sum(motor_combs, 2) < 0) == 1) && counter < 5
    counter = counter + 1;
    actions = kmeans(torque_data, n_unique_actions);
    for naction = 1:n_unique_actions
        motor_combs(naction, :) = mean(torque_data(actions == naction, :));
    end
end

figure(16)
clf
set(gcf, 'position', [251 291 400 420], 'color', 'w')

h3 = histogram(actions, 'binwidth', 0.99);
title('Actions')

xlim([0 n_unique_actions + 1])
set(gca, 'xtick', 1:n_unique_actions)

[~, main_actions] = sort(h3.Values, 'descend');

accidental_actions = main_actions(6:10);
acc_inds = sum(actions == accidental_actions, 2) > 0;
torque_data(acc_inds, :) = [];


%%
n_unique_actions = 5;
actions = kmeans(torque_data, n_unique_actions);
motor_combs = zeros(n_unique_actions, 2);
counter = 0;
while ~(sum(sum(motor_combs, 2) < 0) == 1) && counter < 5
    counter = counter + 1;
    actions = kmeans(torque_data, n_unique_actions);
    for naction = 1:n_unique_actions
        motor_combs(naction, :) = mean(torque_data(actions == naction, :));
    end
end


%%
try
axes(im_ax1)
cla
gscatter(torque_data(:,1)+randn(size(torque_data(:,1)))*4, torque_data(:,2)+randn(size(torque_data(:,2)))*4, actions, [],[],[], 'off')
hold on
for naction = 1:n_unique_actions
    text(motor_combs(naction,1), motor_combs(naction,2), num2str(naction), 'fontsize', 16, 'fontweight', 'bold');
end
axis padded
set(gca, 'yscale', 'linear')
title('Actions')
xlabel('Left Motor')
ylabel('Right Motor')
drawnow
catch
end


%%
figure(16)
clf
set(gcf, 'position', [251 291 400 420], 'color', 'w')

h3 = histogram(actions, 'binwidth', 0.99);
title('Actions')

xlim([0 n_unique_actions + 1])
set(gca, 'xtick', 1:n_unique_actions)


try
axes(ml_train4_status)
cla
tx8 = text(0.03, 0.5, horzcat('Clustering torques to into ', num2str(n_unique_actions), ' unique actions...'), 'FontSize', bfsize + 4);
drawnow
catch
end

disp(horzcat('n unique actions: ', num2str(n_unique_actions)))
disp(horzcat('mode action: ', num2str(mode(actions))))
disp(horzcat('mode action torque: ',  num2str(round(mean(torque_data(actions == mode(actions), :), 1)))))

save(strcat(nets_dir_name, state_net_name, '-actions'), 'actions')


%% Get tuples
load(horzcat(nets_dir_name, state_net_name, '-states'))
states(acc_inds) = [];
ntuples = length(states);
n_unique_states = length(unique(states));
disp(horzcat('n unique states: ', num2str(n_unique_states)))

tuples = zeros(ntuples, 3);
for ntuple = 6:ntuples - 1
    tuples(ntuple - 5, 1) = states(ntuple - 5);
    tuples(ntuple - 5, 2) = states(ntuple);
    tuples(ntuple - 5, 3) = actions(ntuple - 5);
end


%%
disp(horzcat(num2str(ntuples), ' tuples assembled successfully'))
save(strcat(nets_dir_name, state_net_name, '-tuples'), 'tuples')


%% Lucid sleep?
% basal_ganglia_lucid


%%
figure(26)
clf
set(gcf, 'position', [251 291 400 420], 'color', 'w')

h3 = histogram(tuples(:,3), 'binwidth', 0.99);
title('Actions')

xlim([0.5 n_unique_actions + 1.5])
set(gca, 'xtick', 1:n_unique_actions)

