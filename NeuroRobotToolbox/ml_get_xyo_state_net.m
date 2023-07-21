
minmin = 100;

% image_ds = imageDatastore(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*.png'));
image_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*.png'));
ext_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*ext_data.mat'));
ntuples = size(ext_dir, 1);

x1 = 0;
y1 = 0;
x2 = 1;
y2 = 1;

thetas = zeros(ntuples, 1);
thetas2 = zeros(ntuples * 2, 1);
states = zeros(ntuples, 1);
robot_xys = zeros(ntuples, 2);
disp(horzcat('Getting ', num2str(ntuples), ' states from xyos'))

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
    thetas2(ntuple * 2 - 1 : ntuple * 2) = [theta theta];

%     this_n = 7;
%     this_range = linspace(0, 360, this_n);
% 
%     for ii = 1:this_n-1
%         if theta >= this_range(ii) && theta < this_range(ii+1)
%             states(ntuple) = ii;
%         end
%     end

%     if robot_xy(1) <= 173 && robot_xy(2) <= 107
% %         states(ntuple) = 1;
%     elseif robot_xy(1) > 173 && robot_xy(2) <= 107
%         states(ntuple) = states(ntuple) + this_n - 1;
%     elseif robot_xy(1) <= 173 && robot_xy(2) > 107
%         states(ntuple) = states(ntuple) + (this_n - 1) * 2;
%     elseif robot_xy(1) > 173 && robot_xy(2) > 107
%         states(ntuple) = states(ntuple) + (this_n - 1) * 3;
%     end

end


% 1



% n_unique_states = length(unique(states));
% disp(horzcat('n unique states: ', num2str(n_unique_states)))


% %%
% try
%     rmdir(strcat(workspace_dir_name, net_name), 's')
%     disp('Removed previous net')
% catch
%     disp(horzcat('Could not find or delete any previous training data for ', net_name))
% end
% 
% h = histogram(states);
% min_size = min([h.Values ,minmin]);
% disp(horzcat('Min size: ', num2str(min_size)))
% 
% for nstate = 1:n_unique_states
%     disp(horzcat('Processing state ', num2str(nstate)))
%     if nstate >= 100
%         this_dir = strcat('state_', num2str(nstate));
%     elseif nstate >= 10
%         this_dir = strcat('state_0', num2str(nstate));
%     else
%         this_dir = strcat('state_00', num2str(nstate));
%     end
%     mkdir(strcat(workspace_dir_name, net_name, '\', this_dir))
% 
%     these_inds = find(states == nstate);
%     these_inds_subset = randsample(these_inds, min_size);
% 
%     for nimage = 1:min_size
%         this_ind = these_inds_subset(nimage) * 2 - 1;    
%         left_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
%     
%         fname = strcat(workspace_dir_name, net_name, '\', this_dir, '\', 'im_left_', num2str(this_ind), '.png');
%         imwrite(left_im, fname);
%     
%         this_ind = these_inds_subset(nimage) * 2;
%         right_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
%     
%         fname = strcat(workspace_dir_name, net_name, '\', this_dir, '\', 'im_right_', num2str(this_ind), '.png');
%         imwrite(right_im, fname);
%     end
%     
% end


% %% Get labels
% labels = folders2labels(strcat(workspace_dir_name, net_name, '\'));
% labels = unique(labels);
% n_unique_states = length(labels);
% disp(horzcat('n unique states = ', num2str(n_unique_states)))


%% Train classifier net
% classifier_ds = imageDatastore(strcat(workspace_dir_name, net_name, '\'), 'FileExtensions', '.png', 'IncludeSubfolders', true, 'LabelSource','foldernames');
% imds = imageDatastore(strcat(workspace_dir_name, net_name, '\'),'FileExtensions','.png','IncludeSubfolders', true);
image_ds = imageDatastore(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*.png'));
tds = arrayDatastore(thetas2);
ds = combine(image_ds,tds);
% imds.ReadFcn = @customReadFcn; % imdim = 100

imdim = 227;

net = [
    imageInputLayer([imdim imdim 3])
    
    convolution2dLayer(3,32,'Padding','same')
    batchNormalizationLayer
    reluLayer
    
    maxPooling2dLayer(2,'Stride',2)
    
    convolution2dLayer(3,32,'Padding','same')
    batchNormalizationLayer
    reluLayer

    maxPooling2dLayer(2,'Stride',2)
    
    convolution2dLayer(3,16,'Padding','same')
    batchNormalizationLayer
    reluLayer
    
%     fullyConnectedLayer(200)
%     reluLayer

%     fullyConnectedLayer(200)
%     reluLayer
    
%     fullyConnectedLayer(n_unique_states)
%     softmaxLayer
%     classificationLayer];

    dropoutLayer(0.2)
    fullyConnectedLayer(1)
    regressionLayer];

if isdeployed
    this_str = 'none';
else
    this_str = 'training-progress';
end

options = trainingOptions('adam', ...
    'ExecutionEnvironment', 'auto', ...
    Plots=this_str, ...
    Shuffle ='every-epoch', ...
    MaxEpochs=5);

% options = trainingOptions("sgdm", ...
%     LearnRateSchedule="piecewise", ...
%     LearnRateDropFactor=0.5, ...
%     LearnRateDropPeriod=2, ...
%     MaxEpochs=10, ...
%     MiniBatchSize=256, ...
%     Plots="training-progress")

net = trainNetwork(ds, net, options);
save(strcat(nets_dir_name, net_name, '-net-ml'), 'net')

