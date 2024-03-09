


close all
clear

get_images = 0;
get_torques = 0;
get_combs = 1;
get_rewards = 1;
get_buffer = 1;

rec_dir_name = '';
dataset_dir_name = 'C:\SpikerBot\Datasets\livingroom\';
nets_dir_name = strcat(userpath, '\Nets\');
state_net_name = 'livingroom_supernet';
agent_name = 'smith';


%% Get images

disp('Getting images...')
if get_images
    image_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*_x.png'));
    save(strcat(nets_dir_name, state_net_name, '-image_dir'), 'image_dir')
else
    load(strcat(nets_dir_name, state_net_name, '-image_dir'))
end

nimages = size(image_dir, 1);
ntuples = nimages;
disp(horzcat('nimages / ntuples: ', num2str(ntuples)))


%% Get torques
disp('Getting torques...')
if get_torques
    torque_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*torques.mat'));
    ntorques = size(torque_dir, 1);
    torque_data = zeros(ntuples, 2);
    for ntuple = 1:ntuples
        if ~rem(ntuple, round(ntuples/10))
            disp(horzcat('done = ', num2str(round((100 * (ntuple/ntuples)))), '%'))
        end
        torque_fname = horzcat(torque_dir(ntuple).folder, '\', torque_dir(ntuple).name);
        load(torque_fname)
        torques(torques > 250) = 250;
        torques(torques < -250) = -250;
        torque_data(ntuple, :) = torques;
    end
    torque_data = fliplr(torque_data); % 240309 fix
    save(strcat(nets_dir_name, state_net_name, '-torque_data'), 'torque_data')
else
    load(strcat(nets_dir_name, state_net_name, '-torque_data'))
end


%% Get combs
n_unique_actions = 7;

disp('Getting actions / combs...')
if get_combs
    
    % rng(1)
    actions = kmeans(torque_data, n_unique_actions);
    n_unique_actions = length(unique(actions));
    motor_combs = zeros(n_unique_actions, 2);
    mode_action = mode(actions);

    disp(horzcat('mode action: ', num2str(mode_action)))


    figure(1)
    clf
    gscatter(torque_data(:,1)+randn(size(torque_data(:,1)))*4, torque_data(:,2)+randn(size(torque_data(:,2)))*4, actions, [],[],[], 'off')
    hold on
    for naction = 1:n_unique_actions
        motor_combs(naction, :) = mean(torque_data(actions == naction, :));
        text(motor_combs(naction, 1), motor_combs(naction, 2), num2str(naction), 'fontsize', 18, 'fontweight', 'bold')
    end
    axis padded
    set(gca, 'yscale', 'linear')
    title('Actions')
    xlabel('Torque 1')
    ylabel('Torque 2')
    drawnow
    
    save(strcat(nets_dir_name, state_net_name, '-actions'), 'actions')
    save(strcat(nets_dir_name, state_net_name, '-motor_combs'), 'motor_combs')
else
    load(strcat(nets_dir_name, state_net_name, '-actions'))
    load(strcat(nets_dir_name, state_net_name, '-motor_combs'))
end


%% Get rewards
disp('Getting rewards...')
if get_rewards

    % gnet = googlenet;
    
    rewards = zeros(ntuples, 1);
    
    for ntuple = 1:ntuples
    
        next_im = imread(strcat(image_dir(ntuple).folder, '\',  image_dir(ntuple).name));    
        
        this_reward = (sum(next_im(:)) / 52443810) * 2;

        % cup_score = sum(next_im(:));
        % cup_score = (sum(next_im(:))/(10^7)) - sum(abs(torque_data(ntuple, :)));  
        
        % [~, scores] = classify(gnet, next_im(1:224,1:224,:));
        % cup_score_left = max(scores([505 739 969]));
        % [~, scores] = classify(gnet, next_im(1:224,79:302,:));    
        % cup_score_right = max(scores([505 739 969]));
        % cup_score = max([cup_score_left cup_score_right]) * 10;
        % this_reward = cup_score;

        rewards(ntuple) = this_reward;
        disp(horzcat('ntuple = ', num2str(ntuple), ', done = ', num2str(100*(ntuple/ntuples)), '%, reward = ', num2str(this_reward)))
    end
    save(strcat(nets_dir_name, state_net_name, '->-', agent_name, '-rewards'), 'rewards')
else
    load(strcat(nets_dir_name, state_net_name, '->-', agent_name, '-rewards'))
end


%%
image_size = round([227 302] * 0.02);
nsmall = 5000;
steps_per_sequence = 50;

obsInfo = rlNumericSpec(image_size);
obsInfo.Name = "CameraImages";

actInfo = rlFiniteSetSpec(1:n_unique_actions);
actInfo.Name = "Actions";

small_inds = randsample(1:(ntuples-steps_per_sequence-5), nsmall);
mode_action = mode(actions);

if get_buffer
    disp('Getting buffer...')
    
    try
        rmdir logs s
    catch
    end
    mkdir('./logs')

    for n = 1:nsmall
        if ~rem(n, round(nsmall/100))
            disp(horzcat('Assembling buffer, % done = ', num2str(round((100 * (n/nsmall))))))
        end        
        start_ind = small_inds(n);
        clear exp
        for ntuple = 1:steps_per_sequence
            
            this_ind = start_ind + (ntuple - 1);
            
            this_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
            this_im_small = imresize(this_im, image_size);
            this_im_g = rgb2gray(this_im_small);
            
            next_im = imread(strcat(image_dir(this_ind + 5).folder, '\',  image_dir(this_ind + 5).name));
            next_im_small = imresize(next_im, image_size);
            next_im_g = rgb2gray(next_im_small);      

            exp(ntuple).Observation = {this_im_g};
            exp(ntuple).Action = {actions(this_ind)};

            if actions(this_ind) == mode_action
                action_cost = 0;
            else
                action_cost = 1;
            end
            exp(ntuple).Reward = rewards(this_ind) - action_cost;
            exp(ntuple).NextObservation = {next_im_g};
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


%% Train DQN
fds = fileDatastore("./logs", "ReadFcn", @ml_readFcn);
% fds.shuffle();
nfiles = length(fds.Files);

% Net
criticNet = [
    imageInputLayer([imdim_h imdim_w 3])
    
    convolution2dLayer(3,16,'Padding','same')
    batchNormalizationLayer
    reluLayer
    
    maxPooling2dLayer(2,'Stride',2)
    
    convolution2dLayer(3,16,'Padding','same')
    batchNormalizationLayer
    reluLayer

    maxPooling2dLayer(2,'Stride',2)
    
    convolution2dLayer(3,8,'Padding','same')
    batchNormalizationLayer
    reluLayer
    
    fullyConnectedLayer(n_unique_states)
    softmaxLayer];

% criticNet = [
%     imageInputLayer([image_size(1) image_size(2) 1],"Name","imageinput_state","Normalization","none")
%     convolution2dLayer(3,8,"Padding","same")
%     reluLayer
%     convolution2dLayer(3,8,"Padding","same")
%     reluLayer
%     % maxPooling2dLayer(2,'Stride',2)
%     fullyConnectedLayer(400)
%     reluLayer
%     fullyConnectedLayer(300)
%     reluLayer    
%     fullyConnectedLayer(n_unique_actions)
%     % softmaxLayer
%     ];

% Critic
criticNet = dlnetwork(criticNet);
critic = rlVectorQValueFunction(criticNet,obsInfo,actInfo);
critic.UseDevice = 'gpu';

% Agent
agentOptions = rlDQNAgentOptions;
agentOptions.MiniBatchSize = 128;
agentOptions.ExperienceBufferLength = nsmall * steps_per_sequence;
agent = rlDQNAgent(critic,agentOptions);
% agent.AgentOptions.CriticOptimizerOptions.LearnRate = 0.1;
cqOpts = rlConservativeQLearningOptions;
agentOptions.BatchDataRegularizerOptions  = cqOpts;

% Training
tfdOpts = rlTrainingFromDataOptions;
tfdOpts.StopTrainingCriteria = "none";
tfdOpts.ScoreAveragingWindowLength = steps_per_sequence;
tfdOpts.MaxEpochs = 200;
tfdOpts.NumStepsPerEpoch = steps_per_sequence;
trainFromData(agent, fds, tfdOpts);

% Save
agent_fname = horzcat(nets_dir_name, state_net_name, '->-', agent_name, '-ml');
save(agent_fname, 'agent')
disp(horzcat('agent net saved as ', agent_fname))

%
nsteps = 100;

figure(2)
clf

mini_inds = randsample(1:(ntuples-steps_per_sequence), nsteps);
data = zeros(nsteps, 1);
for nstep = 1:nsteps
    this_ind = mini_inds(nstep);
    this_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
    this_im_small = imresize(this_im, image_size);
    this_im_g = rgb2gray(this_im_small);
    this_action = getAction(agent, this_im_g);
    this_action = cell2mat(this_action);
    data(nstep) = this_action;
    image(this_im_g)
    title(num2str(this_action))
    drawnow
end

figure(2)
clf
plot(1:nsteps, repmat(mode_action, nsteps), 'linewidth', 2, 'color', [1 0.5 0])
hold on
plot(data, 'color', [0.2 0.7 0.2])
title('Actions taken')


