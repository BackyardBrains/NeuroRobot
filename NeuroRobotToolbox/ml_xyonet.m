
state_net_name = ml_name1_edit.String;
ml_get_data_stats
n_unique_states = init_n_unique_states;

if ml_h == 240
    image_ds.ReadFcn = @default_read;
else
    image_ds.ReadFcn = @resize_read;
end    

ext_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*ext_data.mat'));

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

xyos = arrayDatastore([robot_xys(:,1) robot_xys(:,2) thetas]);
training_data = combine(image_ds, xyos);
numResponses = 3;

layers = [
    imageInputLayer([ml_h ml_w 3]) 
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
save(strcat(nets_dir_name, state_net_name), 'xyoNet')


%%
xyo_net_vals = zeros(ntuples, 3);
for ntuple = 1:ntuples
    if ~rem(ntuple, round(ntuples/20))
        disp(num2str(ntuple/ntuples))
    end
    im = readimage(image_ds, ntuple);
    xyo_net_vals(ntuple, :) = predict(xyoNet, double(im));
end


%%
figure(12)

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


%%
states = zeros(ntuples, 1);

if n_unique_states == 16

    for ntuple = 1:ntuples

        x = xyo_net_vals(ntuple, 1);
        y = xyo_net_vals(ntuple, 2);
        o = xyo_net_vals(ntuple, 3);

        if o >= 0 && o < 90
            if y <= 200
                if x < 250
                    states(ntuple) = 1;
                else
                    states(ntuple) = 2;
                end
            else
                if x < 250
                    states(ntuple) = 3;
                else
                    states(ntuple) = 4;
                end
            end
        elseif o >= 90 && o < 180
            if y <= 200
                if x < 250
                    states(ntuple) = 5;
                else
                    states(ntuple) = 6;
                end
            else
                if x < 250
                    states(ntuple) = 7;
                else
                    states(ntuple) = 8;
                end
            end
        elseif o >= 180 && o < 270
            if y <= 200
                if x < 250
                    states(ntuple) = 9;
                else
                    states(ntuple) = 10;
                end
            else
                if x < 250
                    states(ntuple) = 11;
                else
                    states(ntuple) = 12;
                end
            end    
        else
            if y <= 250
                if x < 250
                    states(ntuple) = 13;
                else
                    states(ntuple) = 14;
                end
            else
                if x < 250
                    states(ntuple) = 15;
                else
                    states(ntuple) = 16;
                end
            end            
        end
    end

elseif n_unique_states == 36

    for ntuple = 1:ntuples
        if o >= 0 && o < 90
            if y <= 200
                if x < 233
                    states(ntuple) = 1;
                elseif x < 366
                    states(ntuple) = 2;
                else
                    states(ntuple) = 3;
                end
            elseif y <= 300
                if x < 233
                    states(ntuple) = 4;
                elseif x < 366
                    states(ntuple) = 5;
                else
                    states(ntuple) = 6;
                end
            else
                if x < 233
                    states(ntuple) = 7;
                elseif x < 366
                    states(ntuple) = 8;
                else
                    states(ntuple) = 9;
                end
            end
        elseif o >= 90 && o < 180
            if y <= 200
                if x < 233
                    states(ntuple) = 10;
                elseif x < 366
                    states(ntuple) = 11;
                else
                    states(ntuple) = 12;
                end
            elseif y <= 300
                if x < 233
                    states(ntuple) = 13;
                elseif x < 366
                    states(ntuple) = 14;
                else
                    states(ntuple) = 15;
                end
            else
                if x < 233
                    states(ntuple) = 16;
                elseif x < 366
                    states(ntuple) = 17;
                else
                    states(ntuple) = 18;
                end
            end
        elseif o >= 180 && o < 270
            if y <= 200
                if x < 233
                    states(ntuple) = 19;
                elseif x < 366
                    states(ntuple) = 20;
                else
                    states(ntuple) = 21;
                end
            elseif y <= 300
                if x < 233
                    states(ntuple) = 22;
                elseif x < 366
                    states(ntuple) = 23;
                else
                    states(ntuple) = 24;
                end
            else
                if x < 233
                    states(ntuple) = 25;
                elseif x < 366
                    states(ntuple) = 26;
                else
                    states(ntuple) = 27;
                end
            end
        else
            if y <= 200
                if x < 233
                    states(ntuple) = 28;
                elseif x < 366
                    states(ntuple) = 29;
                else
                    states(ntuple) = 30;
                end
            elseif y <= 300
                if x < 233
                    states(ntuple) = 31;
                elseif x < 366
                    states(ntuple) = 32;
                else
                    states(ntuple) = 33;
                end
            else
                if x < 233
                    states(ntuple) = 34;
                elseif x < 366
                    states(ntuple) = 35;
                else
                    states(ntuple) = 36;
                end
            end
        end
    end
else
    error('No xyo to states transform found')
end

save(horzcat(nets_dir_name, state_net_name, '-states'), 'states')

figure(13)
clf
set(gcf, 'position', [201 241 800 420], 'color', 'w')

histogram(states, 'binwidth', 0.4)
xlim([0 n_unique_states + 1])
title('States')


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


%% Torques
get_torques
save(horzcat(nets_dir_name, state_net_name, '-torque_data'), 'torque_data')
