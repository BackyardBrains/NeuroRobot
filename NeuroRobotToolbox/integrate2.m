
% close all
clear
clc

%% Ontology
classifier_dir_name = '.\Data_1\Rec_2\';
labels = folders2labels(classifier_dir_name);
unique_states = unique(labels);
n_unique_states = length(unique_states);

%% Tuples
tuples_dir_name = 'C:\Users\Christopher Harris\Dropbox (CNE)\Operant\';
image_dir = dir(fullfile(tuples_dir_name, '**\*.png'));
torque_dir = dir(fullfile(tuples_dir_name, '**\*torques.mat'));
serial_dir = dir(fullfile(tuples_dir_name, '**\*serial_data.mat'));
ntuples = size(torque_dir, 1);

%% States
load('states')
states = modefilt(states, [9 1]);

%% Torques
load('torque_data')

%% Distances
load('dists')

%% Actions
torque_vals = 2;
motor_combs = combinator(torque_vals, 2,'p','r') - ((0.5 * torque_vals) + 0.5);
motor_combs = motor_combs * 50;
motor_combs = [motor_combs(1:2,:); [0 0]; motor_combs(3:4,:)];
motor_combs = padarray(motor_combs, [0 1], rand * 0.00001, 'pre');
motor_combs = padarray(motor_combs, [0 1], rand * 0.00001, 'post');
n_unique_actions = size(motor_combs, 1);
% get_actions
load('actions')


%% 
state_buffer = [];
next_state_buffer = [];
torque_buffer = [];
action_buffer = [];
dist_buffer = [];
atuples = zeros(ntuples - 1, 3);
btuples = [];
btorques = [];
moving = 0;
moving_counter = [];
for ntuple = 1:ntuples - 1

    if ~rem(ntuple, round((ntuples-1)/10))
        disp(num2str(ntuple/(ntuples-1)))
    end

    this_state = states(ntuple);
    this_action = actions(ntuple);
    these_torques = torque_data(ntuple, :);
    this_next_state = states(ntuple + 1);
    this_dist = dists(ntuple);
    
    state_buffer = [state_buffer; this_state];
    next_state_buffer = [next_state_buffer; this_next_state];
    torque_buffer = [torque_buffer; these_torques];
    action_buffer = [action_buffer; this_action];
    dist_buffer = [dist_buffer; this_dist];

%     if sum(torques)
    if this_next_state ~= this_state
        moving = moving + 1;
    elseif moving
        moving_counter = [moving_counter moving];
        moving = 0;
        
        motor_vector = mean(torque_buffer(1:end-1, :), 1);
        motor_vector = padarray(motor_vector, [0 1], rand * 0.00001, 'pre');
        motor_vector = padarray(motor_vector, [0 1], rand * 0.00001, 'post');
        r = corr(motor_vector', motor_combs');  
        [~, this_action] = max(r);

        btuples = [btuples; state_buffer(1), next_state_buffer(end-1), this_action];
        btorques = [btorques; motor_vector];

        state_buffer = [];
        action_buffer = [];
        dist_buffer = [];
        torque_buffer = [];
        next_state_buffer = [];
    else
        state_buffer = [];
        action_buffer = [];
        torque_buffer = [];
        next_state_buffer = [];
        dist_buffer = [];
    end
    
    atuples(ntuple, 1) = this_state;
    atuples(ntuple, 2) = this_next_state;
    atuples(ntuple, 3) = this_action;

end


%% Get Markov Decision Process
% tuples = atuples;
tuples = btuples;
ntuples = size(tuples, 1);

mdp = createMDP(n_unique_states, n_unique_actions);
transition_counter = zeros(size(mdp.T));
for ntuple = 1:ntuples

    this_state = tuples(ntuple, 1);
    this_next_state = tuples(ntuple, 2);
    this_action = tuples(ntuple, 3);
    if this_state && this_next_state
        transition_counter(this_state, this_next_state, this_action) = transition_counter(this_state, this_next_state, this_action) + 1;
    end
end

disp(horzcat('n transitions: ', num2str(sum(transition_counter(:)))))
transition_counter_save = transition_counter;

for ii_state = 1:n_unique_states
    for naction = 1:n_unique_actions
        this_sum = sum(transition_counter(ii_state, :, naction));
        if this_sum
            this_val = transition_counter(ii_state, :, naction) / this_sum;
        else
            this_val = zeros(size(transition_counter(ii_state, :, naction)));
            flag = 0;
            while ~flag
                if sum(this_val) < 1
                    sum(this_val)
                    this_state = randsample(n_unique_states, 1);
                    this_val(this_state) = this_val(this_state) + 0.001;
                    disp('padded')
                else
                    flag = 1;
                end
            end
        end
        transition_counter(ii_state, :, naction) = this_val;
    end
end

mdp.T = transition_counter;

%% Plot mdp
figure(1)
clf
set(gcf, 'position', [100 50 1280 720], 'color', 'w')

