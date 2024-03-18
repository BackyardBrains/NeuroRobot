

%%

clc
format long

dataset_dir_name = 'C:\SpikerBot\Datasets\Flutter\';
rec_dir_name = 'Livingroom\';

disp('Indexing datasets...')
image_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*_x.jpg'));
serial_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*serial.txt'));
torque_dir = dir(fullfile(strcat(dataset_dir_name, rec_dir_name), '**\*torque.txt'));

nimages = size(image_dir, 1);
nserials = size(serial_dir, 1);
ntorques = size(torque_dir, 1);
ntuples = nimages;


%% Ims
ims = zeros(nimages, 1);
for nimage = 1:nimages
    if ~rem(nimage + 1, round(nimages/5))
        disp(horzcat(num2str(round(100*(nimage/nimages))), '%, ntuple: ', num2str(nimage)))
    end    
    xfile = image_dir(nimage).name;
    ims(nimage, :) = str2double(xfile(21:33));
end


%% Serials
serials = zeros(nserials, 1);
for nserial = 1:nserials
    if ~rem(nserial + 1, round(nserials/5))
        disp(horzcat(num2str(round(100*(nserial/nserials))), '%, ntuple: ', num2str(nserial)))
    end    
    xfile = serial_dir(nserial).name;
    serials(nserial, :) = str2double(xfile(21:33));
end


%% Torques
torques = zeros(ntorques, 1);
for ntorque = 1:ntorques
    if ~rem(ntorque + 1, round(ntorques/5))
        disp(horzcat(num2str(round(100*(ntorque/ntorques))), '%, ntuple: ', num2str(ntorque)))
    end
    xfile = torque_dir(ntorque).name;
    torques(ntorque, :) = str2double(xfile(21:33));
end


%%

pool = [ims; serials; torques];
uniques = unique(pool);
nuniques = length(uniques);

disp(horzcat('nimages = ', num2str(nimages)))
disp(horzcat('nserials = ', num2str(nserials)))
disp(horzcat('ntorques = ', num2str(ntorques)))
disp(horzcat('ntuples = ', num2str(nimages)))
disp(horzcat('nuniques = ', num2str(nuniques)))




