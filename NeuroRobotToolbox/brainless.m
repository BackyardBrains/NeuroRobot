
%%%% Brainless %%%%

%% Visual line - before first run only
% figure(5)
% clf
% this_frame = zeros(227, 404, 3, 'uint8');
% bl_ax1 = subplot(2,1,2);
% bl_frame1 = image(this_frame);
% bl_ax2 = subplot(2,1,1);
% bl_plot1 = plot(1,1,'r', 'marker', '.', 'markersize', 30);
% hold on
% bl_plot2 = plot(1,1,'color',[0 0.7 0], 'marker', '.', 'markersize', 30);
% bl_plot3 = plot(1,1,'color','b', 'marker', '.', 'markersize', 30);
% xlim([1 404])
% ylim([0 50])

%% Visual line - every run
this_frame = imresize(large_frame, 0.315);
bl_frame1.CData = this_frame;

for ncol = 1:3
    if ncol == 1
        colframe = this_frame(:,:,1) > this_frame(:,:,2) * 1.8 & this_frame(:,:,1) > this_frame(:,:,3) * 1.8;
        colframe(this_frame(:,:,1) < 50) = 0;
    elseif ncol == 2
        colframe = this_frame(:,:,2) > this_frame(:,:,1) * 1.2 & this_frame(:,:,2) > this_frame(:,:,3) * 1.2;
        colframe(this_frame(:,:,2) < 50) = 0;
    elseif ncol == 3
        colframe = this_frame(:,:,3) > this_frame(:,:,2) * 1.5 & this_frame(:,:,3) > this_frame(:,:,1) * 1.5;
        colframe(this_frame(:,:,3) < 50) = 0;            
    end

    blob = bwconncomp(colframe);
    if blob.NumObjects
        [i, j] = max(cellfun(@numel,blob.PixelIdxList));
        npx = i;
        [y, x] = ind2sub(blob.ImageSize, blob.PixelIdxList{j});
        this_score = sigmoid(npx, 1000, 0.0075) * 50;
        this_left_score = sigmoid(((404 - mean(x)) / 403), 0.85, 10) * this_score;
        this_right_score = sigmoid(((mean(x)) / 403), 0.85, 10) * this_score;
    else
        this_score = 0;
        this_left_score = 0;
        this_right_score = 0;
        x = [0 0 0];
    end

    if ncol == 1
        bl_plot1.XData = mean(x);
        bl_plot1.YData = this_left_score;
    elseif ncol == 2
        bl_plot2.XData = mean(x);
        bl_plot2.YData = this_left_score;
    elseif ncol == 3
        bl_plot3.XData = mean(x);
        bl_plot3.YData = this_left_score;
    end
end


% %% Distance as number and sound
% rak_get_serial
% disp(num2str(this_distance))
% 
% if this_distance > 50 && this_distance < 2000
%     disp(horzcat('distance = ', num2str(this_distance)))
%     if matlab_speaker_ctrl && exist('speaker_obj', 'var')
%         dxvalues=1/16000:1/16000:pulse_period;
%         dxa = sin(2*pi*this_distance*dxvalues);
%         dxa2 = ones(size(dxvalues));
%         dxa2(1:500) = dxa2(1:500) .* [0.002:0.002:1];
%         dxa2((end-499):end) = dxa2((end-499):end) .* [1:-0.002:0.002];             
%         dxa = dxa .* dxa2;
%         speaker_obj(dxa');
%     elseif rak_only
%         send_this = horzcat('l:', num2str(0), ';', 'r:', num2str(0),';', 's:', num2str(this_distance), ';');
%     end
% elseif rak_only
%     send_this = horzcat('l:', num2str(0), ';', 'r:', num2str(0),';', 's:', num2str(0), ';');
% end
% if rak_only
%     rak_cam.writeSerial(send_this)
% end

