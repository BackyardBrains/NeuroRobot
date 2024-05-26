

%% Get data
dataset_dir_name = 'C:\Livingroom\';
torque_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*torques.mat'));
ext_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*ext_data.mat'));
ntuples = size(ext_dir, 1);


%% Get objective XYOs
thetas = zeros(ntuples, 1);
robot_xys = zeros(ntuples, 2);
disp(horzcat('Getting ', num2str(ntuples), ' xyos'))
for ntuple = 1:ntuples
    if ~rem(ntuple, round(ntuples/10))
        disp(num2str(ntuple/ntuples))
    end
    ext_fname = horzcat(ext_dir(ntuple).folder, '\', ext_dir(ntuple).name);
    load(ext_fname)

    robot_xy = ext_data.robot_xy;
    rblob_xy = ext_data.rblob_xy;    
    gblob_xy = ext_data.gblob_xy;    

    x1 = rblob_xy(1);
    y1 = rblob_xy(2);
    x2 = gblob_xy(1);
    y2 = gblob_xy(2);

    robot_xys(ntuple, :) = robot_xy;

    sepx = x1-x2;
    sepy = y1-y2;

    theta = mod(atan2d(sepy,sepx),360); 
    thetas(ntuple) = theta;

end

allx = robot_xys(:,1);
ally = robot_xys(:,2);

xlim1 = prctile(allx, 5);
xlim2 = prctile(allx, 95);
n1 = sum(allx < xlim1 | allx > xlim2);
ns = randsample(xlim1:xlim2, n1, 1);
allx(allx < xlim1 | allx > xlim2) = ns;

ylim1 = prctile(ally, 5);
ylim2 = prctile(ally, 95);
n1 = sum(ally < ylim1 | ally > ylim2);
ns = randsample(ylim1:ylim2, n1, 1);
ally(ally < ylim1 | ally > ylim2) = ns;

xlims = round(linspace(xlim1, xlim2, 4));
ylims = round(linspace(ylim1, ylim2, 4));
disp(horzcat('xlims: ', num2str(xlims)))
disp(horzcat('ylims: ', num2str(ylims)))


%% Torques
torque_data = zeros(ntuples, 2);
disp(horzcat('Getting ', num2str(ntuples), ' torques'))
torques = zeros(2,1);

for ntuple = 1:ntuples

    if ~rem(ntuple, round(ntuples/10))
        disp(horzcat('done = ', num2str(round((100 * (ntuple/ntuples)))), '%'))
    end

    torque_fname = horzcat(torque_dir(ntuple).folder, '\', torque_dir(ntuple).name);
    
    raw_torques = load(torque_fname);
    torques(2) = raw_torques.torques(1); % torque flip 240525
    torques(1) = raw_torques.torques(2); % torque flip 240525

    torques(torques > 250) = 250;
    torques(torques < -250) = -250;

    torque_data(ntuple, :) = torques;
    
end


%% Actions
n_unique_actions = 10;

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
figure(71)
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
drawnow


%%
figure(72)
clf
set(gcf, 'position', [251 291 400 420], 'color', 'w')

h3 = histogram(actions, 'binwidth', 0.99);
title('Actions')

xlim([0 n_unique_actions + 1])
set(gca, 'xtick', 1:n_unique_actions)

disp(horzcat('n unique actions: ', num2str(n_unique_actions)))
disp(horzcat('mode action: ', num2str(mode(actions))))
disp(horzcat('mode action torque: ',  num2str(round(mean(torque_data(actions == mode(actions), :), 1)))))


%%
allx(acc_inds) = [];
ally(acc_inds) = [];
thetas(acc_inds) = [];


%%
figure(6)
clf

subplot(3,3,1)
h1 = histogram(allx);
hold on
for ii = 1:4
    plot([xlims(ii) xlims(ii)], [0 max(h1.Values)], 'linewidth', 2, 'color', 'k')
    plot([mean(xlims(2:3)) mean(xlims(2:3))], [0 max(h1.Values)], 'linewidth', 2, 'color', 'r')
end
title('True X')

subplot(3,3,2)
h2 = histogram(ally);
hold on
for ii = 1:4
    plot([ylims(ii) ylims(ii)], [0 max(h2.Values)], 'linewidth', 2, 'color', 'k')
    plot([mean(ylims(2:3)) mean(ylims(2:3))], [0 max(h2.Values)], 'linewidth', 2, 'color', 'r')
end
title('True Y')

subplot(3,3,3)
histogram(thetas)
title('True O')

