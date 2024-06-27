
state_net_name = ml_name1_edit.String;

ml_get_data_stats
tx1.String = 'xyo alternative';

ext_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*ext_data.mat'));

ntuples = size(ext_dir, 1);

this_msg = horzcat('Getting ', num2str(ntuples), ' xyos');
disp(horzcat(this_msg))
tx1.String = this_msg;

ml_get_objective_xyo


%%
figure(6)
clf

subplot(3,3,1)
h1 = histogram(allx);
hold on
for ii = 1:4
    plot([xlims(ii) xlims(ii)], [0 max(h1.Values)], 'linewidth', 2, 'color', 'k')
    plot([mean(xlims(2:3)) mean(xlims(2:3))], [0 max(h1.Values)], 'linewidth', 2, 'color', 'r')
end
title('True X')

subplot(3,3,2)
h2 = histogram(ally);
hold on
for ii = 1:4
    plot([ylims(ii) ylims(ii)], [0 max(h2.Values)], 'linewidth', 2, 'color', 'k')
    plot([mean(ylims(2:3)) mean(ylims(2:3))], [0 max(h2.Values)], 'linewidth', 2, 'color', 'r')
end
title('True Y')

subplot(3,3,3)
histogram(thetas)
title('True O')

drawnow


%%
this_msg = 'Training...';
disp(horzcat(this_msg))

cv = cvpartition(ntuples,'HoldOut',0.05);
idx = cv.test;

x_train = allx(~idx);
x_test = allx(idx);
y_train = ally(~idx);
y_test = ally(idx);
o_train = thetas(~idx);
o_test = thetas(idx);

xyo_train = arrayDatastore([x_train y_train o_train]);
xyo_test = arrayDatastore([x_test y_test o_test]);

image_ds_train = subset(image_ds, ~idx);
image_ds_test = subset(image_ds, idx);

training_data = combine(image_ds_train, xyo_train);
test_data = combine(image_ds_test, xyo_test);

numResponses = 3;


%%

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
    ValidationData=test_data, ...
    ValidationFrequency=100, ...
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
    if ~rem(ntuple, round(ntuples/10))
        disp(horzcat(num2str(round(100*(ntuple/ntuples))), '%'))
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
scatter(allx, xyo_net_vals(:,1), 1)
axis tight
title('True vs Estimated X')

subplot(3,3,8)
scatter(ally, xyo_net_vals(:,2), 1)
axis tight
title('True vs Estimated Y')

subplot(3,3,9)
scatter(thetas, xyo_net_vals(:,3), 1)
axis tight
title('True vs Estimated O')

drawnow


%%
% this_msg = 'Generating states from XYOs...';
% disp(horzcat(this_msg))
% 
% n_unique_states = 32;
% states = zeros(ntuples, 1);
% 
% for ntuple = 1:ntuples
% 
%     %%% Estimated XYO
%     % this_x = xyo_net_vals(ntuple, 1);
%     % this_y = xyo_net_vals(ntuple, 2);
%     % this_o = xyo_net_vals(ntuple, 3);
% 
%     %%% Objective XYO
%     this_x = allx(ntuple, 1);
%     this_y = ally(ntuple, 1);
%     this_o = thetas(ntuple, 1);
% 
%     xyo_state = get_xyo_state(this_x, this_y, this_o, xlims, ylims, n_unique_states);
% 
%     states(ntuple) = xyo_state;
% 
% end
% 
% labels = cell(n_unique_states, 1);
% for nstate = 1:n_unique_states
%     labels{nstate} = horzcat('State ', num2str(nstate));
% end
% 
% save(horzcat(nets_dir_name, state_net_name, '-states'), 'states')
% save(strcat(nets_dir_name, state_net_name, '-labels'), 'labels')
% disp('XYO states generated')
% 
% 
% %%
% figure(17)
% clf
% set(gcf, 'position', [201 241 800 420], 'color', 'w')
% 
% histogram(states, 'binwidth', 0.4)
% xlim([0 n_unique_states + 1])
% title('States')
% 
% drawnow


%% Torques
this_msg = 'Getting torques...';
disp(horzcat(this_msg))

get_torques
raw_torque_data = torque_data;
clear torque_data
save(horzcat(nets_dir_name, state_net_name, '-raw_torque_data'), 'raw_torque_data')

this_msg = 'xyoNet and torques ready';
disp(horzcat(this_msg))