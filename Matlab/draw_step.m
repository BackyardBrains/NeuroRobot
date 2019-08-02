

% Draw the activity front
vplot_front.XData = [nstep nstep] * ms_per_step;

% Update second screen analysis
if second_screen_analysis
    
%     % Original
%     draw_analysis_1(1).YData = vis_pref_vals(:,1);
%     draw_analysis_1(2).YData = vis_pref_vals(:,2);
    
    % Edited
    draw_analysis_1.YData = audio_I;
    
    % Original
%     if exist('I', 'var')
%         draw_analysis_2.YData = I;
%     end
    
    % Edited
    if sum(pw) && length(pw) == 1000 
        draw_analysis_2.YData = pw;
    else
        disp('empty or wrong length pw (in draw step)')
        disp(horzcat('length pw = ', num2str(length(pw))))
    end
    
    draw_analysis_3.YData = [motor_command(1) * sign(1.5 - motor_command(2)) motor_command(3) * sign(1.5 - motor_command(4))];
%     draw_analysis_3.YData = pw3;
    
end