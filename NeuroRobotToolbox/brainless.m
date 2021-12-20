
%%%% Brainless %%%%

%% Visual line - before first run only
% first_visual_line

%% Visual line - every run
this_frame = imresize(large_frame, [227 404]);
bl_frame1.CData = this_frame;

for ncol = 1:3
    if ncol == 1
        colframe = this_frame(:,:,1) > this_frame(:,:,2) * 1.5 & this_frame(:,:,1) > this_frame(:,:,3) * 1.5;
        colframe(this_frame(:,:,1) < 125) = 0;
        this_col = 'r';
    elseif ncol == 2
        colframe = this_frame(:,:,2) > this_frame(:,:,1) * 1.3 & this_frame(:,:,2) > this_frame(:,:,3) * 1.3;
        colframe(this_frame(:,:,2) < 125) = 0;
        this_col = 'g';
    elseif ncol == 3
        colframe = this_frame(:,:,3) > this_frame(:,:,2) * 1.4 & this_frame(:,:,3) > this_frame(:,:,1) * 1.4;
        colframe(this_frame(:,:,3) < 125) = 0;
        this_col = 'b';
    end

    blob = bwconncomp(colframe);
    if blob.NumObjects
        [i, j] = max(cellfun(@numel,blob.PixelIdxList));
        npx = i;
%         disp(horzcat(this_col, ' epsp = ', num2str(sigmoid(npx, 1000, 0.0075) * 50)))
        [y, x] = ind2sub(blob.ImageSize, blob.PixelIdxList{j});
        this_score = sigmoid(npx, 1000, 0.0075) * 50;
%         if ncol == 1
%             disp(num2str(this_score))
%         end
        this_left_score = sigmoid(((404 - mean(x)) / 403), 0.85, 10) * this_score;
        this_right_score = sigmoid(((mean(x)) / 403), 0.85, 10) * this_score;
    else
        this_score = 0;
        this_left_score = 0;
        this_right_score = 0;
        x = [0 0 0];
        y = [0 0 0];
    end

%     if ncol == 1
%         bl_plot1.XData = mean(x);
%         bl_plot1.YData = this_score;
%     elseif ncol == 2
%         bl_plot2.XData = mean(x);
%         bl_plot2.YData = this_score;
%     elseif ncol == 3
%         bl_plot3.XData = mean(x);
%         bl_plot3.YData = this_score;
%     end

    if ncol == 1
        bl1_scr.XData = x;
        bl1_scr.YData = y;
    elseif ncol == 2
        bl1_scg.XData = x;
        bl1_scg.YData = y;
    elseif ncol == 3
        bl1_scb.XData = x;
        bl1_scb.YData = y;        
    end

end

bwframe = rgb2gray(this_frame);
bwframe(bwframe < 125) = 0;

% tic
blob = bwconncomp(bwframe);
% disp(num2str(toc))
if blob.NumObjects
    [i, j] = max(cellfun(@numel,blob.PixelIdxList));
    npx = i;
%     disp(horzcat(this_col, ' epsp = ', num2str(sigmoid(npx, 1000, 0.0075) * 50)))
    [y, x] = ind2sub(blob.ImageSize, blob.PixelIdxList{j});
    this_score = sigmoid(npx, 1000, 0.0075) * 50;
    this_left_score = sigmoid(((404 - mean(x)) / 403), 0.85, 10) * this_score;
    this_right_score = sigmoid(((mean(x)) / 403), 0.85, 10) * this_score;
else
    this_score = 0;
    this_left_score = 0;
    this_right_score = 0;
    x = [0 0 0];
    y = [0 0 0];
end

bl1_scbri.XData = x;
bl1_scbri.YData = y;

%% Distance as number and sound
rak_get_serial
disp(num2str(this_distance))

if this_distance > 50 && this_distance < 5000
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
        send_this = horzcat('l:', num2str(this_distance*0.5), ';', 'r:', num2str(this_distance*0.5),';', 's:', num2str(this_distance), ';');
    end
elseif rak_only
    send_this = horzcat('l:', num2str(0), ';', 'r:', num2str(0),';', 's:', num2str(0), ';');
end
if rak_only
    rak_cam.writeSerial(send_this)
    disp(send_this)
end
