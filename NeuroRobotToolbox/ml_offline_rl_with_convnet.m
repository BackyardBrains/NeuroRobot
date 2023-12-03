

% Run this after ml_get_tuples


close all
clear

get_rewards = 0;
get_imdir = 0;
get_combs = 0;
get_buffer = 1;

nsmall = 100000;

rec_dir_name = '';
dataset_dir_name = 'C:\SpikerBot ML Datasets Livingroom\';
nets_dir_name = strcat(userpath, '\Nets\');
net_name = 'livingroomNet';


%%
load(strcat(nets_dir_name, net_name, '-states'))
load(strcat(nets_dir_name, net_name, '-torque_data'))
load(strcat(nets_dir_name, net_name, '-actions'))
load(strcat(nets_dir_name, net_name, '-ml'))
load(strcat(nets_dir_name, net_name, '-labels'))

n_unique_states = length(labels);
disp(horzcat('n unique states: ', num2str(n_unique_states)))

n_unique_actions = length(unique(actions));
disp(horzcat('n unique actions: ', num2str(n_unique_actions)))

obsInfo = rlFiniteSetSpec(1);
obsInfo.Name = "States";

actInfo = rlFiniteSetSpec(1:n_unique_actions);
actInfo.Name = "Actions";

%% Get rewards
if get_rewards
    gnet = googlenet;
    rewards = zeros(ntuples, 1);
    for ntuple = 1:ntuples
        next_im = imread(strcat(image_dir(ntuple).folder, '\',  image_dir(ntuple).name));    
        [~, scores] = classify(gnet, next_im(1:224,1:224,:));
        cup_score_left = max(scores([505 739 969]));
        [~, scores] = classify(gnet, next_im(1:224,79:302,:));    
        cup_score_right = max(scores([505 739 969]));
        cup_score = max([cup_score_left cup_score_right]) * 10;
        rewards(ntuple) = cup_score;
        disp(horzcat('ntuple = ', num2str(ntuple), ', done = ', num2str(100*(ntuple/ntuples)), '%, reward = ', num2str(cup_score)))
    end
    save(strcat(nets_dir_name, net_name, '-rewards'), 'rewards')
else
    load(strcat(nets_dir_name, net_name, '-rewards'))
end


%%
if get_imdir
    image_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*_x.png'));
    save(strcat(nets_dir_name, net_name, '-image_dir'), 'image_dir')
else
    load(strcat(nets_dir_name, net_name, '-image_dir'))
end

nimages = size(image_dir, 1);
ntuples = nimages;
disp(horzcat('ntuples: ', num2str(ntuples)))

if get_combs
    motor_combs = zeros(2, n_unique_actions);
    figure(1)
    clf
    gscatter(torque_data(:,1)+randn(size(torque_data(:,1)))*4, torque_data(:,2)+randn(size(torque_data(:,2)))*4, actions, [],[],[], 'off')
    hold on
    for naction = 1:n_unique_actions
        motor_combs(:,naction) = mean(torque_data(actions == naction, :));
        text(motor_combs(1,naction), motor_combs(2,naction), num2str(naction), 'fontsize', 16, 'fontweight', 'bold')
    end
    axis padded
    set(gca, 'yscale', 'linear')
    title('Actions')
    xlabel('Torque 1')
    ylabel('Torque 2')
    drawnow
    save(strcat(nets_dir_name, net_name, '-motor_combs'), 'motor_combs')
else
    load(strcat(nets_dir_name, net_name, '-motor_combs'))
end


%%
try
    rmdir logs s
catch
end
mkdir('./logs')
steps_per_sequence = 10;

small_inds = randsample(6:(ntuples-steps_per_sequence), nsmall);

if get_buffer
    disp('Getting buffer...')
    % buffer = rlReplayMemory(obsInfo,actInfo, nsmall * steps_per_sequence);
    for n = 1:nsmall
        if ~rem(n, round(nsmall/20))
            disp(horzcat('done = ', num2str(round((100 * (n/nsmall)))), '%'))
        end        
        start_ind = small_inds(n);
        clear exp
        for ntuple = 1:steps_per_sequence
            this_ind = start_ind + (ntuple - 1);
            exp(ntuple).Observation = {states(this_ind - 5)};
            exp(ntuple).Action = {actions(this_ind - 5)};
            exp(ntuple).Reward = rewards(this_ind);
            exp(ntuple).NextObservation = {states(this_ind)};
            exp(ntuple).IsDone = 0;
        end
        exp(steps_per_sequence).IsDone = 1;
        if n >= 10000
            this_str = '';
        elseif n >= 1000
            this_str = '0';
        elseif n >= 100
            this_str = '00';
        elseif n >= 10
            this_str = '000';
        else
            this_str = '0000';
        end
        save(strcat('./logs/', 'loggedData', this_str, num2str(n)), 'exp')
    end
end

%%
fds = fileDatastore("./logs", "ReadFcn", @ml_readFcn);
nfiles = length(fds.Files);


%% Train DQN 
criticNet = [
    featureInputLayer(1)
    fullyConnectedLayer(200)
    reluLayer
    fullyConnectedLayer(300)
    reluLayer
    fullyConnectedLayer(200)
    reluLayer    
    fullyConnectedLayer(n_unique_actions)
    ];

criticNet = dlnetwork(criticNet);
summary(criticNet)

critic = rlVectorQValueFunction(criticNet,obsInfo,actInfo);

agentOptions = rlDQNAgentOptions;
agentOptions.MiniBatchSize = 512;
agent = rlDQNAgent(critic,agentOptions);

tfdOpts = rlTrainingFromDataOptions;
tfdOpts.StopTrainingCriteria = "none";
tfdOpts.ScoreAveragingWindowLength = 10;
tfdOpts.MaxEpochs = 10000;
tfdOpts.NumStepsPerEpoch = 10;

trainFromData(agent, fds, tfdOpts);

agent_fname = horzcat(nets_dir_name, net_name, '2cups-ml');
save(agent_fname, 'agent')
disp(horzcat('agent net saved as ', agent_fname))

