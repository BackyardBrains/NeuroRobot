
state_net_name = ml_name1_edit.String;

ml_get_data_stats
tx1.String = 'xyo alternative';

if ml_h == 240
    image_ds.ReadFcn = @default_read;
elseif ml_h == 48
    image_ds.ReadFcn = @resize_read_48;
elseif ml_h == 24
    image_ds.ReadFcn = @resize_read_24;
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
this_msg = horzcat('Getting ', num2str(ntuples), ' xyos');
disp(horzcat(this_msg))
tx1.String = this_msg;

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

this_x = robot_xys(:,1);
this_y = robot_xys(:,2);

xlim1 = prctile(this_x, 10);
xlim2 = prctile(this_x, 90);
n1 = sum(this_x < xlim1 | this_x > xlim2);
ns = randsample(xlim1:xlim2, n1, 1);
this_x(this_x < xlim1 | this_x > xlim2) = ns;

ylim1 = prctile(this_y, 10);
ylim2 = prctile(this_y, 90);
n1 = sum(this_y < ylim1 | this_y > ylim2);
ns = randsample(ylim1:ylim2, n1, 1);
this_y(this_y < ylim1 | this_y > ylim2) = ns;

%%
figure(6)
clf

subplot(3,3,1)
histogram(this_x)
title('True X')

subplot(3,3,2)
histogram(this_y)
title('True Y')

subplot(3,3,3)
histogram(thetas)
title('True O')


%%
this_msg = 'Training...';
disp(horzcat(this_msg))
tx1.String = this_msg;

xyos = arrayDatastore([this_x this_y thetas]);
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
    maxPooling2dLayer(2,'Stride',2)
    convolution2dLayer(3,xyo_l4,'Padding','same')
    batchNormalizationLayer
    reluLayer
    fullyConnectedLayer(xyo_l5)
    reluLayer
    fullyConnectedLayer(xyo_l6)
    reluLayer
    fullyConnectedLayer(xyo_l7)
    reluLayer
    fullyConnectedLayer(xyo_l8)
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
save(strcat(nets_dir_name, state_net_name, '-ml'), 'xyoNet')


%%
this_msg = 'Inference...';
disp(horzcat(this_msg))
tx1.String = this_msg;

xyo_net_vals = zeros(ntuples, 3);
for ntuple = 1:ntuples
    if ~rem(ntuple, round(ntuples/20))
        disp(num2str(ntuple/ntuples))
    end
    im = readimage(image_ds, ntuple);
    xyo_net_vals(ntuple, :) = predict(xyoNet, double(im));
end


%%
figure(6)

subplot(3,3,4)
histogram(xyo_net_vals(:,1))
axis tight
title('Estimated X')

subplot(3,3,5)
histogram(xyo_net_vals(:,2))
axis tight
title('Estimated Y')

subplot(3,3,6)
histogram(xyo_net_vals(:,3))
axis tight
title('Estimated O')

subplot(3,3,7)
scatter(this_x, xyo_net_vals(:,1))
axis tight
title('True vs Estimated X')

subplot(3,3,8)
scatter(this_y, xyo_net_vals(:,2))
axis tight
title('True vs Estimated Y')

subplot(3,3,9)
scatter(thetas, xyo_net_vals(:,3))
axis tight
title('True vs Estimated O')


%%
this_msg = 'Generating states from XYOs...';
disp(horzcat(this_msg))
% tx1.String = this_msg;

n_unique_states = init_n_unique_states;
states = zeros(ntuples, 1);
labels = cell(n_unique_states, 1);

xs = round(linspace(xlim1,xlim2,4));
ys = round(linspace(ylim1,ylim2,4));

for ntuple = 1:ntuples
    this_x = xyo_net_vals(ntuple, 1);
    this_y = xyo_net_vals(ntuple, 2);
    this_o = xyo_net_vals(ntuple, 3);

    if this_y <= ys(2)
        if this_x < xs(2)
            this_o_state = get_o_state(this_o);
            xyo_state = 0 + this_o_state;
            states(ntuple) = 1;
            labels{states(ntuple)} = horzcat('state ', num2str(states(ntuple)));
        elseif this_x < xs(3)
            this_o_state = get_o_state(this_o);
            xyo_state = 1 + this_o_state;            
        else
            this_o_state = get_o_state(this_o);
            xyo_state = 2 + this_o_state;      
        end
    elseif this_y < ys(3)
        if this_x < xs(2)
            this_o_state = get_o_state(this_o);
            xyo_state = 3 + this_o_state;
        elseif this_x < xs(3)
            this_o_state = get_o_state(this_o);
            xyo_state = 4 + this_o_state;            
        else
            this_o_state = get_o_state(this_o);
            xyo_state = 5 + this_o_state;      
        end
    else
        if this_x < xs(2)
            this_o_state = get_o_state(this_o);
            xyo_state = 6 + this_o_state;
        elseif this_x < xs(3)
            this_o_state = get_o_state(this_o);
            xyo_state = 7 + this_o_state;            
        else
            this_o_state = get_o_state(this_o);
            xyo_state = 8 + this_o_state;      
        end
    end
    if xyo_state == 0
        ntuple
        error('State = 0!')
    else
        states(ntuple) = xyo_state;
    end
end

save(horzcat(nets_dir_name, state_net_name, '-states'), 'states')
save(strcat(nets_dir_name, state_net_name, '-labels'), 'labels')
disp('XYO states generates')


%%
figure(17)
clf
set(gcf, 'position', [201 241 800 420], 'color', 'w')

histogram(states, 'binwidth', 0.4)
xlim([0 n_unique_states + 1])
title('States')


%% Torques
this_msg = 'Getting torques...';
disp(horzcat(this_msg))
tx1.String = this_msg;

get_torques
save(horzcat(nets_dir_name, state_net_name, '-torque_data'), 'torque_data')

this_msg = 'xyoNet and torques ready';
disp(horzcat(this_msg))
tx1.String = this_msg;