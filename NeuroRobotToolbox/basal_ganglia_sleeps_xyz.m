

close all
clear
clc

load('rl_net.mat')

rootdir = '.\Data_1\';
filelist = dir(fullfile(rootdir, '**\*.png'));  %get list of files and folders in any subfolder
folders = folders2labels(rootdir);
states = unique(folders);

%% States
rootdir = '.\Data_2\';
images_dir = dir(fullfile(rootdir, '**\*.png'));  %get list of files and folders in any subfolder
nimages = size(images_dir,1);
nstates = 60;
disp(horzcat('nstates: ', num2str(nstates)))

%% Motors
% nmotors = 2;
% ntorques = 7; % Should be odd number
% motor_combs = combinator(ntorques, nmotors,'p','r') - ((0.5 * ntorques) + 0.5);
% motor_combs = padarray(motor_combs, [0 1], -floor(ntorques/2), 'pre');
% motor_combs = padarray(motor_combs, [0 1], floor(ntorques/2), 'post');
% nactions = size(motor_combs, 1);
nactions = 5;
disp(horzcat('nactions: ', num2str(nactions)))

%% Custom rewards
serials_dir = dir(fullfile(rootdir, '**\*serial_data.mat'));  %get list of files and folders in any subfolder
torques_dir = dir(fullfile(rootdir, '**\*torques.mat'));  %get list of files and folders in any subfolder
nserials = size(serials_dir, 1);
ntorques = size(torques_dir, 1);

%% Markov
mdp = createMDP(nstates, nactions);
transition_counter = zeros(size(mdp.T));
reward_counter = zeros(size(mdp.R));

