
%%

close all
clear
clc

rootdir = '.\Data\';

filelist1 = dir(fullfile(rootdir, '**\*.png'));  %get list of files and folders in any subfolder
filelist2 = dir(fullfile(rootdir, '**\*serial_data.mat'));  %get list of files and folders in any subfolder
filelist3 = dir(fullfile(rootdir, '**\*torques.mat'));  %get list of files and folders in any subfolder

nfiles1 = size(filelist1, 1);
nfiles2 =  size(filelist2, 1);

distance = zeros(nfiles2, 1);
state = zeros(nfiles2, 1);

folders = folders2labels(rootdir);
folders = unique(folders);
nstates = length(unique(folders));

for nfile2 = 1:nfiles2
    if ~rem(nfile2, round(nfiles2/10))
        disp(num2str(nfile2/(nfiles2)))
    end    
%     load(horzcat(filelist2(nfile2).folder, '\', filelist2(nfile2).name))  % robot 15 doesn't record serial, tru agaon
    for ii = 1:2

        this_str1 = filelist2(nfile2).folder(end-2:end);
        this_state = [];
        if strcmp(this_str1(1), '\')
            this_str1(1) = [];
        end        
        for nstate = 1:nstates         
            this_str2 = char(folders(nstate));
            if strcmp(this_str1, this_str2)
                this_state = nstate;
            end
        end
        if isempty(this_state)
            error
        end

%         this_im = imread(strcat(filelist1(nfile2*2-(ii-1)).folder, '\',  filelist1(nfile2*2-(ii-1)).name));
%         this_im = imresize(this_im, 'outputsize', [50 50]);

        this_val = nfile2*2-(ii-1);
        if this_val < 10
            zeropad = '000';
        elseif this_val < 100
            zeropad = '00';
        elseif this_val < 1000
            zeropad = '0';
        else
            zeropad = '';
        end
        
%         images(:,:,:,nfile2*2-(ii-1)) = this_im;
%         images{nfile2*2-(ii-1)} = horzcat(filelist2(nfile2).folder, '\', filelist2(nfile2).name);
        fname = strcat('.\DeepTest\', zeropad, num2str(this_val), '.png');
%         imwrite(this_im, fname);
%         this_distance = str2double(serial_data{3});
%         this_distance(this_distance >= 4000) = 0;
%         distance(nfile2*2-(ii-1)) = this_distance; 

        distance(nfile2*2-(ii-1)) = rand; % robot 15 doesn't record serial, tru agaon
        state(nfile2*2-(ii-1)) = this_state;

    end
%     disp(num2str(nfile2))
end

%%
dist_ds = arrayDatastore(distance);

% img_ds = imageDatastore('.\DeepTest\*.png');
img_ds = imageDatastore(rootdir, ...
    'IncludeSubfolders',true,'LabelSource','foldernames');

nimgs = size(img_ds.Files, 1);

img_ds.ReadFcn = @customReadFcn; % Must add imdim to customReadFcn manually
% final_ds = combine(dist_ds, img_ds);


%% build net
filterSize = 5;
numFilters = 16;

layers = [
    imageInputLayer([50 50 3],Normalization="none")
    convolution2dLayer(filterSize,numFilters)
    batchNormalizationLayer
    reluLayer
    fullyConnectedLayer(50)
    flattenLayer
    concatenationLayer(1,2,Name="cat")
    fullyConnectedLayer(nstates)
    softmaxLayer
    classificationLayer];

lgraph = layerGraph(layers);

% featInput = featureInputLayer(1,Name="features",Normalization="none");
% lgraph = addLayers(lgraph,featInput);
% lgraph = connectLayers(lgraph,"features","cat/in2");

plot(lgraph)

%%
% options = trainingOptions("adam", Plots="training-progress")

options = trainingOptions("sgdm", ...
    LearnRateSchedule="piecewise", ...
    LearnRateDropFactor=0.2, ...
    LearnRateDropPeriod=5, ...
    MaxEpochs=20, ...
    MiniBatchSize=64, ...
    Plots="training-progress")

net = trainNetwork(img_ds, layers_2, options)

