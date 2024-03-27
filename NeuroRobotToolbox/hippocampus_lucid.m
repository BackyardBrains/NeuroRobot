
%% Lucid dream Hippocampus

close all
clear

data_dir_name = 'C:\SpikerBot\Temp\';
rec_dir_name = '';

image_dir = dir(fullfile(strcat(data_dir_name, rec_dir_name), '**\*large_frame_x.jpg'));
serial_dir = dir(fullfile(strcat(data_dir_name, rec_dir_name), '**\*serial.txt'));
torque_dir = dir(fullfile(strcat(data_dir_name, rec_dir_name), '**\*torque.txt'));

nimages = size(image_dir, 1);
ndists = size(serial_dir, 1);
ntorques = size(torque_dir, 1);
ntuples = nimages;

disp(horzcat('nimages: ', num2str(nimages)))
disp(horzcat('ndists:',  num2str(ndists)))
disp(horzcat('ntorques:' , num2str(ntorques)))
disp(horzcat('ntuples: ', num2str(ntuples)))


%% Prepare
figure(6)
clf
set(gcf, 'position', [80 80 1320 600], 'color', 'w')
ax1 = axes('position', [0.05 0.1 0.4 0.85]);
im1 = image(zeros(240, 320, 3, 'uint8'));
set(gca, 'xtick', [], 'ytick', [])
tx1 = title('');
ax2 = axes('position', [0.55 0.1 0.4 0.85]);
im2 = image(zeros(240, 320, 3, 'uint8'));
set(gca, 'xtick', [], 'ytick', [])
tx2 = title('');
ax3 = axes('position', [0.3 0.025 0.4 0.05], 'xcolor', 'w', 'ycolor', 'w');
plot([0 10], [0 10], 'color', 'w')
set(gca, 'xtick', [], 'ytick', [], 'xcolor', 'w', 'ycolor', 'w')
tx3 = text(5, 5, '', 'HorizontalAlignment','center', 'VerticalAlignment', 'middle');


%%
data1 = zeros(ntuples,1);
data2 = zeros(ntuples,2);
counter = 0;

for ntuple = 1:ntuples-5

    counter = counter + 1;

    im_l = imread(strcat(image_dir(ntuple).folder, '\',  image_dir(ntuple).name));
    im1.CData = im_l;
 
    im_r = imread(strcat(image_dir(ntuple+5).folder, '\',  image_dir(ntuple+5).name));
    im2.CData = im_r;

    im_x = im_l - im_r;
    im_y = im_x.^2;
    im_z = sum(im_y(:));
    data1(counter, :) = im_z;

    torque_fname = horzcat(torque_dir(ntuple).folder, '\', torque_dir(ntuple).name);
    raw_torques = readtable(torque_fname);

    this_motor_vector = [0 0];

    if ~isempty(raw_torques)
        torque_str = char(raw_torques.Var1);
        semis = strfind(torque_str, ';');
        l_str = torque_str(3:semis(1)-1);
        r_str = torque_str(semis(1)+3:semis(2)-1);   
        l_int = str2double(l_str);
        r_int = str2double(r_str);
        this_motor_vector = [l_int r_int];

        this_motor_vector = fliplr(this_motor_vector);
        this_motor_vector(2) = -this_motor_vector(2);

        tx3.String = horzcat('ntuple: ', num2str(ntuple), ...
            ', left torque: ', num2str(this_motor_vector(1)), ...
            ', right torque: ', num2str(this_motor_vector(2)));
    end
    
    data2(counter, :) = this_motor_vector;

    drawnow

    pause

end

