

close all
clear
clc

working_dir = '.\Transfer\';

%% States
rootdir = '.\Data_2\';
filelist = dir(fullfile(rootdir, '**\*.png'));  %get list of files and folders in any subfolder
states = folders2labels(rootdir);
ustates = unique(states);
nstates = length(ustates);
disp(horzcat('nstates: ', num2str(nstates)))

%% Motors
nmotors = 2;
ntorques = 5; % Should be odd number
motor_combs = combinator(ntorques, nmotors,'p','r') - ((0.5 * ntorques) + 0.5);
motor_combs = motor_combs * 25;
nactions = size(motor_combs, 1);
disp(horzcat('nactions: ', num2str(nactions)))

%% Custom rewards
serials = dir(fullfile(rootdir, '**\*serial_data.mat'));  %get list of files and folders in any subfolder
torques = dir(fullfile(rootdir, '**\*torques.mat'));  %get list of files and folders in any subfolder

%% Markov
mdp = createMDP(nstates, nactions)
transition_counter = zeros(size(mdp.T));
reward_counter = zeros(size(mdp.R));

%% Get tuples
tuples = dir(strcat(working_dir, '*tuple.mat'));
ntuples = size(tuples, 1);
rl_data = zeros(ntuples, 4);
state_data = zeros(ntuples, nsensors * nfeatures);
motor_data = zeros(ntuples, 2);
counter = 0;
missed_tuples = 0;
load working_rand_tuples_2.mat
% rand_tuples = randsample(ntuples, ntuples * 5, 1);
disp(horzcat('Processing ', num2str(length(rand_tuples)), ' tuples...'))
for ntuple = rand_tuples' % this will need to be prioritized

    counter = counter + 1;

    if ~rem(counter, round(length(rand_tuples)/20))
        disp(num2str(counter/length(rand_tuples)))
    end

    % Load data
    load(horzcat(working_dir, tuples(ntuple).name))

    % Get state
    state_vector = rl_tuple{1};
    if length(state_vector) == 20 
        state_vector([6:10, 16:20]) = [];
    end

    if length(rl_tuple{1}) == 10 || length(rl_tuple{1}) == 20

        state_data(ntuple, :) = state_vector;
        state_vector = padarray(state_vector, [0 1], 0, 'pre');
        state_vector = padarray(state_vector, [0 1], statemax, 'post');  % Change lone 1 to 50 to do vis_pref_vals  
        r = corr(state_vector', state_combs');
        [~, ind] = max(r);
        rl_state = ind;
    
        % Get action    
        motor_vector = rl_tuple{2};
        motor_vector(motor_vector > 250) = 250;
        motor_vector(motor_vector < -250) = -250;
        motor_data(ntuple, :) = motor_vector;
    
        motor_vector = padarray(motor_vector, [0 1], -250, 'pre');
        motor_vector = padarray(motor_vector, [0 1], 250, 'post');
        r = corr(motor_vector', motor_combs');
        [~, ind] = max(r);
        rl_action = ind;
    
        % Get reward
        rl_reward = rand;

        % Get state
        state_vector = rl_tuple{4};
        if length(state_vector) == 20   
            state_vector([6:10, 16:20]) = [];
        end     

        state_data(ntuple, :) = state_vector;
        state_vector = padarray(state_vector, [0 1], 0, 'pre');
        state_vector = padarray(state_vector, [0 1], statemax, 'post');  % Change lone 1 to 50 to do vis_pref_vals
        r = corr(state_vector', state_combs');
        [~, ind] = max(r);
        rl_next_state = ind;
    
        % Update MDP
        transition_counter(rl_state, rl_next_state, rl_action) = transition_counter(rl_state, rl_next_state, rl_action) + 1;
        reward_counter(rl_state, rl_next_state, rl_action) = reward_counter(rl_state, rl_next_state, rl_action) + rl_reward;
    
        % Store data
        rl_data(ntuple, 1) = rl_state;
        rl_data(ntuple, 2) = rl_action;
        rl_data(ntuple, 3) = rl_reward;
        rl_data(ntuple, 4) = rl_next_state;

    else
        missed_tuples = missed_tuples + 1;
    end
end

