
%%%% Brainless %%%%


% Assumes brainless_prepare.m ran in runtime.m 


left_eye_frame = large_frame(left_cut(1):left_cut(2), left_cut(3):left_cut(4), :);
right_eye_frame = large_frame(right_cut(1):right_cut(2), right_cut(3):right_cut(4), :);

left_uframe = imresize(left_eye_frame, net_input_size);
right_uframe = imresize(right_eye_frame, net_input_size);

[left_featureVector, ~] = encode(bag, left_uframe, 'UseParallel', 0);
[right_featureVector, ~] = encode(bag, right_uframe, 'UseParallel', 0);
bl1_plt.YData = [left_featureVector right_featureVector];
drawnow

1

% this_frame = imresize(large_frame, [227 404]);
% xframe = imsubtract(rgb2gray(this_frame), rgb2gray(prev_frame));
% % xframe = imsubtract(rgb2gray(prev_frame), rgb2gray(this_frame));
% bl_frame1.CData = this_frame;
% 
% for ncol = 1:3
%     if ncol == 1
%         colframe = this_frame(:,:,1) > this_frame(:,:,2) * 1.5 & this_frame(:,:,1) > this_frame(:,:,3) * 1.5;
%         colframe(this_frame(:,:,1) < 125) = 0;
%         this_col = 'red';
%     elseif ncol == 2
%         colframe = this_frame(:,:,2) > this_frame(:,:,1) * 1.3 & this_frame(:,:,2) > this_frame(:,:,3) * 1.3;
%         colframe(this_frame(:,:,2) < 125) = 0;
%         this_col = 'green';
%     elseif ncol == 3
%         colframe = this_frame(:,:,3) > this_frame(:,:,2) * 1.4 & this_frame(:,:,3) > this_frame(:,:,1) * 1.4;
%         colframe(this_frame(:,:,3) < 125) = 0;
%         this_col = 'blue';
%     end
% 
%     blob = bwconncomp(colframe);
%     if blob.NumObjects
%         [i, j] = max(cellfun(@numel,blob.PixelIdxList));
%         npx = i;
% %         disp(horzcat(this_col, ' epsp = ', num2str(sigmoid(npx, 1000, 0.0075) * 50)))
%         [y, x] = ind2sub(blob.ImageSize, blob.PixelIdxList{j});
%         this_score = sigmoid(npx, 1000, 0.0075) * 50;
%         this_left_score = sigmoid(((404 - mean(x)) / 403), 0.85, 10) * this_score;
%         this_right_score = sigmoid(((mean(x)) / 403), 0.85, 10) * this_score;
%     else
%         this_score = 0;
%         this_left_score = 0;
%         this_right_score = 0;
%         x = [0 0 0];
%         y = [0 0 0];
%     end
% 
% %     if ncol == 1
% %         bl_plot1.XData = mean(x);
% %         bl_plot1.YData = this_score;
% %     elseif ncol == 2
% %         bl_plot2.XData = mean(x);
% %         bl_plot2.YData = this_score;
% %     elseif ncol == 3
% %         bl_plot3.XData = mean(x);
% %         bl_plot3.YData = this_score;
% %     end
% 
%     if ncol == 1
%         bl1_scr.XData = x;
%         bl1_scr.YData = y;
%     elseif ncol == 2
%         bl1_scg.XData = x;
%         bl1_scg.YData = y;
%     elseif ncol == 3
%         bl1_scb.XData = x;
%         bl1_scb.YData = y;        
%     end
% 
% %     if ncol == 1
% %         disp(horzcat('mean x = ', num2str(mean(x)), ', out = ', num2str(mean(x))))
% %     end
% 
% end
% 
% bwframe = xframe > 20;
% 
% blob = bwconncomp(bwframe);
% if blob.NumObjects
%     [i, j] = max(cellfun(@numel,blob.PixelIdxList));
%     npx = i;
% %     disp(horzcat('bright', ' epsp = ', num2str(sigmoid(npx, 1000, 0.0075) * 50)))
%     [y, x] = ind2sub(blob.ImageSize, blob.PixelIdxList{j});
%     this_score = sigmoid(npx, 1000, 0.0075) * 50;
%     this_left_score = sigmoid(((404 - mean(x)) / 403), 0.85, 10) * this_score;
%     this_right_score = sigmoid(((mean(x)) / 403), 0.85, 10) * this_score;
% else
%     this_score = 0;
%     this_left_score = 0;
%     this_right_score = 0;
%     x = [0 0 0];
%     y = [0 0 0];
% end
% 
% bl1_scbri.XData = x;
% bl1_scbri.YData = y;
% 
% prev_frame = this_frame; 

% if mean(x) > 0
%     dxvalues=1/16000:1/16000:pulse_period;
%     dxa = sin(2*pi*(100 + mean(x) * 3)*dxvalues);
%     dxa2 = ones(size(dxvalues));
%     dxa2(1:500) = dxa2(1:500) .* [0.002:0.002:1];
%     dxa2((end-499):end) = dxa2((end-499):end) .* [1:-0.002:0.002];             
%     dxa = dxa .* dxa2;
%     dxa = dxa * (this_score/50);
%     speaker_obj(dxa');
% end

% % %% Distance as number and sound
% if rak_only
%   rak_get_serial
%   disp(num2str(this_distance))
% end

% 
% if this_distance > 50 && this_distance < 5000
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
%         send_this = horzcat('l:', num2str(this_distance*0.5), ';', 'r:', num2str(this_distance*0.5),';', 's:', num2str(this_distance), ';');
%     end
% elseif rak_only
%     send_this = horzcat('l:', num2str(0), ';', 'r:', num2str(0),';', 's:', num2str(0), ';');
% end
% if rak_only
%     rak_cam.writeSerial(send_this)
%     disp(send_this)
% end