%% Get tuples
rl_data = nan(nserials, 4);
missed_tuples = 0;
counter = 0;
load rand_tuples.mat
rand_tuples = randsample(nserials-1, round(nserials * 3), 1);
disp(horzcat('Processing ', num2str(length(rand_tuples)), ' tuples...'))
for ntuple = rand_tuples' % this will need to be prioritized
% for counter = 1:nserials-1

    counter = counter + 1;
    if ~rem(counter, round(length(rand_tuples)/100))
        disp(num2str(counter/length(rand_tuples)))
    end

    torque_fname = horzcat(torques_dir(ntuple).folder, '\', torques_dir(ntuple).name);
    load(torque_fname)
    torques(torques > 250) = 250;
    torques(torques < -250) = -250;

%     motor_vector = torques;
%     motor_vector = padarray(motor_vector, [0 1], -250, 'pre');
%     motor_vector = padarray(motor_vector, [0 1], 250, 'post');
%     r = corr(motor_vector', motor_combs');
%     [~, ind] = max(r);
%     rl_action = ind;

    if torques(1) > 0 && torques(2) > 0
        rl_action = 1;
    elseif torques(1) > torques(2)
        rl_action = 2;
    elseif torques(1) < torques(2)
        rl_action = 3;
    elseif torques(1) == 0  && torques(2) == 0
        rl_action = 4;
    elseif torques(1) < 0  && torques(2) < 0
        rl_action = 5;
    else
        error('unrecognized action')
    end

    serial_fname = horzcat(serials_dir(ntuple).folder, '\', serials_dir(ntuple).name);
    load(serial_fname)
    this_distance = str2double(serial_data{3});
    this_distance(this_distance >= 4000) = 0;    
    if this_distance
        rl_reward = 1/this_distance;
    else
        rl_reward = 0;
    end

    ix1 = [];
    ix2 = [];
    iy1 = [];
    iy2 = [];
    rl_state = [];
    rl_next_state = [];
    for ii = 1:2
        ii2 = ntuple*2-(ii-1);
        this_im = imread(strcat(images_dir(ii2).folder, '\',  images_dir(ii2).name));
        this_im = imresize(this_im, 'outputsize', [50 50]);
        state = classify(net, this_im);
        
        if ii == 1
            ix1 = find(states == state);
        elseif ii == 2
            ix2 = find(states == state);
        end
        
        if ix1 == ix2
            rl_state = ix1;
%             disp('binocular match!')
        elseif ~isempty(ix1)
            rl_state = ix1;
        elseif ~isempty(ix2)
            rl_state = ix2;
        else
            error('something wrong')
        end

        ii3 = (ntuple+1)*2-(ii-1);
        this_im = imread(strcat(images_dir(ii3).folder, '\',  images_dir(ii3).name));
        this_im = imresize(this_im, 'outputsize', [50 50]);
        next_state = classify(net, this_im);

        if ii == 1
            iy1 = find(states == next_state);
        elseif ii == 2
            iy2 = find(states == next_state);
        end
        
        if iy1 == iy2
            rl_next_state = iy1;
%             disp('binocular match!')
        elseif ~isempty(iy1)
            rl_next_state = iy1;
        elseif ~isempty(iy2)
            rl_next_state = iy2;
        else
            error('something wrong')
        end

    end

%     this_noise = 0.1;
%     if rand < this_noise
%         rl_state = randsample(nstates, 1);
%     end
%     if rand < this_noise
%         rl_action = randsample(nactions, 1);
%     end
%     if rand < this_noise
%         rl_reward = rand;
%     end
%     if rand < this_noise
%         rl_next_state = randsample(nstates, 1);
%     end    

    % Update MDP
    transition_counter(rl_state, rl_next_state, rl_action) = transition_counter(rl_state, rl_next_state, rl_action) + 1;
    reward_counter(rl_state, rl_next_state, rl_action) = reward_counter(rl_state, rl_next_state, rl_action) + rl_reward;

    % Store data
    rl_data(ntuple, 1) = rl_state;
    rl_data(ntuple, 2) = rl_action;
    rl_data(ntuple, 3) = rl_reward;
    rl_data(ntuple, 4) = rl_next_state;

end

rl_data(end,:) = [];

% disp(horzcat('n_unique_states: ', num2str(length(unique(rl_data(:,1))))))
% disp(horzcat('%: ', num2str(100*(length(unique(rl_data(:,1)))/nstates))))
% 
% disp(horzcat('n_unique_actuins: ', num2str(length(unique(rl_data(:,2))))))
% disp(horzcat('%: ', num2str(100*(length(unique(rl_data(:,2)))/nactions))))

% disp(horzcat('total reward: ', num2str(sum(rl_data(:,3)))))


%% Plot mdp
figure(1)
clf
set(gcf, 'position', [100 50 1280 720], 'color', 'w')

subplot(3,1,1)
histogram(rl_data(:,1), 'binwidth', 2)
hold on
histogram(rl_data(rl_data(:,3) > 0,1), 'binwidth', 2)
set(gca, 'yscale', 'log')
title('States (location and heading)')
xlabel('State')
ylabel('Count')

subplot(3,1,2)
histogram(rl_data(:,2), 'binwidth', 0.25)
hold on
histogram(rl_data(rl_data(:,3) > 0,2), 'binwidth', 0.25)
% set(gca, 'yscale', 'log')
title('Actions (torques)')
xlabel('Action')
ylabel('#')

subplot(3,1,3)
plot(rl_data(:,3))
axis tight
title('Reward')
ylabel('Reward')
xlabel('xsteps')

export_fig(horzcat('agent_5_', num2str(date), '_mdp'), '-r150', '-jpg', '-nocrop')

transition_counter_save = transition_counter;
reward_counter_save = reward_counter;

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
            if abs(1 - sum(this_val)) > 0.001
                error('sgs')
            end
        end
        transition_counter(ii_state, :, naction) = this_val;
    end
end
x = [];
for ii_state = 1:nstates
    for naction = 1:nactions
        this_sum = sum(transition_counter(ii_state, :, naction));
        this_array = transition_counter(ii_state, :, naction);
        this_diff = 1 - sum(this_array);
        x = [x; this_array];
    end
end

mdp.T = transition_counter;
reward_counter = reward_counter_save ./ transition_counter_save;
reward_counter(isnan(reward_counter)) = 0;
mdp.R = reward_counter;
% mdp.TerminalStates = ["s7";"s8"];
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
training_opts.MaxStepsPerEpisode = 500;
training_opts.StopTrainingCriteria = "AverageReward";
training_opts.ScoreAveragingWindowLength = 5;
trainingStats_shallow = train(agent,env, training_opts);
figure(11)
clf
set(gcf, 'color', 'w')
scan_agent
ylim([0 nstates + 1])
title('Agent 5')
set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
export_fig(horzcat('agent_5_', num2str(date), '_net'), '-r150', '-jpg', '-nocrop')
save('agent_5', 'agent')


%% Deep
agent_opt = rlDQNAgentOptions;
agent_opt.DiscountFactor = 0.99;
% agent_opt.EpsilonGreedyExploration.Epsilon = 0.1;
% agent_opt.EpsilonGreedyExploration.EpsilonMin = 0.01;
% agent_opt.EpsilonGreedyExploration.EpsilonDecay = 0.005;
agent = rlDQNAgent(critic, agent_opt);
training_opts = rlTrainingOptions;
training_opts.MaxEpisodes = 500;
training_opts.MaxStepsPerEpisode = 500;
training_opts.StopTrainingCriteria = "AverageReward";
training_opts.ScoreAveragingWindowLength = 5;
training_opts.UseParallel = 1;
trainingStats_deep = train(agent, env, training_opts);
figure(12)
clf
set(gcf, 'color', 'w')
scan_agent
ylim([0 nstates + 1])
title('Agent 55')
set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
export_fig(horzcat('agent_55_', num2str(date), '_net'), '-r150', '-jpg', '-nocrop')
save('agent_55', 'agent')

