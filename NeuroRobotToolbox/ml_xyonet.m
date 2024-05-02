
ml_get_data_stats

ext_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*ext_data.mat'));

net_name = 'xyoNet';

ntuples = size(ext_dir, 1);

x1 = 0;
y1 = 0;
x2 = 1;
y2 = 1;


%%

thetas = zeros(ntuples, 1);
robot_xys = zeros(ntuples, 2);
disp(horzcat('Getting ', num2str(ntuples), ' xyos'))

for ntuple = 1:ntuples

    if ~rem(ntuple, round(ntuples/10))
        disp(num2str(ntuple/ntuples))
    end

    ext_fname = horzcat(ext_dir(ntuple).folder, '\', ext_dir(ntuple).name);
    load(ext_fname)

    robot_xy = ext_data.robot_xy;
    rblob_xy = ext_data.rblob_xy;    
    gblob_xy = ext_data.gblob_xy;    

    x1 = rblob_xy(1);
    y1 = rblob_xy(2);
    x2 = gblob_xy(1);
    y2 = gblob_xy(2);

    robot_xys(ntuple, :) = robot_xy;

    sepx = x1-x2;
    sepy = y1-y2;

    theta = mod(atan2d(sepy,sepx),360); 
    thetas(ntuple) = theta;

end

% thetas = round(thetas);
% robot_xys = round(robot_xys);

x = robot_xys(:,1);
y = robot_xys(:,2);

n1 = sum(x < 100 | x > 500);
ns = randsample(100:500, n1, 1);
x(x < 100 | x > 500) = ns;

n1 = sum(y < 100 | y > 400);
ns = randsample(100:400, n1, 1);
y(y < 100 | y > 400) = ns;

n1 = sum(thetas > 360);
ns = randsample(360, n1, 1);
thetas(thetas > 360) = ns;

%%

figure(3)
clf

subplot(3,2,1)
histogram(x)
title('x')

subplot(3,2,2)
histogram(y)
title('y')

subplot(3,2,3)
histogram(thetas)
title('o')

%%
% xyo_l1 = 4;
% xyo_l2 = 4;
% xyo_l3 = 4;
% xyo_l4 = 10;
% xyo_l5 = 10;
% xyo_drop = 1; % LearnRateDropPeriod
% xyo_maxeps = 2;
% xyo_minbatch = 128;

xyos = arrayDatastore([robot_xys(:,1) robot_xys(:,2) thetas]);
training_data = combine(image_ds, xyos);
numResponses = 3;

layers = [
    imageInputLayer([240 320 3])    
    convolution2dLayer(3,xyo_l1,'Padding','same')
    batchNormalizationLayer
    reluLayer    
    maxPooling2dLayer(2,'Stride',2)  
    convolution2dLayer(3,xyo_l2,'Padding','same')
    batchNormalizationLayer
    reluLayer
    maxPooling2dLayer(2,'Stride',2)
    convolution2dLayer(3,xyo_l3,'Padding','same')
    batchNormalizationLayer
    reluLayer
    fullyConnectedLayer(xyo_l4)
    reluLayer
    fullyConnectedLayer(xyo_l5)
    reluLayer
    fullyConnectedLayer(numResponses)];

if isdeployed
    this_str = 'none';
else
    this_str = 'training-progress';
end

options = trainingOptions("adam", ...
    ExecutionEnvironment='auto',...
    InitialLearnRate=1e-3, ...
    LearnRateSchedule="piecewise", ...
    LearnRateDropFactor=0.1, ...
    LearnRateDropPeriod=xyo_drop, ...
    Shuffle="every-epoch", ...
    MaxEpochs=xyo_maxeps, ...
    MiniBatchSize=xyo_minbatch, ...
    Plots=this_str, ...
    Metrics="rmse", ...
    VerboseFrequency=1, ...
    Verbose=1);

xyoNet = trainnet(training_data, layers, 'mse', options);

save(strcat(nets_dir_name, net_name), 'xyoNet')

% load(strcat(nets_dir_name, net_name))

%%
xyo_net_vals = zeros(ntuples, 3);
for ntuple = 1:ntuples
    if ~rem(ntuple, round(ntuples/10))
        disp(num2str(ntuple/ntuples))
    end
    im = readimage(image_ds, ntuple);
    xyo_net_vals(ntuple, :) = predict(xyoNet, double(im));
end

%%

figure(3)

subplot(3,2,4)
scatter(robot_xys(:,1), xyo_net_vals(:,1))
axis tight
title('X')

subplot(3,2,5)
scatter(robot_xys(:,2), xyo_net_vals(:,2))
axis tight
title('Y')

subplot(3,2,6)
scatter(thetas, xyo_net_vals(:,3))
axis tight
title('O')

