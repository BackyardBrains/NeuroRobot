


close all
clear

nsmall = 10000;
get_imdir = 0;
get_combs = 1;
get_buffer = 1;

rec_dir_name = '';
dataset_dir_name = 'C:\SpikerBot ML Datasets Livingroom\';
nets_dir_name = strcat(userpath, '\Nets\');

net_name = 'livingroom2cups';

gnet = googlenet;

if get_imdir
    image_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*_x.png'));
    save(strcat(nets_dir_name, net_name, '-image_dir'), 'image_dir')
else
    load(strcat(nets_dir_name, net_name, '-image_dir'))
end

nimages = size(image_dir, 1);
ntuples = nimages;
disp(horzcat('ntuples: ', num2str(ntuples)))

small_inds = randsample(6:ntuples-10, nsmall);

n_unique_actions = 9; %%%%%%%%

if get_combs
    torque_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*torques.mat'));
    ntorques = size(torque_dir, 1);
    get_torques
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


%%
image_size = round([227 302] * 0.5);
obsInfo = rlNumericSpec(image_size);
obsInfo.Name = "CameraImages";

actInfo = rlFiniteSetSpec(n_unique_actions);
actInfo.Name = "Actions";

if get_buffer
    buffer = rlReplayMemory(obsInfo,actInfo);
    clear exp
    for ii = 1:nsmall
    
        disp(horzcat('offline step = ', num2str(ii), ', done = ', num2str(100*(ii/nsmall)), '%' ))
    
        this_ind = small_inds(ii);
            
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
        
        cup_score = max([cup_score_left cup_score_right]) * 10;
    
        exp.Observation = {this_im_g};
        exp.Action = {actions(this_ind - 5)};
        exp.Reward = cup_score;
        exp.NextObservation = {next_im_g};
        exp.IsDone = 0;
    
        validateExperience(buffer,exp)
        append(buffer,exp);
    
    end
    
    save(strcat(nets_dir_name, net_name, '-buffer'), 'buffer')
else
    load(strcat(nets_dir_name, net_name, '-buffer'))
end


%%
lgraph = layerGraph();

tempLayers1 = [
    imageInputLayer([image_size(1) image_size(2) 1],"Name","imageinput_state","Normalization","none")
    convolution2dLayer(3,16,"Padding","same")
    reluLayer
    convolution2dLayer(3,8,"Padding","same")
    reluLayer
    fullyConnectedLayer(200)
    reluLayer
    fullyConnectedLayer(100,"Name","fc_image_final")];
lgraph = addLayers(lgraph,tempLayers1);

tempLayers2 = [
    imageInputLayer([1 1 1],"Name","imageinput_action","Normalization","none")
    fullyConnectedLayer(100,"Name","fc_action_final")];
lgraph = addLayers(lgraph,tempLayers2);

tempLayers3 = [
    additionLayer(2)
    reluLayer
    fullyConnectedLayer(1)];
this_graph = addLayers(lgraph,tempLayers3);

% clean up helper variable
clear tempLayers1;
clear tempLayers2;
clear tempLayers3;

this_graph = connectLayers(this_graph,"fc_image_final","addition/in1");
this_graph = connectLayers(this_graph,"fc_action_final","addition/in2");

figure(2)
clf
plot(this_graph);
title('Agent net')
drawnow

net = dlnetwork(this_graph);
summary(net)


critic = rlQValueFunction(net,obsInfo,actInfo, "ObservationInputNames","imageinput_state","ActionInputNames","imageinput_action");
critic.UseDevice = 'gpu';
agent_opt = rlDQNAgentOptions('MiniBatchSize', 64);
agent = rlDQNAgent(critic, agent_opt);
agent.ExperienceBuffer = buffer;
agent.AgentOptions.CriticOptimizerOptions.LearnRate = 0.01;
agent.AgentOptions.EpsilonGreedyExploration.Epsilon = 0.05;
tfdOpts = rlTrainingFromDataOptions('Verbose', 1, 'MaxEpochs', 100, 'NumStepsPerEpoch', 10, 'ScoreAveragingWindowLength', 10);
trainFromData(agent,tfdOpts);
agent_fname = horzcat(nets_dir_name, net_name, '-ml');
save(agent_fname, 'agent')
disp(horzcat('agent net saved as ', agent_fname))









% %% Train neural agent from data
% criticNet = [
%     imageInputLayer([image_size(1) image_size(2) 1],"Name","imageinput","Normalization","none")
%     convolution2dLayer(3,16,"Padding","same")
%     reluLayer
%     fullyConnectedLayer(24)
%     reluLayer
%     fullyConnectedLayer(numel(actInfo.Elements))
%     ];
% 
% criticNet = dlnetwork(criticNet);
% summary(criticNet)
% 
% figure(2)
% clf
% plot(criticNet);
% title('criticNet')
% drawnow
% 
% critic = rlVectorQValueFunction(criticNet,obsInfo,actInfo, "ObservationInputNames","imageinput");
% agentOptions = rlDQNAgentOptions(MiniBatchSize=16);
% agent = rlDQNAgent(critic,agentOptions);
% % agent = rlDQNAgent(critic);
% % agent.AgentOptions.EpsilonGreedyExploration.Epsilon = .04;
% % agent.AgentOptions.CriticOptimizerOptions.LearnRate = 0.1;
% agent.ExperienceBuffer = buffer;
% % tfdOpts = rlTrainingFromDataOptions;
% % tfdOpts.StopTrainingCriteria = "none";
% % tfdOpts.ScoreAveragingWindowLength = 30;
% % tfdOpts.MaxEpochs = 1000;
% % tfdOpts.NumStepsPerEpoch = 10;
% trainFromData(agent);





