    
%% Get net

clear
clc

imdim = 227;
data_dir_name = 'C:\Users\Christopher Harris\Dataset2\';

image_dir = dir(fullfile(data_dir_name, '**\*.png'));
serial_dir = dir(fullfile(data_dir_name, '**\*serial_data.mat'));
ext_data_dir = dir(fullfile(data_dir_name, '**\*ext_data.mat'));

ntuples = size(serial_dir, 1);

ps = parallel.Settings;
ps.Pool.AutoCreate = false;
ps.Pool.IdleTimeout = Inf;

%% Get left frames
left_frames = zeros(imdim, imdim, 3, ntuples);
disp(horzcat('Getting ', num2str(ntuples), ' frames'))
for ntuple = 1:ntuples
    if ~rem(ntuple, round(ntuples/5))
        disp(horzcat(num2str(round(100*(ntuple/ntuples))), ' %'))
    end
    this_ind = ntuple*2-1;    
    left_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
    left_im = imresize(left_im, [imdim imdim]);
    left_frames(:,:,:,ntuple) = left_im;
end

%% Get dists
dists = zeros(ntuples, 1);
disp(horzcat('getting ', num2str(ntuples), ' dists'))
for ntuple = 1:ntuples
    if ~rem(ntuple, round(ntuples/5))
        disp(horzcat(num2str(round(100*(ntuple/ntuples))), ' %'))
    end
    serial_fname = horzcat(serial_dir(ntuple).folder, '\', serial_dir(ntuple).name);
    load(serial_fname)
    this_distance = str2double(serial_data{3});
    this_distance(this_distance == Inf) = 0;    
    dists(ntuple, :) = this_distance;
end

%% Get robot XYs
robot_xy_data = zeros(ntuples, 2);
rblob_xy_data = zeros(ntuples, 2);
gblob_xy_data = zeros(ntuples, 2);
disp(horzcat('Getting ', num2str(ntuples), ' xys'))
for ntuple = 1:ntuples
    if ~rem(ntuple, round(ntuples/5))
        disp(horzcat(num2str(round(100*(ntuple/ntuples))), ' %'))
    end
    ext_data_fname = horzcat(ext_data_dir(ntuple).folder, '\', ext_data_dir(ntuple).name);
    load(ext_data_fname)
    robot_xy = ext_data.robot_xy;
    rblob_xy = ext_data.rblob_xy;
    gblob_xy = ext_data.gblob_xy;    
    robot_xy_data(ntuple, :) = robot_xy;
    rblob_xy_data(ntuple, :) = rblob_xy;
    gblob_xy_data(ntuple, :) = gblob_xy;
end

figure(1)
clf
plot(robot_xy_data(:,1), robot_xy_data(:,2))
set(gca, 'ydir', 'reverse')
drawnow 

%% Get distance to target (D2Gs)
target_x = 250;
target_y = 100;

d2g = zeros(ntuples, 1);
disp(horzcat('Getting ', num2str(ntuples), ' distances to target'))
for ntuple = 1:ntuples
    if ~rem(ntuple, round(ntuples/5))
        disp(horzcat(num2str(round(100*(ntuple/ntuples))), ' %'))
    end    
    xdist = robot_xy_data(ntuple, 1) - target_x;
    ydist = robot_xy_data(ntuple, 2) - target_y;
    d2g(ntuple) = sqrt(xdist^2 + ydist^2);
end

%% Get prime change in distance to target
% dd2g = zeros(ntuples, 1);
% for ntuple = 1:ntuples - 5
%     dd2g(ntuple) = d2g(ntuple + 5) - d2g(ntuple);
% end

%% Get torques
% torque_data = zeros(ntuples, 2);
% disp(horzcat('Getting ', num2str(ntuples), ' torques'))
% for ntuple = 1:ntuples
%     if ~rem(ntuple, round(ntuples/5))
%         disp(horzcat(num2str(round(100*(ntuple/ntuples))), ' %'))
%     end
%     torque_fname = horzcat(torque_dir(ntuple).folder, '\', torque_dir(ntuple).name);
%     load(torque_fname)
%     torques(torques > 250) = 250;
%     torques(torques < -250) = -250;
%     torque_data(ntuple, :) = torques;
% end
% 
%% Get actions
% n_unique_actions = 9;
% actions = kmeans(torque_data, n_unique_actions);
% still = torque_data(:,1) == 0 & torque_data(:,2) == 0;
% disp(horzcat('n still actions: ', num2str(sum(still))))
% actions(still) = n_unique_actions + 1;
% save(strcat(data_dir_name, 'actions'), 'actions')
% 
% load(strcat(data_dir_name, 'actions'))
% n_unique_actions = length(unique(actions));
% disp(horzcat('n unique actions: ', num2str(n_unique_actions)))
% 
% % figure(7)
% % gscatter(torque_data(:,1)+randn(size(torque_data(:,1)))*1.5, torque_data(:,2)+randn(size(torque_data(:,2)))*1.5, actions)

%% Combine
disp('Combining datastores...')
ds_frames = arrayDatastore(left_frames, IterationDimension=4);
ds_dists = arrayDatastore(dists);
nouts = 10;
thix_max = max(d2g);
reward = 1-(d2g/thix_max);
reward_num = round(nouts * reward);
reward_num(reward_num < 1) = 1;
reward_cats = categorical(reward_num);
ds_reward = arrayDatastore(reward_cats);

% create state array from location and orientation here (3x3x4)

ds = combine(ds_frames, ds_dists, ds_reward);
% ds = combine(ds_frames, ds_reward);


%%
disp('Creating neural network...')
layers = [
    imageInputLayer([imdim imdim 3], Normalization="none")
    
    convolution2dLayer(3,16,'Padding','same')
    batchNormalizationLayer
    reluLayer

    maxPooling2dLayer(2,'Stride',2)
        
    convolution2dLayer(3,32,'Padding','same')
    batchNormalizationLayer
    reluLayer    

    maxPooling2dLayer(2,'Stride',2)
        
    convolution2dLayer(3,32,'Padding','same')
    batchNormalizationLayer
    reluLayer       

    fullyConnectedLayer(100)
    batchNormalizationLayer
    reluLayer    

    fullyConnectedLayer(50)
    flattenLayer
    concatenationLayer(1,2,Name="cat")
    fullyConnectedLayer(nouts)
    softmaxLayer
    classificationLayer];

%     fullyConnectedLayer(1)
%     softmaxLayer
%     regressionLayer];


lgraph = layerGraph(layers);

figure(2)
clf
plot(lgraph)
drawnow

featInput = featureInputLayer(1,Name="actions");
lgraph = addLayers(lgraph,featInput);
lgraph = connectLayers(lgraph,"actions","cat/in2");
plot(lgraph)
drawnow

%% Train net
disp('Training neural network...')
options = trainingOptions("sgdm", 'ExecutionEnvironment', 'auto', ...
    MaxEpochs=10, Plots="training-progress", Shuffle ='every-epoch', ...
    LearnRateSchedule='piecewise', LearnRateDropPeriod = 1, Verbose=1);

net = trainNetwork(ds,lgraph,options);

disp('Neural network ready')


%% Test net
this_ind = round(ntuples * rand)*2-1;
this_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
this_im = imresize(this_im, [imdim imdim]);
[cat, score] = classify(net, this_im);
figure(3)
clf
image(this_im)
title(horzcat('frame = ', num2str(this_ind), ', cat = ', char(cat)))
