    
%% Get net

clear
clc

imdim = 100;
data_dir_name = 'C:\Users\Christopher Harris\Dataset2\';

image_dir = dir(fullfile(data_dir_name, '**\*.png'));
serial_dir = dir(fullfile(data_dir_name, '**\*serial_data.mat'));
robot_xy_dir = dir(fullfile(data_dir_name, '**\*robot_xy.mat'));
torque_dir = dir(fullfile(data_dir_name, '**\*torques.mat'));

ntuples = size(torque_dir, 1);
disp(horzcat('ntuples: ', num2str(ntuples)))

ps = parallel.Settings;
ps.Pool.AutoCreate = false;
ps.Pool.IdleTimeout = Inf;

%% Get left frames
lframes = zeros(imdim, imdim, 3, ntuples);
disp(horzcat('Getting ', num2str(ntuples), ' frames'))
for ntuple = 1:ntuples
    if ~rem(ntuple, round(ntuples/5))
        disp(horzcat(num2str(round(100*(ntuple/ntuples))), ' %'))
    end
    this_ind = ntuple*2-1;    
    left_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
    left_im = imresize(left_im, [imdim imdim]);
    lframes(:,:,:,ntuple) = left_im;
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
dists = round(dists / 1000);
unique_states = unique(dists);
n_unique_states = length(unique_states);

%% Get robot XYs
robot_xy_data = zeros(ntuples, 2);
disp(horzcat('Getting ', num2str(ntuples), ' robot xys'))
for ntuple = 1:ntuples
    if ~rem(ntuple, round(ntuples/5))
        disp(horzcat(num2str(round(100*(ntuple/ntuples))), ' %'))
    end
    robot_xy_fname = horzcat(robot_xy_dir(ntuple).folder, '\', robot_xy_dir(ntuple).name);
    load(robot_xy_fname)
    robot_xy_data(ntuple, :) = robot_xy;
end

figure(1)
clf
plot(robot_xy_data(:,1), robot_xy_data(:,2))
set(gca, 'ydir', 'reverse')

%% Get distance to target (D2Gs)
target_x = 250;
target_y = 100;

d2g = zeros(ntuples, 1);
for ntuple = 1:ntuples
    if ~rem(ntuple, round(ntuples/5))
        disp(horzcat(num2str(round(100*(ntuple/ntuples))), ' %'))
    end    
    xdist = robot_xy_data(ntuple, 1) - target_x;
    ydist = robot_xy_data(ntuple, 2) - target_y;
    d2g(ntuple) = sqrt(xdist^2 + ydist^2);
end

dd2g = zeros(ntuples, 1);
for ntuple = 1:ntuples - 5
    dd2g(ntuple) = d2g(ntuple + 5) - d2g(ntuple);
end

%% Get torques
torque_data = zeros(ntuples, 2);
disp(horzcat('Getting ', num2str(ntuples), ' torques'))
for ntuple = 1:ntuples
    if ~rem(ntuple, round(ntuples/5))
        disp(horzcat(num2str(round(100*(ntuple/ntuples))), ' %'))
    end
    torque_fname = horzcat(torque_dir(ntuple).folder, '\', torque_dir(ntuple).name);
    load(torque_fname)
    torques(torques > 250) = 250;
    torques(torques < -250) = -250;
    torque_data(ntuple, :) = torques;
end

%% Get actions
n_unique_actions = 9;
actions = kmeans(torque_data, n_unique_actions);
still = torque_data(:,1) == 0 & torque_data(:,2) == 0;
disp(horzcat('n still actions: ', num2str(sum(still))))
actions(still) = n_unique_actions + 1;
save(strcat(data_dir_name, 'actions'), 'actions')

load(strcat(data_dir_name, 'actions'))
n_unique_actions = length(unique(actions));
disp(horzcat('n unique actions: ', num2str(n_unique_actions)))

% figure(7)
% gscatter(torque_data(:,1)+randn(size(torque_data(:,1)))*1.5, torque_data(:,2)+randn(size(torque_data(:,2)))*1.5, actions)

%% Combine
frames = arrayDatastore(lframes, IterationDimension=4);
dsts = categorical(dists);
dsts = arrayDatastore(dsts);
% acts = arrayDatastore(actions);
% dsts = arrayDatastore(dists);
% dd = arrayDatastore(dd2g);
% % ds_train = combine(frames, acts, dsts);
ds_train = combine(frames, dsts);

%%
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

%     fullyConnectedLayer(50)
%     flattenLayer
%     concatenationLayer(1,2,Name="cat")

    fullyConnectedLayer(n_unique_states)
    softmaxLayer
    classificationLayer];    

lgraph = layerGraph(layers);

% featInput = featureInputLayer(1,Name="actions");
% lgraph = addLayers(lgraph,featInput);
% lgraph = connectLayers(lgraph,"actions","cat/in2");

figure(5)
clf
plot(lgraph)
drawnow

%%

options = trainingOptions("adam", 'ExecutionEnvironment', 'auto', ...
    MaxEpochs=15, Plots="training-progress", Shuffle ='every-epoch', Verbose=1);

net = trainNetwork(ds_train,lgraph,options);

