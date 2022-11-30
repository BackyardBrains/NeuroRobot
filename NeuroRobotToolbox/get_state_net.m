    
%% Get net

clear
clc

imdim = 227;
data_dir_name = '.\Datasets\';
rec_dir_name = 'Recordings\';
comb_img_dir_name = 'CombinedImages\';
net_dir_name = '.\Nets\';
image_dir = dir(fullfile(data_dir_name, rec_dir_name, '**\*.png'));
nimages = length(image_dir);
ntuples = nimages/2;

%% Combine eye frames to large frame
% disp('Combining eye frames to large frames...')
% new_frame = zeros(227, 404, 3, 'uint8');
% for ntuple = 1:ntuples
%     if ~rem(ntuple, round(ntuples/20))
%         disp(horzcat(num2str(round(20*(ntuple/ntuples))), ' %'))
%     end
%     this_ind = ntuple*2-1;
%     left_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
%     this_ind = ntuple*2;
%     right_im = imread(strcat(image_dir(this_ind).folder, '\',  image_dir(this_ind).name));
%     new_frame(:, 1:227, :) = left_im;
%     new_frame(:, 178:404, :) = right_im;    
%     fname = strcat(data_dir_name, comb_img_dir_name, image_dir(this_ind).name(1:end-16), 'uframe.png');
%     imwrite(new_frame, fname);
% end

image_ds = imageDatastore(strcat(data_dir_name, comb_img_dir_name), 'FileExtensions', '.png', 'IncludeSubfolders', 1);
image_ds.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually - This is where some images get saved small

ext_data_dir = dir(fullfile(data_dir_name, rec_dir_name, '**\*ext_data.mat'));
serial_dir = dir(fullfile(data_dir_name, rec_dir_name, '**\*serial_data.mat'));

ntuples = size(ext_data_dir, 1);

ps = parallel.Settings;
ps.Pool.AutoCreate = false;
ps.Pool.IdleTimeout = Inf;

%% Get dists
% dists = zeros(ntuples, 1);
% disp(horzcat('Getting ', num2str(ntuples), ' distances'))
% for ntuple = 1:ntuples
%     if ~rem(ntuple, round(ntuples/5))
%         disp(horzcat(num2str(round(100*(ntuple/ntuples))), ' %'))
%     end
%     serial_fname = horzcat(serial_dir(ntuple).folder, '\', serial_dir(ntuple).name);
%     load(serial_fname)
%     this_distance = str2double(serial_data{3});
%     this_distance(this_distance == Inf) = 0;    
%     dists(ntuple, :) = this_distance;
% end
% save(strcat(data_dir_name, 'dists'), dists)


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
save(strcat(data_dir_name, 'robot_xy_data'), robot_xy_data)
save(strcat(data_dir_name, 'rblob_xy_data'), rblob_xy_data)
save(strcat(data_dir_name, 'gblob_xy_data'), gblob_xy_data)

%% Get states
states = zeros(ntuples, 1);
for ntuple = 1:ntuples
    if ~rem(ntuple, round(ntuples/5))
        disp(horzcat(num2str(round(100*(ntuple/ntuples))), ' %'))
    end    
    rbox = robot_xy_data(ntuple, 1);
    rboy = robot_xy_data(ntuple, 2);
    gx = gblob_xy_data(ntuple, 1);
    gy = gblob_xy_data(ntuple, 2);
    rx = rblob_xy_data(ntuple, 1);
    ry = rblob_xy_data(ntuple, 2);

    if rbox < 202
        xx = 1;
    elseif rbox >= 202
        xx = 2;
    end

    if rboy < 114
        yy = 1;
    elseif rboy >= 114
        yy = 2;
    end

    if gx <= rx && gy <= ry
        oo = 1;
    elseif gx > rx && gy <= ry
        oo = 2;
    elseif gx > rx && gy > ry
        oo = 3;
    elseif gx <= rx && gy > ry
        oo = 4;
    end

    if yy == 1
        if xx == 1
            if oo == 1
                states(ntuple) = 1;
            elseif oo == 2
                states(ntuple) = 2;
            elseif oo == 3
                states(ntuple) = 3;
            elseif oo == 4
                states(ntuple) = 4;
            end
        elseif xx == 2
            if oo == 1
                states(ntuple) = 5;
            elseif oo == 2
                states(ntuple) = 6;
            elseif oo == 3
                states(ntuple) = 7;
            elseif oo == 4
                states(ntuple) = 8;
            end
        end
    elseif yy == 2
        if xx == 1
            if oo == 1
                states(ntuple) = 9;
            elseif oo == 2
                states(ntuple) = 10;
            elseif oo == 3
                states(ntuple) = 11;
            elseif oo == 4
                states(ntuple) = 12;
            end
        elseif xx == 2
            if oo == 1
                states(ntuple) = 13;
            elseif oo == 2
                states(ntuple) = 14;
            elseif oo == 3
                states(ntuple) = 15;
            elseif oo == 4
                states(ntuple) = 16;
            end
        end
    end
end
n_unique_states = 16;

%%
h = histogram(states, 'binwidth', 1);
min_size = min(h.Values);
disp(horzcat('min size: ', num2str(min_size)))
state_inds = zeros(n_unique_states, min_size);
for nstate = 1:n_unique_states
    these_inds = find(states == nstate);
    if length(these_inds) >= min_size
        these_inds_subset = randsample(these_inds, min_size);
        state_inds(nstate, :) = these_inds_subset;
    end
end

%%
for nstate = 1:n_unique_states
    disp(horzcat('Processing state ', num2str(nstate)))
    if nstate >= 100
        this_dir = strcat('state_', num2str(nstate));
    elseif nstate >= 10
        this_dir = strcat('state_0', num2str(nstate));
    else
        this_dir = strcat('state_00', num2str(nstate));
    end
    mkdir(strcat(data_dir_name, 'Classifier\', this_dir))
    for nimage = 1:min_size
        this_ind = state_inds(nstate, nimage);
        this_im = readimage(image_ds, this_ind);
        fname = strcat(data_dir_name, 'Classifier\', this_dir, '\', 'im', num2str(this_ind), '.png');
        imwrite(this_im, fname);
    end
end

%%
labels = folders2labels(strcat(data_dir_name, 'Classifier\'));
labels = unique(labels);
save(strcat(net_dir_name, 'LivingRoomLabels'), 'labels')


%%
classifier_ds = imageDatastore(strcat(data_dir_name, 'Classifier\'), 'FileExtensions', '.png', 'IncludeSubfolders', true, 'LabelSource','foldernames');
classifier_ds.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually

disp('Creating neural network...')
layers = [
    imageInputLayer([imdim 404 3], Normalization="none")
    
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
disp('Ready to train')


%% Train net
disp('Training neural network...')

% options = trainingOptions("sgdm", 'ExecutionEnvironment', 'auto', ...
%     MaxEpochs=20, Plots="training-progress", Shuffle ='every-epoch', ...
%     LearnRateSchedule='piecewise', LearnRateDropPeriod = 1, Verbose=1);

options = trainingOptions('adam', 'ExecutionEnvironment', 'auto', ...
    Plots="training-progress", Shuffle ='every-epoch', MaxEpochs=20, ...
    Verbose=1);

net = trainNetwork(classifier_ds,lgraph,options);
save(strcat(net_dir_name, 'LivingRoomNet'), 'net')

disp('Neural network ready')


%% Test net

figure(3)
clf

flag = 0;
while ~flag
    this_ind = randsample(ntuples, 1);
    this_im = readimage(image_ds, this_ind);
    % this_im = imresize(this_im, [imdim imdim]);
    [cat, score] = classify(net, this_im);
    cat_str = char(cat);
    cat_str(cat_str=='_') = [];
    this_im = imresize(this_im, [imdim 404]*2);
    imshow(this_im)
    title(horzcat('frame = ', num2str(this_ind), ', cat = ', cat_str))
    drawnow
    pause
end
