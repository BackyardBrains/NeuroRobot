
%%%% Brainless %%%%

svf = 1;
% figure(5)
% clf
% this_frame = zeros(227, 404, 3, 'uint8');
% bl_ax1 = subplot(2,1,1);
% bl_frame1 = image(this_frame);
% bl_ax2 = subplot(2,1,2);
% bl_plot1 = plot(sum(mean(this_frame), 3));
% xlim([1 404])

%% Frame
this_frame = imresize(large_frame, 0.315);
this_frame = single(this_frame);

%% Red
red = this_frame(:,:,1) > this_frame(:,:,2) * 1.8 & this_frame(:,:,1) > this_frame(:,:,3) * 1.8;
red(this_frame(:,:,1) < 50) = 0;
blob = bwconncomp(red);
if blob.NumObjects
    [i, j] = max(cellfun(@numel,blob.PixelIdxList));
    npx = i;
    [y, x] = ind2sub(blob.ImageSize, blob.PixelIdxList{j});
    red_max = sigmoid(npx, 1000, 0.01) * 50;
    if npx > 1
        red_loc = mean(x);
    else
        red_loc = x; 
    end
else
    red_max = 0;
    red_loc = 202;
end


%% Green
green = this_frame(:,:,2) > this_frame(:,:,1) * 1.2 & this_frame(:,:,2) > this_frame(:,:,3) * 1.2;
green(this_frame(:,:,2) < 50) = 0;
blob = bwconncomp(green);
if blob.NumObjects
    [i, j] = max(cellfun(@numel,blob.PixelIdxList));
    npx = i;
    [y, x] = ind2sub(blob.ImageSize, blob.PixelIdxList{j});
    green_max = sigmoid(npx, 1000, 0.01) * 50;
    if npx > 1
        green_loc = mean(x);
    else
        green_loc = x; 
    end    
else
    green_max = 0;
    green_loc = 202;
end

%% Blue
blue = this_frame(:,:,3) > this_frame(:,:,2) * 1.5 & this_frame(:,:,3) > this_frame(:,:,1) * 1.5;
blue(this_frame(:,:,3) < 50) = 0;
blob = bwconncomp(blue);
if blob.NumObjects
    [i, j] = max(cellfun(@numel,blob.PixelIdxList));
    npx = i;
    [y, x] = ind2sub(blob.ImageSize, blob.PixelIdxList{j});
    blue_max = sigmoid(npx, 1000, 0.01) * 50;
    if npx > 1
        blue_loc = mean(x);
    else
        blue_loc = x; 
    end    
else
    blue_max = 0;
    blue_loc = 202;
end


%% Sensorimotor transform

left_motor = ((sigmoid(green_loc, 404 * 0.5, 0.015)) * 2 - 1) * green_max;
right_motor = -((sigmoid(green_loc, 404 * 0.5, 0.015)) * 2 - 1) * green_max;

% left_motor = (green_loc * 0.5 - 100) * green_max * 0.018;
% right_motor = (green_loc * -0.5 + 100) * green_max * 0.018;




% disp(horzcat('green_loc = ', num2str(green_loc), ...
%     ', green_max = ', num2str(green_max), ...
%     ', left_motor = ', num2str(left_motor), ...
%     ', right_motor = ', num2str(right_motor)))
% 
% send_this = horzcat('l:', num2str(left_motor), ';', 'r:', num2str(right_motor),';', 's:', num2str(0), ';');
% 
% if rak_only
%     rak_cam.writeSerial(send_this)
% elseif use_esp32
%     esp32WebsocketClient.send(send_this)
% end



if svf
    this_frame = imresize(large_frame, 0.315);
    bl_frame1.CData = this_frame;
    bl_plot1.YData = sum(mean(this_frame), 3);
end
