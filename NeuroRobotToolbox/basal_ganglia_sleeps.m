

close all
clear
clc


%% Get states
load livingroom2_net

rootdir = '.\Data_1\Rec_2\';
folders = folders2labels(rootdir);
unique_states = unique(folders);
nstates = length(unique_states);

rootdir = '.\Data_2\';
% get_states
load(horzcat(rootdir, 'states.mat'))
nsteps = length(states);

% states = modefilt(states, [9 1]);

%% Get actions
torques_dir = dir(fullfile(rootdir, '**\*torques.mat'));

nmotors = 2;
ntorques = 2; % Should be odd number
motor_combs = combinator(ntorques, nmotors,'p','r') - ((0.5 * ntorques) + 0.5);
motor_combs = motor_combs * 500;

% motor_combs = [motor_combs(1:2,:); [0 0]; motor_combs(3:4,:)];

motor_combs = padarray(motor_combs, [0 1], rand * 0.001, 'pre');
motor_combs = padarray(motor_combs, [0 1], rand * 0.001, 'post');
nactions = size(motor_combs, 1);

state1_buffer = [];
state2_buffer = [];
action_buffer = [];
tuples = [];
moving = 0;
for nstep = 1:nsteps-1

    this_state = states(nstep);
    this_next_state = states(nstep + 1);

    torque_fname = horzcat(torques_dir(nstep).folder, '\', torques_dir(nstep).name);
    load(torque_fname)
    torques(torques > 250) = 250;
    torques(torques < -250) = -250;

    if sum(torques)
        moving = moving + 1;
        state1_buffer = [state1_buffer; this_state];
        action_buffer = [action_buffer; torques];
        state2_buffer = [state2_buffer; this_next_state];
    elseif moving
%         state1_buffer'
%         action_buffer'
%         state2_buffer'
        moving = 0;
        motor_vector = mean(action_buffer, 1);
        motor_vector = padarray(motor_vector, [0 1], rand * 0.001, 'pre');
        motor_vector = padarray(motor_vector, [0 1], rand * 0.001, 'post');
        r = corr(motor_vector', motor_combs');    
        [~, ind] = max(r);
        this_action = ind;
        tuples = [tuples; state1_buffer(1), this_action, state2_buffer(end)];
        state1_buffer = [];
        action_buffer = [];
        state2_buffer = [];
    end
end

ntuples = size(tuples, 1);

%% Get Markov Decision Process
mdp = createMDP(nstates, nactions);
transition_counter = zeros(size(mdp.T));
for ntuple = 1:ntuples

    this_state = tuples(ntuple, 1);
    this_action = tuples(ntuple, 2);
    this_next_state = tuples(ntuple, 3);
    if this_state && this_next_state
        transition_counter(this_state, this_next_state, this_action) = transition_counter(this_state, this_next_state, this_action) + 1;
    end
end

transition_counter_save = transition_counter;

%%
transition_counter = transition_counter_save;

for ii_state = 1:nstates
    for naction = 1:nactions
        this_sum = sum(transition_counter(ii_state, :, naction));
        if this_sum
            this_val = transition_counter(ii_state, :, naction) / this_sum;
        else
            this_val = zeros(size(transition_counter(ii_state, :, naction)));
            this_val(ii_state) = 0.5;
            flag = 0;
            while ~flag
                if sum(this_val) < 1
                    this_state = randsample(1:nstates, 1);
                    if this_state ~= ii_state
                        this_val(this_state) = 0.05;
                        disp('padded')
                    end
                else
                    flag = 1;
                end
            end
        end
        transition_counter(ii_state, :, naction) = this_val;
    end
end

mdp.T = transition_counter;
save('transition_counter', 'transition_counter')

%% Plot mdp
figure(1)
clf
set(gcf, 'position', [100 50 1280 720], 'color', 'w')

subplot(2,2,1)
histogram(tuples(:,1), 'binwidth', 1)
title('States (location and heading)')
xlabel('State')
ylabel('Count')

subplot(2,2,2)
histogram(tuples(:,2), 'binwidth', 0.2)
set(gca, 'xtick',0:1:nactions+1, 'xticklabel', 0:nactions+1)
title('Actions (torque combinations)')
xlabel('Action')
ylabel('#')

subplot(2,2,3)
imagesc(mean(transition_counter, 3))
title('Transitions')

% subplot(2,2,4)
% histogram(bufl)
% title('Movements per transition')

export_fig(horzcat('agent_5_', num2str(date), '_mdp'), '-r150', '-jpg', '-nocrop')


%% Get reward
reward_counter = zeros(size(mdp.R));
counter = 0;
for ntuple = 1:ntuples

    this_state = tuples(ntuple, 1);
    this_action = tuples(ntuple, 2);
    this_next_state = tuples(ntuple, 3);

%     goal_states = randsample(nstates,4);
    goal_states = 1:4;
    if sum(this_state == goal_states)
        this_reward = 1;
    else
        this_reward = 0;
    end
    
    reward_counter(this_state, this_next_state, this_action) = reward_counter(this_state, this_next_state, this_action) + this_reward;

end

reward_counter = reward_counter ./ transition_counter_save;
reward_counter(isnan(reward_counter)) = 0;
mdp.R = reward_counter;
save('reward_counter', 'reward_counter')

%%
% mdp.TerminalStates = 's1';
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
% agent_opt.DiscountFactor = 0.1;
qOptions = rlOptimizerOptions;
% qOptions.LearnRate = 0.1;
agentOpts.CriticOptimizerOptions = qOptions;
agent = rlQAgent(critic, agent_opt);
training_opts = rlTrainingOptions;
training_opts.MaxEpisodes = 500;
training_opts.MaxStepsPerEpisode = 100;
training_opts.StopTrainingValue = 500;
training_opts.StopTrainingCriteria = "AverageReward";
training_opts.ScoreAveragingWindowLength = 5;
trainingStats_shallow = train(agent,env, training_opts);
figure(11)
clf
set(gcf, 'color', 'w')
scan_agent
ylim([0 nstates + 1])
title('Agent xyz')
set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
export_fig(horzcat('agent_xyz', num2str(date), '_net'), '-r150', '-jpg', '-nocrop')
save('agent_xyz', 'agent')


% %% Deep
% agent_opt = rlDQNAgentOptions;
% agent_opt.DiscountFactor = 0.99;
% % agent_opt.EpsilonGreedyExploration.Epsilon = 0.1;
% % agent_opt.EpsilonGreedyExploration.EpsilonMin = 0.01;
% % agent_opt.EpsilonGreedyExploration.EpsilonDecay = 0.005;
% agent = rlDQNAgent(critic, agent_opt);
% training_opts = rlTrainingOptions;
% training_opts.MaxEpisodes = 500;
% training_opts.MaxStepsPerEpisode = 100;
% training_opts.StopTrainingValue = 500;
% training_opts.StopTrainingCriteria = "AverageReward";
% training_opts.ScoreAveragingWindowLength = 5;
% training_opts.UseParallel = 1;
% trainingStats_deep = train(agent, env, training_opts);
% figure(12)
% clf
% set(gcf, 'color', 'w')
% scan_agent
% ylim([0 nstates + 1])
% title('Agent xyz2')
% set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
% export_fig(horzcat('agent_xyz2', num2str(date), '_net'), '-r150', '-jpg', '-nocrop')
% save('agent_xyz2_a3', 'agent')

