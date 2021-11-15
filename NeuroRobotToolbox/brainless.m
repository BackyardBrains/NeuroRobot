
%%%% Brainless %%%%

% figure(5)
% clf
% this_frame = zeros(227, 404, 3, 'uint8');
% bl_ax1 = subplot(2,1,1);
% bl_frame1 = image(this_frame);
% bl_ax2 = subplot(2,1,2);
% bl_plot1 = plot(sum(mean(this_frame), 3));
% xlim([1 404])

% this_frame = imresize(large_frame, 0.315);
% bl_frame1.CData = this_frame;
% bl_plot1.YData = sum(mean(this_frame), 3);

rak_get_serial
disp(num2str(this_distance))
            
if this_distance > 50 && this_distance < 2000
    disp(horzcat('distance = ', num2str(this_distance)))
    if matlab_speaker_ctrl && exist('speaker_obj', 'var')
        dxvalues=1/16000:1/16000:pulse_period;
        dxa = sin(2*pi*this_distance*dxvalues);
        dxa2 = ones(size(dxvalues));
        dxa2(1:500) = dxa2(1:500) .* [0.002:0.002:1];
        dxa2((end-499):end) = dxa2((end-499):end) .* [1:-0.002:0.002];             
        dxa = dxa .* dxa2;
        speaker_obj(dxa');
    elseif rak_only
        send_this = horzcat('l:', num2str(0), ';', 'r:', num2str(0),';', 's:', num2str(this_distance), ';');
    end
elseif rak_only
    send_this = horzcat('l:', num2str(0), ';', 'r:', num2str(0),';', 's:', num2str(0), ';');
end
if rak_only
    rak_cam.writeSerial(send_this)
end

