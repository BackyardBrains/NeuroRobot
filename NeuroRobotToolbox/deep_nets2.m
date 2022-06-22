
close all
clear
clc

this_dir = '.\Data\Recording_1\';
imdim = 27;

img_ds = imageDatastore(strcat(this_dir, '*Helium*.png'));
nimgs = size(img_ds.Files, 1);
serials = dir(strcat(this_dir, '*Helium*serial_data.mat'));
nserials = size(serials, 1);

for nimg = 2:2:nimgs
    nimg/nimgs
    img_name = char(img_ds.Files(nimg));
    d1 = img_name(75:98);
    serial_name = serials(nimg/2).name;
    d2 = serial_name(1:24);
    if ~strcmp(d1, d2)
        1
    end
end


distance = zeros(nimgs, 1); % should be nserials*2 but its 2 shorter than nimgs 
images = zeros(imdim, imdim, 1, nimgs);

for nserial = 1:nserials
    if ~rem(nserial, round(nserials/10))
        disp(num2str(nserial/(nserials)))
    end    
    load(horzcat(this_dir, serials(nserial).name))
    for ii = 1:2
        this_im = readimage(img_ds, nserial*2-(ii-1));
        this_im = rgb2gray(this_im);
        this_im = imresize(this_im, [imdim imdim]);
        images(:,:,:,nserial*2-(ii-1)) = this_im;
        this_distance = str2double(serial_data{3});
        this_distance(this_distance >= 4000) = 0;
        distance(nserial*2-(ii-1)) = this_distance;        
    end
end

img_ds = arrayDatastore(images,IterationDimension=4);
dist_ds = arrayDatastore(distance);
final_ds = combine(img_ds, dist_ds);


options = trainingOptions("sgdm", ...
    LearnRateSchedule="piecewise", ...
    LearnRateDropFactor=0.2, ...
    LearnRateDropPeriod=5, ...
    MaxEpochs=20, ...
    MiniBatchSize=64, ...
    Plots="training-progress")
net = trainNetwork(images, layers_1, options)



