

%%
torque_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*torques.mat'));

ntorques = size(torque_dir, 1);
ntuples = ntorques;
disp(horzcat('ntuples: ', num2str(ntuples)))

get_torques


%%
n_unique_actions = 7;

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

figure(4)
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


%% Get tuples
tuples = zeros(ntuples, 3);
for ntuple = 6:ntuples - 1
    tuples(ntuple - 5, 1) = states(ntuple - 5);
    tuples(ntuple - 5, 2) = states(ntuple);
    tuples(ntuple - 5, 3) = actions(ntuple - 5);
end
ntuples = size(tuples, 1);
disp('Tuples assembled successfully')


%% Lucid sleep?
% basal_ganglia_lucid


%% Output
% tx7.String = 'tuples aquired successfully';
drawnow

figure(12)
clf
set(gcf, 'position', [201 241 1200 420], 'color', 'w')

subplot(1,3,1:2)
histogram(states, 'binwidth', 0.4)
xlim([0 n_unique_states + 1])
title('States')
subplot(1,3,3)
histogram(actions, 'binwidth', 0.4)
xlim([0 n_unique_actions + 1])
set(gca, 'xtick', 1:n_unique_actions)
title('Actions')


%% Get xyoMDP
n_unique_actions = 5;
mdp = createMDP(n_unique_states, n_unique_actions);
transition_counter = zeros(size(mdp.T));
for ntuple = 1:ntuples

    this_state = tuples(ntuple, 1);
    this_next_state = tuples(ntuple, 2);
    this_action = tuples(ntuple, 3);
    if ~isnan(this_state) && ~isnan(this_next_state) && ~sum(this_action == [6 7])
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
        transition_counter(ii_state, :, naction) = this_val;
    end
end

mdp.T = transition_counter;
disp('Ready to train decision network')


ml_visualize_mdp


%% Set rewards
list_of_states = 5;
reward_states = list_of_states(sign(list_of_states) == 1);
bad_states = [];

reward_action = mode(actions);
disp(horzcat('reward action (mode) = ', num2str(reward_action)))
disp(horzcat('reward action torque: ',  num2str(round(mean(torque_data(actions == reward_action, :), 1)))))

bad_action = [];

% bad_action = find(sum(motor_combs, 2) < 0);
% disp(horzcat('bad action (backward) = ', num2str(bad_action)))
% disp(horzcat('bad action torque: ',  num2str(round(mean(torque_data(actions == bad_action, :), 1)))))

reward_counter = zeros(size(mdp.R));
reward_counter(:, :, bad_action) = -1;
if ~isempty(reward_states)
    reward_counter(:, reward_states, reward_action) = 5;
end
if ~isempty(bad_states)
    reward_counter(:, -bad_states, reward_action) = -1;
end
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
% save(horzcat(nets_dir_name, state_net_name, '---', action_net_name, '-ml'), 'agent')


%% Show Agent
try
axes(im_ax1)
cla

hold on
scan_agent
title(horzcat(state_net_name, '-', action_net_name))
set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')

tx10.String = horzcat('Finished training agent net');
drawnow
catch
end

disp('Finished training agent net')