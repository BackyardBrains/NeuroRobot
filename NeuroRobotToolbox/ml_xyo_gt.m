

% This script will facilitate ground truth-based MDP contruction for
% consistency analysis

close all
clear
clc

dataset_dir_name = 'C:\SpikerBot\Livingroom\';
nets_dir_name = strcat(userpath, '\Nets\');
state_net_name = 'xyoNet16';
action_net_name = 's17181920';

torque_dir = dir(fullfile(dataset_dir_name, '**\*torques.mat'));
ntorques = size(torque_dir, 1);
ext_dir = dir(fullfile(dataset_dir_name, '**\*ext_data.mat'));
nexts = size(ext_dir, 1);
image_ds = imageDatastore(fullfile(dataset_dir_name, '**\*large_frame_x.png'));

n_unique_states = 16;
n_unique_actions = 7;

if ntorques ~= nexts
    error('tuple size mismatch')
else
    ntuples = ntorques;
end
disp(horzcat('Processing ', num2str(ntuples), ' tuples'))


%%
settings_dir_name = strcat(userpath, '\Settings\');
available_settings = dir(strcat(settings_dir_name, 'settings.csv'));
settings_fname = horzcat(available_settings(1).folder, '\', available_settings(1).name);
disp(horzcat('Loading settings: ', settings_fname))
try
    raw_settings = readtable(settings_fname);
    nparams = size(raw_settings, 1);
    for nparam = 1:nparams
        expression = char(strcat(raw_settings{nparam, 2}, '=', num2str(raw_settings{nparam, 3}), ';'));
        eval(expression);
    end        
catch
    disp('Cannot read settings')
end


%%
thetas = zeros(ntuples, 1);
robot_xys = zeros(ntuples, 2);
this_msg = horzcat('Getting ', num2str(ntuples), ' xyos');
disp(horzcat(this_msg))
tx1.String = this_msg;

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

this_x = robot_xys(:,1);
this_y = robot_xys(:,2);

n1 = sum(this_x < 160 | this_x > 500);
ns = randsample(160:500, n1, 1);
this_x(this_x < 160 | this_x > 500) = ns;

n1 = sum(this_y < 100 | this_y > 400);
ns = randsample(100:400, n1, 1);
this_y(this_y < 100 | this_y > 400) = ns;

n1 = sum(thetas > 360);
ns = randsample(360, n1, 1);
thetas(thetas > 360) = ns;


%%
figure(1)
clf
set(gcf, 'color', 'w', 'position', [160 60 1164 716])

subplot(2,2,1)
plot(robot_xys(:,1), robot_xys(:,2))
hold on
plot(this_x, this_y)
axis([1 600 1 500])
title('Robot trajectory')

subplot(2,2,2)
histogram(this_x)
title('True X')
axis tight

subplot(2,2,3)
histogram(this_y)
title('True Y')
axis tight

subplot(2,2,4)
histogram(thetas)
title('True O')
axis tight


%%
states = zeros(ntuples, 1);
labels = cell(n_unique_states, 1);

medx = median(this_x);
medy = median(this_y);

prcx33 = prctile(this_x, 33);
prcy33 = prctile(this_y, 33);

prcx66 = prctile(this_x, 66);
prcy66 = prctile(this_y, 66);

for ntuple = 1:ntuples
    x1 = this_x(ntuple);
    y1 = this_y(ntuple);
    o1 = thetas(ntuple);
    [state, label] = ml_roast(x1, y1, o1, medx, medy);
    % [state, label] = ml_roast2(x1, y1, o1, prcx33, prcy33, prcx66, prcy66);
    states(ntuple) = state;
    labels{ntuple} = label;
    if states(ntuple) == 0
        error('fjonk')
    end
end

save(horzcat(nets_dir_name, state_net_name, '-states'), 'states')
save(strcat(nets_dir_name, state_net_name, '-labels'), 'labels')


%%
figure(17)
clf
set(gcf, 'position', [201 241 800 420], 'color', 'w')

histogram(states, 'binwidth', 0.4)
xlim([0 n_unique_states + 1])
title('States')


%% Examples
for nstate = 1:n_unique_states
    state_inds = find(states == nstate);
    these_inds = randsample(state_inds, 25);
    this_ds = subset(image_ds, these_inds);
    figure(10 + nstate)
    montage(this_ds)
    title(horzcat('State ', num2str(nstate)))
    set(gcf, 'position', [393 515 595 451], 'color', 'w')    
    saveas(gcf, strcat('state', num2str(nstate), '.jpg'))
end


%% Torques
this_msg = 'Getting torques...';
disp(horzcat(this_msg))

get_torques
save(horzcat(nets_dir_name, state_net_name, '-torque_data'), 'torque_data')

this_msg = 'states and torques ready';
disp(horzcat(this_msg))


%%
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

disp(horzcat('n unique actions: ', num2str(n_unique_actions)))
disp(horzcat('mode action: ', num2str(mode(actions))))
disp(horzcat('mode action torque: ',  num2str(round(mean(torque_data(actions == mode(actions), :), 1)))))

save(strcat(nets_dir_name, state_net_name, '-actions'), 'actions')


figure(3)
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


%%
tuples = zeros(ntuples, 3);
for ntuple = 6:ntuples - 1
    tuples(ntuple - 5, 1) = states(ntuple - 5);
    tuples(ntuple - 5, 2) = states(ntuple);
    tuples(ntuple - 5, 3) = actions(ntuple - 5);
end
ntuples = size(tuples, 1);
disp('Tuples assembled successfully')
save(strcat(nets_dir_name, state_net_name, '-tuples'), 'tuples')


%%
figure(4)
clf
set(gcf, 'position', [251 291 400 420], 'color', 'w')

histogram(actions, 'binwidth', 0.4)
title('Actions')

xlim([0 n_unique_actions + 1])
set(gca, 'xtick', 1:n_unique_actions)


%%
n_unique_actions = n_unique_actions - 2;

mdp = createMDP(n_unique_states, n_unique_actions);
transition_counter = zeros(size(mdp.T));
for ntuple = 1:ntuples

    this_state = tuples(ntuple, 1);
    this_next_state = tuples(ntuple, 2);
    this_action = tuples(ntuple, 3);
    if ~isnan(this_state) && ~isnan(this_next_state) && ~sum(this_action == [n_unique_actions + 1 n_unique_actions + 2])
        if this_state && this_next_state
            transition_counter(this_state, this_next_state, this_action) = transition_counter(this_state, this_next_state, this_action) + 1;
        end
    end
end

disp(horzcat('n transitions: ', num2str(sum(transition_counter(:)))))
transition_counter_save = transition_counter;


%% Normalize mdp
for ii_state = 1:n_unique_states
    for naction = 1:n_unique_actions
        this_sum = sum(transition_counter(ii_state, :, naction));
        if this_sum
            this_val = transition_counter(ii_state, :, naction) / this_sum;
        else
            % transition_counter(ii_state, :, naction) = 0;
            this_val = zeros(size(transition_counter(ii_state, :, naction)));
            flag = 0;
            disp('padding mdp')
            while ~flag
                if sum(this_val) < 1
                    this_state = randsample(n_unique_states, 1);
                    this_val(this_state) = this_val(this_state) + 0.001;
                else
                    flag = 1;
                end
            end
        end
        if naction == mode(actions)
            transition_counter(ii_state, :, naction) = 0;
            transition_counter(ii_state, ii_state, naction) = 1;
        else
            transition_counter(ii_state, :, naction) = this_val;
        end
    end
end

mdp.T = transition_counter;
save(strcat(nets_dir_name, state_net_name, '-mdp'), 'mdp')
disp('Ready to train decision network')

ml_visualize_mdp


%%
reward_states = [5 6 7 8];
reward_action = mode(actions);
disp(horzcat('reward action (mode) = ', num2str(reward_action)))
disp(horzcat('reward action torque: ',  num2str(round(mean(torque_data(actions == reward_action, :), 1)))))

reward_counter = zeros(size(mdp.R));
[i, j] = min(sum(motor_combs, 2));
bad_action = j;
reward_counter(:, :, bad_action) = -1;
if ~isempty(reward_states)
    reward_counter(:, reward_states, reward_action) = 5;
end
% if ~isempty(bad_states)
%     reward_counter(:, -bad_states, reward_action) = -1;
% end
mdp.R = reward_counter;
disp(horzcat('total reward: ', num2str(sum(reward_counter(:)))))
disp('Rewards ready')

env = rlMDPEnv(mdp);
validateEnvironment(env)
disp('Environment ready')


%% Unpack environment
obsInfo = getObservationInfo(env);
actInfo = getActionInfo(env);
qTable = rlTable(obsInfo, actInfo);
critic = rlQValueFunction(qTable,obsInfo,actInfo);

n_unique_states = size(obsInfo.Elements, 1);
n_unique_actions = size(actInfo.Elements, 1);


%% Train Agent 2
agent_opt = rlDQNAgentOptions;
agent_opt.DiscountFactor = ml_rl_d;
agent = rlDQNAgent(critic, agent_opt);
training_opts = rlTrainingOptions;
training_opts.MaxEpisodes = ml_rl_me;
training_opts.MaxStepsPerEpisode = ml_rl_mspe;
training_opts.StopTrainingValue = 1000000;
training_opts.StopTrainingCriteria = "AverageReward";
training_opts.ScoreAveragingWindowLength = ml_rl_me/50;
training_opts.UseParallel = 0;
if isdeployed
    this_str = 'none';
else
    this_str = 'training-progress';
end
training_opts.Plots = this_str;
training_opts.Verbose = 1;

trainingStats_deep = train(agent, env, training_opts);
save(horzcat(nets_dir_name, state_net_name, '---', action_net_name, '-ml'), 'agent')


%%
figure(4)
clf
hold on
scan_agent
title(horzcat(state_net_name, '-', action_net_name))
set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')



