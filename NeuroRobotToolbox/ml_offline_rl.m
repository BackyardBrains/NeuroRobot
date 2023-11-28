


close all
clear

nsmall = 100000;

rec_dir_name = '';
dataset_dir_name = 'C:\SpikerBot ML Datasets Livingroom\';
nets_dir_name = strcat(userpath, '\Nets\');

net_name = 'nova';

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


%%
image_size = round([227 302] * 0.3);
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

tempLayers1 = [
    imageInputLayer([image_size(1) image_size(2) 1],"Name","imageinput_state","Normalization","none")
    convolution2dLayer(3,16,"Padding","same")
    reluLayer
    fullyConnectedLayer(400)
    reluLayer
    fullyConnectedLayer(300,"Name","fc_image_final")];
lgraph = addLayers(lgraph,tempLayers1);

tempLayers2 = [
    imageInputLayer([1 1 1],"Name","imageinput_action","Normalization","none")
    fullyConnectedLayer(300,"Name","fc_action_final")];
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
title('Nova net')
drawnow

net = dlnetwork(this_graph);
summary(net)


%%
critic = rlQValueFunction(net,obsInfo,actInfo, "ObservationInputNames","imageinput_state","ActionInputNames","imageinput_action");
critic.UseDevice = 'gpu';
agent_opt = rlDQNAgentOptions;
agent = rlDQNAgent(critic, agent_opt);
agent.ExperienceBuffer = buffer;
tfdOpts = rlTrainingFromDataOptions('verbose', 1, 'MaxEpochs', 500, 'NumStepsPerEpoch', 20);
trainFromData(agent,tfdOpts);


%%
% getAction(agent, next_im_g)
save(horzcat(nets_dir_name, net_name, '-ml'), 'agent')


