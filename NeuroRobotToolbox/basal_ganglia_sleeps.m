

close all
clear
clc

working_dir = '.\Transfer\';
% working_dir = '.\Experiences\Recording_10\';
regenerate_rewards = 1;
missed_tuples = 0;

%% States
nsensors = 2;
nfeatures = 5;
statemax = 1; % vis_pref_vals = 50, bag = 1
state_combs = combinator(2, nsensors * nfeatures,'p','r') - 1;
% state_combs = combinator(2, nsensors * nfeatures * 2,'p','r') - 1;
disp(horzcat('ndimensions per state: ', num2str(size(state_combs, 2))))

state_combs = padarray(state_combs, [0 1], 0, 'pre');
state_combs = padarray(state_combs, [0 1], statemax, 'post');
nstates = size(state_combs, 1);
disp(horzcat('nstates: ', num2str(nstates)))

%% Motors
nmotors = 2;
ntorques = 5; % Should be odd number
motor_combs = combinator(ntorques, nmotors,'p','r') - ((0.5 * ntorques) + 0.5);
motor_combs = padarray(motor_combs, [0 1], -floor(ntorques/2), 'pre');
motor_combs = padarray(motor_combs, [0 1], floor(ntorques/2), 'post');
nactions = size(motor_combs, 1);
disp(horzcat('nactions: ', num2str(nactions)))

%% Custom rewards
if regenerate_rewards
    serials = dir(strcat(working_dir, '*serial_data.mat'));
end

%% Markov
mdp = createMDP(nstates, nactions);
transition_counter = zeros(size(mdp.T));
reward_counter = zeros(size(mdp.R));

%% Get tuples
tuples = dir(strcat(working_dir, '*tuple.mat'));
ntuples = size(tuples, 1);
rl_data = zeros(ntuples, 4);
state_data = zeros(ntuples, nsensors * nfeatures);
motor_data = zeros(ntuples, 2);
counter = 0;
rand_tuples = randsample(ntuples, round(ntuples/3)); % this will need to be prioritized
% rand_tuples = randsample(ntuples, ntuples); % this will need to be prioritized
% rand_tuples = 1:ntuples;
disp(horzcat('Processing ', num2str(length(rand_tuples)), ' tuples...'))
for ntuple = rand_tuples' % this will need to be prioritized

    counter = counter + 1;

    if ~rem(counter, round(length(rand_tuples)/5))
        disp(num2str(counter/length(rand_tuples)))
    end

    % Load data
    load(horzcat(working_dir, tuples(ntuple).name))

    % Get state
    state_vector = rl_tuple{1};
    if length(state_vector) == 20 
            state_vector([6:10, 16:20]) = [];        
%         if ~rem(counter, 2)
%             state_vector([1:5, 11:15]) = [];
%             1
%         else        
%             state_vector([6:10, 16:20]) = [];
%             2
%         end
    end

    if length(rl_tuple{1}) == 10 || length(rl_tuple{1}) == 20
%     if length(rl_tuple{1}) == 10

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
        rl_reward = rl_tuple{3};

        % Get custom reward
        if regenerate_rewards
            load(horzcat(working_dir, serials(ntuple).name))
            this_distance = str2double(serial_data{3});
            rl_reward = this_distance / 4000;
        end

        % Get state
        state_vector = rl_tuple{4};
        if length(state_vector) == 20   
            state_vector([6:10, 16:20]) = [];
        end      
%         if length(rl_tuple{4}) == 20  
%             if ~rem(counter, 2)
%                 state_vector([1:5, 11:15]) = [];
%             else        
%                 state_vector([6:10, 16:20]) = [];
%             end
%         end        

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


%%
figure(1)
clf

subplot(3,1,1)
histogram(rl_data(:,1), 'binwidth', 5)
hold on
histogram(rl_data(rl_data(:,3) > 0,1), 'binwidth', 5)
set(gca, 'yscale', 'log')
title('States and Rewarded States')
xlabel('State')
ylabel('Count')

subplot(3,1,2)
histogram(rl_data(:,2), 'binwidth', 1)
hold on
histogram(rl_data(rl_data(:,3) > 0,2), 'binwidth', 1)
set(gca, 'yscale', 'log')
title('Actions and Rewarded Actions')
xlabel('Action')
ylabel('Count')

subplot(3,1,3)
histogram(rl_data(:, 3), 'binwidth', 0.01)
axis tight
title('Rewards')
ylabel('Count')
xlabel('Reward')

transition_counter_save = transition_counter;
reward_counter_save = reward_counter;

%% Build Markov process
transition_counter = transition_counter_save;
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

%% 
mdp.T = transition_counter;
reward_counter = reward_counter_save ./ transition_counter_save;
reward_counter(isnan(reward_counter)) = 0;
mdp.R = reward_counter;
env = rlMDPEnv(mdp);
env.ResetFcn = @() ((0.5 * nactions) + 0.5);
validateEnvironment(env)

obsInfo = getObservationInfo(env);
actInfo = getActionInfo(env);
qTable = rlTable(obsInfo, actInfo);

critic = rlQValueFunction(qTable,obsInfo,actInfo); % Learn rate

%% Shallow Q
agent_opt = rlQAgentOptions;
agent_opt.DiscountFactor = 0.1;
agent = rlQAgent(critic, agent_opt);
training_opts = rlTrainingOptions;
training_opts.MaxEpisodes = 1000;
training_opts.MaxStepsPerEpisode = 100;
training_opts.StopTrainingCriteria = "AverageReward";
training_opts.ScoreAveragingWindowLength = 10;
trainingStats_Shallow = train(agent,env, training_opts);
save('agent_5', 'agent')
figure(10)
clf
scan_agent
title('Agent 5')

%% Deep Q
agent_opt = rlDQNAgentOptions;
agent_opt.DiscountFactor = 0.1;
% agent_opt.EpsilonGreedyExploration.Epsilon = 0.01;
% agent_opt.EpsilonGreedyExploration.EpsilonMin = 0.001;
% agent_opt.EpsilonGreedyExploration.EpsilonDecay = 0.0005;
agent = rlDQNAgent(critic, agent_opt);
training_opts = rlTrainingOptions;
training_opts.MaxEpisodes = 1000;
training_opts.MaxStepsPerEpisode = 100;
training_opts.StopTrainingCriteria = "AverageReward";
training_opts.ScoreAveragingWindowLength = 10;
training_opts.UseParallel = true;
trainingStats_Deep = train(agent,env, training_opts);
save('agent_6', 'agent')
figure(10)
clf
scan_agent
title('Agent 6')
