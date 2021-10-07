
iis = 200;

vdata = zeros(3, 2, iis);
ddata = zeros(1, iis);
tdata = zeros(1, iis);

left_cut = [1 rak_cam_h 1 rak_cam_h]; 
right_cut = [1 rak_cam_h (rak_cam_w - rak_cam_h + 1) rak_cam_w];

left_eye_frame = large_frame(left_cut(1):left_cut(2), left_cut(3):left_cut(4), :);
right_eye_frame = large_frame(right_cut(1):right_cut(2), right_cut(3):right_cut(4), :);

rak_cam.writeSerial('l:35;r:-35;s:0;')

for ii = 1:iis
    
    tic
    disp(horzcat('nstep = ', num2str(ii)))
    
    % Vision
    large_frame = rak_cam.readVideo();
    large_frame = permute(reshape(large_frame, 3, rak_cam.readVideoWidth(), rak_cam.readVideoHeight()),[3,2,1]);    
    left_eye_frame = large_frame(left_cut(1):left_cut(2), left_cut(3):left_cut(4), :);
    right_eye_frame = large_frame(right_cut(1):right_cut(2), right_cut(3):right_cut(4), :);       
    process_visual_input
    vdata(:, :, ii) = vis_pref_vals([1 3 5],:);

    % Distance
    serial_receive = rak_cam.readSerial();
    ddata(ii) = serial_receive(3);

    while toc < 0.1
        pause(0.01)
    end
    tdata(ii) = toc;
    
end

rak_cam.writeSerial('l:0;r:0;s:0;')

red_data = squeeze(vdata(1,:,:))';
green_data = squeeze(vdata(2,:,:))';
blue_data = squeeze(vdata(3,:,:))';

[peaks, locs] = findpeaks(mean(red_data, 2), 'minpeakheight', 30);

%%
fig10 = figure(10);
clf
set(fig10, 'position', [330 250 1230 575]);


plot(mean(red_data, 2), 'color', 'r')
hold on
plot(mean(green_data, 2), 'color', 'g')
plot(mean(blue_data, 2), 'color', 'b')


