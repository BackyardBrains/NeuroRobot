

this_dir = '.\Data\Recording_1\';
% ndistances = 10;

% cd(this_dir)
% for ii = 0:ndistances-1
%     if ~exist(num2str(ii),'dir')
%         mkdir(num2str(ii))
%     end
% end
% cd ..
% cd ..

images = imageDatastore(strcat(this_dir, '*.png'));
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
%     dcat = floor(this_distance / 401);
    distance(nserial*2-1:nserial*2) = this_distance;

%     ind = nserial*2;
%     for ii = 1:2
%         fname = strcat(working_dir, num2str(dcat), '\image_', num2str(ind-(ii-1)), '.png');
%         uframe = readimage(images, ind);
%         imwrite(uframe, fname);
%     end
end

% images = imageDatastore(this_dir, 'IncludeSubfolders',true, 'LabelSource', 'foldernames');

label_info = labelDefinitionCreator;
labels = create(ldc);
addLabel(label_info, 'Distance', 'Custom')
gtSource = groundTruthDataSource(images);
gtruth = groundTruth(gtSource, labels, distance);

options = trainingOptions("sgdm", ...
    LearnRateSchedule="piecewise", ...
    LearnRateDropFactor=0.2, ...
    LearnRateDropPeriod=5, ...
    MaxEpochs=20, ...
    MiniBatchSize=64, ...
    Plots="training-progress")
net = trainNetwork(images, layers_1, options)



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