disp(horzcat('n_missed_tuples: ', num2str(missed_tuples)))
disp(horzcat('n_unique_states: ', num2str(length(unique(rl_data(:,1))))))
disp(horzcat('%: ', num2str(100*(length(unique(rl_data(:,1)))/nstates))))
disp(horzcat('total reward: ', num2str(sum(rl_data(:,3)))))


%% Plot mdp
figure(1)
clf
set(gcf, 'position', [100 50 1280 720], 'color', 'w')

subplot(3,1,1)
histogram(rl_data(:,1), 'binwidth', 2)
hold on
histogram(rl_data(rl_data(:,3) > 0,1), 'binwidth', 2)
set(gca, 'yscale', 'log')
title('States and Rewarded States')
xlabel('State')
ylabel('#')

subplot(3,1,2)
histogram(rl_data(:,2), 'binwidth', 1)
hold on
histogram(rl_data(rl_data(:,3) > 0,2), 'binwidth', 1)
set(gca, 'yscale', 'log')
title('Actions and Rewarded Actions')
xlabel('Action')
ylabel('#')

subplot(3,1,3)
plot(rl_data(:, 3))
axis tight
title('Rewards')
ylabel('Reward')
xlabel('Time')

export_fig(horzcat('agent_1_', num2str(date), '_mdp'), '-r150', '-jpg', '-nocrop')

transition_counter_save = transition_counter;
reward_counter_save = reward_counter;
transition_counter = transition_counter_save;

%% Build MDP
for ii_state = 1:nstates
    for naction = 1:nactions
        this_sum = sum(transition_counter(ii_state, :, naction));
        if this_sum
            transition_counter(ii_state, :, naction) = transition_counter(ii_state, :, naction) / this_sum;
        else
            transition_counter(ii_state, :, naction) = 1/nstates;
        end
    end
end
mdp.T = transition_counter;
reward_counter = reward_counter_save ./ transition_counter_save;
reward_counter(isnan(reward_counter)) = 0;
mdp.R = reward_counter;
env = rlMDPEnv(mdp);
% env.ResetFcn = @() ((0.5 * nactions) + 0.5);
env.ResetFcn = @() randsample(nstates, 1);
validateEnvironment(env)
obsInfo = getObservationInfo(env);
actInfo = getActionInfo(env);
qTable = rlTable(obsInfo, actInfo);
critic = rlQValueFunction(qTable,obsInfo,actInfo);

%% Shallow
agent_opt = rlQAgentOptions;
agent_opt.DiscountFactor = 0.99;
qOptions = rlOptimizerOptions;
% qOptions.LearnRate = 0.1;
agentOpts.CriticOptimizerOptions = qOptions;
agent = rlQAgent(critic, agent_opt);
training_opts = rlTrainingOptions;
training_opts.MaxEpisodes = 500;
training_opts.MaxStepsPerEpisode = 50;
training_opts.StopTrainingCriteria = "AverageReward";
training_opts.ScoreAveragingWindowLength = 5;
trainingStats_shallow = train(agent,env, training_opts);
figure(11)
clf
set(gcf, 'color', 'w')
scan_agent
ylim([0 1025])
title('Agent 1')
set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
export_fig(horzcat('agent_1_', num2str(date), '_net'), '-r150', '-jpg', '-nocrop')
save('agent_1', 'agent')


%% Deep
agent_opt = rlDQNAgentOptions;
agent_opt.DiscountFactor = 0.99;
% agent_opt.EpsilonGreedyExploration.Epsilon = 0.1;
% agent_opt.EpsilonGreedyExploration.EpsilonMin = 0.01;
% agent_opt.EpsilonGreedyExploration.EpsilonDecay = 0.005;
agent = rlDQNAgent(critic, agent_opt);
training_opts = rlTrainingOptions;
training_opts.MaxEpisodes = 500;
training_opts.MaxStepsPerEpisode = 50;
training_opts.StopTrainingCriteria = "AverageReward";
training_opts.ScoreAveragingWindowLength = 5;
training_opts.UseParallel = 1;
trainingStats_deep = train(agent, env, training_opts);
figure(12)
clf
set(gcf, 'color', 'w')
scan_agent
ylim([0 1025])
title('Agent 11')
set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
export_fig(horzcat('agent_11_', num2str(date), '_net'), '-r150', '-jpg', '-nocrop')
save('agent_11', 'agent')

