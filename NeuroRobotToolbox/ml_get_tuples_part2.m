

%% Actions
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

tx7.String = horzcat('Clustering torques to into ', num2str(n_unique_actions), ' unique actions...');
drawnow

disp(horzcat('n unique actions: ', num2str(n_unique_actions)))
disp(horzcat('mode action: ', num2str(mode(actions))))
disp(horzcat('mode action torque: ',  num2str(round(mean(torque_data(actions == mode(actions), :), 1)))))

save(strcat(nets_dir_name, state_net_name, '-actions'), 'actions')

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


%% Get tuples
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
% tx7.String = 'tuples aquired successfully';
drawnow

figure(12)
clf
set(gcf, 'position', [201 241 1200 420], 'color', 'w')

subplot(1,3,1:2)
histogram(states)
title('States')
subplot(1,3,3)
histogram(actions)
title('Actions')


