

%% Get base net
if ~exist('vnet', 'var')
    % anet = alexnet;
    vnet = vgg19;
end


% %% Get data
image_dir_name = 'C:\Users\chris\OneDrive\Documents\MATLAB\Selected\office\';
image_dir2_name = 'C:\Users\chris\OneDrive\Documents\MATLAB\Selected\office2\';

image_dir = dir(horzcat(image_dir2_name, '*.png'));
nims = size(image_dir, 1);
disp(horzcat('nims: ', num2str(nims)))


%% Resize
% for nim = 1:nims
%     this_im = strcat(image_dir_name, '\',  image_dir(nim).name);
%     im = imread(this_im);
%     k = imresize(im, 0.5);
%     newfilename = strcat(image_dir2_name, '\',  image_dir(nim).name);
%     imwrite(k, newfilename, 'png');
%     disp(num2str(nim))
% end


%% Label images manually
% imageLabeler(image_dir2_name)


%% Save
% save('office_gTruth', 'office_gTruth')


%% Train net
load('office_gTruth')

trainingData = objectDetectorTrainingData(office_gTruth);

% Net
layers = [
    imageInputLayer([120 160 3])
    convolution2dLayer(3, 16)
    reluLayer  
    convolution2dLayer(3, 8)
    reluLayer     
    maxPooling2dLayer(2,'Stride',2)
    fullyConnectedLayer(400)
    reluLayer 
    fullyConnectedLayer(300)
    reluLayer     
    fullyConnectedLayer(2)
    softmaxLayer()
    classificationLayer()
    ];

% try adam optimizer
options = trainingOptions('sgdm', ...
    'MiniBatchSize', 32, ...
    'InitialLearnRate', 1e-5, ...
    'MaxEpochs', 5, ...
    'verbosefrequency', 5, ...
    'plots', 'training-progress');

rcnn = trainRCNNObjectDetector(trainingData, layers, options);

save(horzcat(nets_dir_name, 'rcnn'), 'rcnn')

