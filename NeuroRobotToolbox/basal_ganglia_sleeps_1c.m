

close all
clear
clc

working_dir = '.\Experiences\Recording_17\';
% gTruth = groundTruth(dataSource,labelDefs,labelData)
ims = imageDatastore('.\Experiences\Recording_17\*.png');
n = length(ims.Files);
frames = readall(ims);

% working_dir = '.\Transfer\';
nsensors = 2;
nfeatures = 5;
nstates = 1024;
nactions = 25;

load C.mat
serials = dir(strcat(working_dir, '*serial_data.mat'));
tuples = dir(strcat(working_dir, '*tuple.mat'));
ntuples = size(tuples, 1);
state_data = zeros(ntuples, nsensors * nfeatures);
state_data2 = zeros(ntuples, 2);
motor_data = zeros(ntuples, 2);
exp_data = zeros(ntuples, 4);
mdp = createMDP(nstates, nactions);
transition_counter = zeros(size(mdp.T));
reward_counter = zeros(size(mdp.R));

counter = 0;
missed_tuples = 0;
for ntuple = 1:ntuples

    counter = counter + 1;

    if ~rem(counter, round(ntuples/20))
        disp(num2str(counter/(ntuples/2)))
    end

    % Load data
    load(horzcat(working_dir, tuples(ntuple).name))

    % Get reward
    load(horzcat(working_dir, serials(ntuple).name))
    this_distance = str2double(serial_data{3});
    this_distance(this_distance >= 4000) = 0;                
    if this_distance
        rl_reward = 1/this_distance;
    else
        rl_reward = 0;
    end

    % Get state
    state_vector = rl_tuple{1};
    if length(state_vector) == 20 
        state_vector([6:10, 16:20]) = [];
    end

    if (length(rl_tuple{1}) == 10 || length(rl_tuple{1}) == 20)

        state_data(ntuple, :) = state_vector;
        [i, j] = max(corr(state_vector', C'));
        
        rl_state = j; % temp
    
        motor_vector = rl_tuple{2};
        motor_vector(motor_vector > 250) = 250;
        motor_vector(motor_vector < -250) = -250;
        motor_data(ntuple, :) = motor_vector;
        rl_action = randsample(nactions, 1); % temp
    
        % Get reward
        load(horzcat(working_dir, serials(ntuple).name))
        this_distance = str2double(serial_data{3});
        this_distance(this_distance >= 4000) = 0;                
        if this_distance
            rl_reward = 1/this_distance;
        else
            rl_reward = 0;
        end

        state_vector = rl_tuple{4};
        if length(state_vector) == 20   
            state_vector([6:10, 16:20]) = [];
        end     

        state_data(ntuple, :) = state_vector;
        rl_next_state = randsample(nstates, 1);
    
        transition_counter(rl_state, rl_next_state, rl_action) = transition_counter(rl_state, rl_next_state, rl_action) + 1;
        reward_counter(rl_state, rl_next_state, rl_action) = reward_counter(rl_state, rl_next_state, rl_action) + rl_reward;
    
        exp_data(ntuple, 1) = rl_state;
        exp_data(ntuple, 2) = rl_action;
        exp_data(ntuple, 3) = rl_reward;
        exp_data(ntuple, 4) = rl_next_state;

    else
        missed_tuples = missed_tuples + 1;
    end
end

% frames{state_data(:,1) == 0} = [];
% state_data(state_data(:,1) == 0, :) = [];
% motor_data(motor_data(:,1) == 0, :) = [];
% exp_data(exp_data(:,1) == 0, :) = [];
nframes = length(frames);

disp(horzcat('n_missed_tuples: ', num2str(missed_tuples)))
disp(horzcat('n_unique_states: ', num2str(length(unique(exp_data(:,1))))))
% disp(horzcat('%: ', num2str(100*(length(unique(exp_data(:,1)))/nstates))))
disp(horzcat('total reward: ', num2str(sum(exp_data(:,3)))))

%%
[idx, C] = kmeans(state_data, 100);
figure(1)
clf
imagesc(C)
xlabel('Feature vector')
ylabel('K-Cluster')
save('C', 'C')

%%
figure(1)
clf
histogram(exp_data(:,1), 'binwidth', 1)
set(gca, 'yscale', 'log')

%%
unique_states = unique(exp_data(:,1));
for ii = unique_states'
    these_frames = exp_data(:,1) == ii;
    if sum(these_frames) > 5
        figure(ii)
        montage({frames{these_frames}})
        title(horzcat('State: ', num2str(ii)))
        pause
    end
end



%% Plot mdp
figure(1)
clf
set(gcf, 'position', [100 50 1280 720], 'color', 'w')

subplot(3,1,1)
histogram(exp_data(:,1), 'binwidth', 2)
hold on
histogram(exp_data(exp_data(:,3) > 0,1), 'binwidth', 2)
set(gca, 'yscale', 'log')
title('States and Rewarded States')
xlabel('State')
ylabel('#')

subplot(3,1,2)
histogram(exp_data(:,2), 'binwidth', 1)
hold on
histogram(exp_data(exp_data(:,3) > 0,2), 'binwidth', 1)
set(gca, 'yscale', 'log')
title('Actions and Rewarded Actions')
xlabel('Action')
ylabel('#')

subplot(3,1,3)
plot(exp_data(:, 3))
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

