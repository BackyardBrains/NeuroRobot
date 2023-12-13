


close all
clear

get_images = 1;
get_torques = 1;
get_combs = 1;
get_rewards = 1;
get_buffer = 1;

rec_dir_name = '';
dataset_dir_name = 'C:\SpikerBot ML Datasets\';
nets_dir_name = strcat(userpath, '\Nets\');
net_name = 'dixie_repeat';

ml_get_images
ml_get_torques
ml_get_combs
ml_get_rewards


%%
image_size = round([227 302] * 0.03);
nsmall = 1000;
steps_per_sequence = 100;

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


%% Train DQN
fds = fileDatastore("./logs", "ReadFcn", @ml_readFcn);
fds.shuffle();
nfiles = length(fds.Files);

% Net
criticNet = [
    imageInputLayer([image_size(1) image_size(2) 1],"Name","imageinput_state","Normalization","none")
    convolution2dLayer(3,8,"Padding","same")
    reluLayer
    convolution2dLayer(3,8,"Padding","same")
    reluLayer
    % maxPooling2dLayer(2,'Stride',2)
    fullyConnectedLayer(400)
    reluLayer
    fullyConnectedLayer(300)
    reluLayer    
    fullyConnectedLayer(n_unique_actions)
    % softmaxLayer
    ];

% Critic
criticNet = dlnetwork(criticNet);
critic = rlVectorQValueFunction(criticNet,obsInfo,actInfo);
critic.UseDevice = 'gpu';

% Agent
agentOptions = rlDQNAgentOptions;
agentOptions.MiniBatchSize = 512;
agentOptions.ExperienceBufferLength = nsmall * steps_per_sequence;
agent = rlDQNAgent(critic,agentOptions);
% agent.AgentOptions.CriticOptimizerOptions.LearnRate = 0.1;
cqOpts = rlConservativeQLearningOptions;
agentOptions.BatchDataRegularizerOptions  = cqOpts;

% Training
tfdOpts = rlTrainingFromDataOptions;
tfdOpts.StopTrainingCriteria = "none";
tfdOpts.ScoreAveragingWindowLength = steps_per_sequence;
tfdOpts.MaxEpochs = 1000;
tfdOpts.NumStepsPerEpoch = steps_per_sequence;
trainFromData(agent, fds, tfdOpts);

% Save
agent_fname = horzcat(nets_dir_name, net_name, '2cups-ml');
save(agent_fname, 'agent')
disp(horzcat('agent net saved as ', agent_fname))

%
nsteps = 500;

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


