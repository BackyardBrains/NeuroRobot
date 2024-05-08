

%% Actions
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

try
figure(7)
clf
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
catch
end


%% Get tuples
load(horzcat(nets_dir_name, state_net_name, '-states'))
n_unique_states = length(unique(states));
disp(horzcat('n unique states: ', num2str(n_unique_states)))

tuples = zeros(ntuples, 3);
for ntuple = 6:ntuples - 1
    tuples(ntuple - 5, 1) = states(ntuple - 5);
    tuples(ntuple - 5, 2) = states(ntuple);
    tuples(ntuple - 5, 3) = actions(ntuple - 5);
end
ntuples = size(tuples, 1);
disp('Tuples assembled successfully')
save(strcat(nets_dir_name, state_net_name, '-tuples'), 'tuples')


%% Lucid sleep?
% basal_ganglia_lucid


%% Output
try
tx8.String = 'tuples aquired successfully';
drawnow
catch
end

figure(16)
clf
set(gcf, 'position', [251 291 400 420], 'color', 'w')

histogram(actions, 'binwidth', 0.4)
title('Actions')

xlim([0 n_unique_actions + 1])
set(gca, 'xtick', 1:n_unique_actions)