subplot(2,2,1)
histogram(tuples(:,1), 'binwidth', 1)
title('States')
xlabel('State')
ylabel('States')

subplot(2,2,2)
histogram(tuples(:,3), 'binwidth', .25)
title('Actions')
xlabel('Action')
ylabel('Actions')

subplot(2,2,3)
imagesc(mean(transition_counter, 3), [0 0.5])
colorbar
title('Transitions')

subplot(2,2,4)
histogram(moving_counter)
set(gca, 'yscale', 'log')
title('Movements per sequence')
xlabel('Movements')
ylabel('Sequences')

export_fig(horzcat('mdp_', num2str(date)), '-r150', '-jpg', '-nocrop')

%% Get reward
reward_counter = zeros(size(mdp.R));
reward_counter = reward_counter - 1;
reward_counter(:,14,:) = 10;
mdp.R = reward_counter;
disp(horzcat('total reward: ', num2str(sum(reward_counter(:)))))
% mdp.TerminalStates = "s14";

%% Scramble MDP
rx = randperm(numel(mdp.T));
mt = reshape(mdp.T(rx), size(mdp.T));
mdp.T = mt;

%% Get env
env = rlMDPEnv(mdp);
% env.ResetFcn = @() 24;
validateEnvironment(env)
obsInfo = getObservationInfo(env);
actInfo = getActionInfo(env);
qTable = rlTable(obsInfo, actInfo);
critic = rlQValueFunction(qTable,obsInfo,actInfo);

%% Agent 1 (Q)
agent_opt = rlQAgentOptions;
qOptions = rlOptimizerOptions;
% qOptions.LearnRate = 0.1;
agentOpts.CriticOptimizerOptions = qOptions;
agent = rlQAgent(critic, agent_opt);
training_opts = rlTrainingOptions;
training_opts.MaxEpisodes = 500;
training_opts.MaxStepsPerEpisode = 100;
training_opts.StopTrainingValue = 1000;
training_opts.StopTrainingCriteria = "AverageReward";
training_opts.ScoreAveragingWindowLength = 5;
trainingStats_shallow = train(agent,env, training_opts);

%%
figure(11)
clf
set(gcf, 'color', 'w')
scan_agent
ylim([0 n_unique_states + 1])
title('Agent 1')
set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
export_fig(horzcat('agent1_', num2str(date), '_net'), '-r150', '-jpg', '-nocrop')
save('agent1_', 'agent')

% %% Agent 2 (Deep Q)
% agent_opt = rlDQNAgentOptions;
% agent_opt.DiscountFactor = 0.99;
% % agent_opt.EpsilonGreedyExploration.Epsilon = 0.1;
% % agent_opt.EpsilonGreedyExploration.EpsilonMin = 0.01;
% % agent_opt.EpsilonGreedyExploration.EpsilonDecay = 0.5;
% agent = rlDQNAgent(critic, agent_opt);
% training_opts = rlTrainingOptions;
% training_opts.MaxEpisodes = 100;
% training_opts.MaxStepsPerEpisode = 20;
% training_opts.StopTrainingValue = 500000;
% training_opts.StopTrainingCriteria = "AverageReward";
% training_opts.ScoreAveragingWindowLength = 5;
% training_opts.UseParallel = 1;
% trainingStats_deep = train(agent, env, training_opts);
% figure(12)
% clf
% set(gcf, 'color', 'w')
% scan_agent
% ylim([0 n_unique_states + 1])
% title('Agent 2')
% set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
% export_fig(horzcat('agent2_', num2str(date), '_net'), '-r150', '-jpg', '-nocrop')
% save('agent2', 'agent')

% %% Agent 3 (SARSA)
% critic = rlQValueFunction(qTable,obsInfo,actInfo);
% opt = rlSARSAAgentOptions
% agent = rlSARSAAgent(critic,opt)
% training_opts = rlTrainingOptions;
% training_opts.MaxEpisodes = 500;
% training_opts.MaxStepsPerEpisode = 100;
% training_opts.StopTrainingValue = 500000;
% training_opts.StopTrainingCriteria = "AverageReward";
% training_opts.ScoreAveragingWindowLength = 5;
% trainingStats_shallow = train(agent,env, training_opts);
% figure(11)
% clf
% set(gcf, 'color', 'w')
% scan_agent
% ylim([0 n_unique_states + 1])
% title('Agent 3 (sarsa) randomized tuples')
% set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
% export_fig(horzcat('agent3_rand_', num2str(date), '_net'), '-r150', '-jpg', '-nocrop')
% % save('agent3', 'agent')
% 
% 
% %% Agent 4 (custom)
% reinforcementLearningDesigner
% 
% figure(14)
% clf
% set(gcf, 'color', 'w')
% scan_agent
% ylim([0 n_unique_states + 1])
% title('Agent 4 (custom) randomized tuples')
% set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
% export_fig(horzcat('agent4_rand_', num2str(date), '_net'), '-r150', '-jpg', '-nocrop')
% % save('agent4', 'agent')


