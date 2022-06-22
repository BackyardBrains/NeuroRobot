

close all
clear
clc

this_dir = '.\Data\Recording_1\';
imdim = 50;

serials = dir(strcat(this_dir, '*serial_data.mat'));
nserials = size(serials, 1);
distance = zeros(nserials * 2, 1);
for nserial = 1:nserials
    if ~rem(nserial, round(nserials/10))
        disp(num2str(nserial/(nserials)))
    end    
    load(horzcat(this_dir, serials(nserial).name))
    this_distance = str2double(serial_data{3});
    this_distance(this_distance >= 4000) = 0;
    if this_distance
        this_distance = this_distance/4000;
    end
    distance(nserial*2-1:nserial*2) = this_distance;
end

dist_ds = arrayDatastore(distance);

img_ds = imageDatastore(strcat(this_dir, '*uframe.png'));
nimgs = size(img_ds.Files, 1);
img_ds.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually

final_ds = combine(img_ds, dist_ds);

%%
layers = [
    imageInputLayer([imdim imdim 3],"Name","imageinput","Normalization","rescale-zero-one")
    convolution2dLayer([3 3],32,"Name","conv","Padding","same")
    reluLayer("Name","relu_1")
    fullyConnectedLayer(100,"Name","fc_1")
    reluLayer("Name","relu_2")
    fullyConnectedLayer(100,"Name","fc_2")    
    reluLayer("Name","relu_3")
    fullyConnectedLayer(1,"Name","fc_3")
    regressionLayer("Name","regressionoutput")];

options = trainingOptions("adam", Plots="training-progress")

net = trainNetwork(final_ds, layers, options)



%%
data = zeros(nimgs, 1);
for ii = 1:nimgs
    ii/nimgs
    im = readimage(img_ds, ii);
    data(ii) = predict(net, im);
end

figure(1)
clf
scatter(distance, data)






% clear
% clc
% 
% load env.mat
% load lgraph_1.mat
% 
% obsInfo = getObservationInfo(env);
% actInfo = getActionInfo(env);
% net = dlnetwork(lgraph_1);
% critic = rlQValueFunction(net,obsInfo,actInfo,...
%     "ObservationInputNames",["pendImage","angularRate"],"ActionInputNames","torque");
% 
% criticOpts = rlOptimizerOptions('LearnRate',1e-03,'GradientThreshold',1);
% 
% agentOpts = rlDQNAgentOptions(...
%     'UseDoubleDQN',false,...    
%     'CriticOptimizerOptions',criticOpts,...
%     'ExperienceBufferLength',1e6,... 
%     'SampleTime',env.Ts);
% agentOpts.EpsilonGreedyExploration.EpsilonDecay = 1e-5;
% 
% agent = rlDQNAgent(critic,agentOpts);
% 
% trainOpts = rlTrainingOptions(...
%     'MaxEpisodes',5000,...
%     'MaxStepsPerEpisode',500,...
%     'Verbose',false,...
%     'Plots','training-progress',...
%     'StopTrainingCriteria','AverageReward',...
%     'StopTrainingValue',-1000);
% 
