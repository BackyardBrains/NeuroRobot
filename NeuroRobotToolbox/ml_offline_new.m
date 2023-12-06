


close all
clear

get_imdir = 1;
get_torques = 1;
get_combs = 1;
get_rewards = 1;
get_buffer = 1;

rec_dir_name = '';
dataset_dir_name = 'C:\SpikerBot ML Datasets\';
nets_dir_name = strcat(userpath, '\Nets\');

net_name = 'tessier';

gnet = googlenet;


%% Get images
disp('Getting images...')
if get_imdir
    image_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*_x.png'));
    save(strcat(nets_dir_name, net_name, '-image_dir'), 'image_dir')
else
    load(strcat(nets_dir_name, net_name, '-image_dir'))
end

nimages = size(image_dir, 1);
ntuples = nimages;
disp(horzcat('nimages / ntuples: ', num2str(ntuples)))


%% Torques
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
    save(strcat(nets_dir_name, net_name, '-torque_data'), 'torque_data')
else
    load(strcat(nets_dir_name, net_name, '-torque_data'))
end


%% Combs
disp('Getting actions / combs...')
if get_combs
    n_unique_actions = 10;
    rng(1)
    actions = kmeans(torque_data, n_unique_actions);
    n_unique_actions = length(unique(actions));
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
    
    save(strcat(nets_dir_name, net_name, '-actions'), 'actions')
    save(strcat(nets_dir_name, net_name, '-motor_combs'), 'motor_combs')
else
    load(strcat(nets_dir_name, net_name, '-actions'))
    load(strcat(nets_dir_name, net_name, '-motor_combs'))
end


%% Get rewards
disp('Getting rewards...')
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
image_size = round([227 302] * 0.1);
nsmall = 1000;
steps_per_sequence = 10;

obsInfo = rlNumericSpec(image_size);
obsInfo.Name = "CameraImages";

actInfo = rlFiniteSetSpec(1:n_unique_actions);
actInfo.Name = "Actions";

try
    rmdir logs s
catch
end
mkdir('./logs')

small_inds = randsample(6:(ntuples-steps_per_sequence), nsmall);

if get_buffer
    disp('Getting buffer...')
    for n = 1:nsmall
        if ~rem(n, round(nsmall/20))
            disp(horzcat('done = ', num2str(round((100 * (n/nsmall)))), '%'))
        end        
        start_ind = small_inds(n);
        clear exp
        for ntuple = 1:steps_per_sequence
            
            this_ind = start_ind + (ntuple - 1);
            
            this_im = imread(strcat(image_dir(this_ind - 5).folder, '\',  image_dir(this_ind - 5).name));
            this_im_small = imresize(this_im, image_size);
            this_im_g = rgb2gray(this_im_small);
            
            next_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
            next_im_small = imresize(next_im, image_size);
            next_im_g = rgb2gray(next_im_small);      

            exp(ntuple).Observation = {this_im_g};
            exp(ntuple).Action = {actions(this_ind - 5)};
            exp(ntuple).Reward = rewards(this_ind);
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

%%
fds = fileDatastore("./logs", "ReadFcn", @ml_readFcn);
nfiles = length(fds.Files);


%% Train DQN 
criticNet = [
    imageInputLayer([image_size(1) image_size(2) 1],"Name","imageinput_state","Normalization","none")
    convolution2dLayer(5,16,"Padding","same")
    reluLayer
    convolution2dLayer(3,8,"Padding","same")
    reluLayer
    fullyConnectedLayer(64)
    reluLayer
    fullyConnectedLayer(24)
    reluLayer
    fullyConnectedLayer(n_unique_actions)
    ];

criticNet = dlnetwork(criticNet);
summary(criticNet)

critic = rlVectorQValueFunction(criticNet,obsInfo,actInfo);
critic.UseDevice = 'gpu';
critic.LearnRate = 0.1;
agentOptions = rlDQNAgentOptions;
agentOptions.MiniBatchSize = 256;
agentOptions.ExperienceBufferLength = nsmall * steps_per_sequence;

agent = rlDQNAgent(critic,agentOptions);

tfdOpts = rlTrainingFromDataOptions;
tfdOpts.StopTrainingCriteria = "none";
tfdOpts.ScoreAveragingWindowLength = 10;
tfdOpts.MaxEpochs = 1000;
tfdOpts.NumStepsPerEpoch = 10;

options = trainingOptions("sgdm", ...
    LearnRateSchedule="piecewise", ...
    LearnRateDropFactor=0.2, ...
    LearnRateDropPeriod=5, ...
    MaxEpochs=20, ...
    MiniBatchSize=64, ...
    Plots="training-progress")

trainFromData(agent, fds, tfdOpts);

agent_fname = horzcat(nets_dir_name, net_name, '2cups-ml');
save(agent_fname, 'agent')
disp(horzcat('agent net saved as ', agent_fname))

