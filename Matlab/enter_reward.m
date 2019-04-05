
% If reward_button is pressed
if run_button == 5 || sum(da_rew_neurons(firing))
    run_button = 0;
    reward = 1;
end

if reward
%     col = [0.8 1 0.8];
%     button_reward.BackgroundColor = col;
%     status_ax.Color = col;
%     set(status_ax, 'xcolor', col, 'ycolor', col)
%     fig_design.Color = col;
%     if manual_controls
%         manual_control_title.BackgroundColor = col;
%     end

%     if isfield(brain, 'rewarded_frames')
%         nrewarded_frame = size(brain.rewarded_frames, 1) + 1;
%     else
%         brain.rewarded_frames = zeros(1, 720, 1280, 3, 'uint8');
%         nrewarded_frame = 2;
%     end
%     brain.rewarded_frames(nrewarded_frame, :, :, :) = large_frame;
    
%     disp(horzcat('Dopamine reward: ', num2str(reward)))
    
%     for ii = [1 0.8]
%         button_reward.BackgroundColor = [0.8 ii 0.8];
%         col = [(1.6- ii) 0.8 (1.6 - ii)] + 0.2;
%         status_ax.Color = col;
%         set(status_ax, 'xcolor', col, 'ycolor', col)
%         fig_design.Color = col;
%         if manual_controls
%             manual_control_title.BackgroundColor = col;
%         end          
%         pause(0.05)
%     end
end