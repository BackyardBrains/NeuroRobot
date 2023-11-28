


close all
clear

nsmall = 10000;

rec_dir_name = '';
dataset_dir_name = 'C:\SpikerBot ML Datasets\';

gnet = googlenet;

image_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*_x.png'));
torque_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*torques.mat'));

nimages = size(image_dir, 1);
ntorques = size(torque_dir, 1);
ntuples = nimages;
disp(horzcat('ntuples: ', num2str(ntuples)))

get_torques
n_unique_actions = 9;
rng(1)
actions = kmeans(torque_data, n_unique_actions);
n_unique_actions = length(unique(actions));


%%
image_size = round([227 302] * 0.5);
obsInfo = rlNumericSpec(image_size);
obsInfo.Name = "CameraImages";

actInfo = rlFiniteSetSpec(1:9);
actInfo.Name = "TorqueCombs";

buffer = rlReplayMemory(obsInfo,actInfo);

clear exp

small_inds = randsample(6:ntuples, nsmall);

for ii = 1:nsmall
    
    this_ind = small_inds(ii);
    disp(horzcat('offline step = ', num2str(ii), ', tuple ind = ', num2str(this_ind), ', done = ', num2str(100*(ii/nsmall)), '%' ))

    this_im = imread(strcat(image_dir(this_ind - 5).folder, '\',  image_dir(this_ind - 5).name));
    this_im_small = imresize(this_im, image_size);
    this_im_g = rgb2gray(this_im_small);

    next_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
    next_im_small = imresize(next_im, image_size);
    next_im_g = rgb2gray(next_im_small);
    
    [~, scores] = classify(gnet, next_im(1:224,1:224,:));
    cup_score_left = max(scores([505 739 969]));

    [~, scores] = classify(gnet, next_im(1:224,79:302,:));    
    cup_score_right = max(scores([505 739 969]));
    
    cup_score = max([cup_score_left cup_score_right]);

    exp(ii).Observation = {this_im_g};
    exp(ii).Action = {actions(this_ind - 5)};
    exp(ii).Reward = cup_score;
    exp(ii).NextObservation = {next_im_g};
    exp(ii).IsDone = 0;

    % obs1.CData = this_im_g;
    % txt1.String = horzcat('Action = ', num2str(cell2mat(exp(ii).Action)));
    % 
    % obs2.CData = next_im_g;
    % txt2.String = horzcat('Reward = ', num2str(exp(ii).Reward));

    % 1

end

validateExperience(buffer,exp)
append(buffer,exp);


%% DQN
lgraph = layerGraph();

tempLayers = [
    imageInputLayer([image_size(1) image_size(2) 1],"Name","imageinput_state","Normalization","none")

    % convolution2dLayer([3 3],32,"Name","conv","Padding","same")
    % reluLayer("Name","relu")

    convolution2dLayer(3,32,'Padding','same')
    batchNormalizationLayer
    reluLayer

    maxPooling2dLayer(2,'Stride',2)

    convolution2dLayer(3,32,'Padding','same')
    batchNormalizationLayer
    reluLayer

    maxPooling2dLayer(2,'Stride',2)
    
    convolution2dLayer(3,16,'Padding','same')
    batchNormalizationLayer
    reluLayer    

    fullyConnectedLayer(400,"Name","fc")
    reluLayer("Name","relu_1")

    fullyConnectedLayer(300,"Name","fc_image_final")];

lgraph = addLayers(lgraph,tempLayers);


tempLayers = [
    imageInputLayer([1 1 1],"Name","imageinput_action","Normalization","none")

    fullyConnectedLayer(300,"Name","fc_action_final")];

lgraph = addLayers(lgraph,tempLayers);

tempLayers = [
    additionLayer(2,"Name","addition")
    reluLayer("Name","relu_2")

    fullyConnectedLayer(1,"Name","fc_rew")];

lgraph = addLayers(lgraph,tempLayers);


% clean up helper variable
clear tempLayers;

lgraph = connectLayers(lgraph,"fc_image_final","addition/in1");
lgraph = connectLayers(lgraph,"fc_action_final","addition/in2");

plot(lgraph);

net = dlnetwork(lgraph);
summary(net)

%%
critic = rlQValueFunction(net,obsInfo,actInfo, "ObservationInputNames","imageinput_state","ActionInputNames","imageinput_action");
critic.UseDevice = 'gpu';
agent_opt = rlDQNAgentOptions;
agent = rlDQNAgent(critic, agent_opt);
agent.ExperienceBuffer = buffer;
tfdOpts = rlTrainingFromDataOptions('verbose', 1, 'MaxEpochs', 500, 'NumStepsPerEpoch', 50);
trainFromData(agent,tfdOpts);

%%
getAction(agent, this_im)



