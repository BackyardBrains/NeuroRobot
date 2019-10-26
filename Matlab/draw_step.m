
% Draw the activity front
vplot_front.XData = [nstep nstep] * ms_per_step;

% Draw audio spectrum
draw_audio.YData = pw(1:250);

% Update second screen analysis
if second_screen_analysis
    
%     draw_analysis_1(1).YData = vis_pref_vals(:,1);
%     draw_analysis_1(2).YData = vis_pref_vals(:,2);
    draw_analysis_1.YData = audio_I;    
%     if exist('I', 'var')
%         draw_analysis_2.YData = I;
%     end
    draw_analysis_2.YData = pw(101:500);    
    draw_analysis_3.YData = [motor_command(1) * sign(1.5 - motor_command(2)) motor_command(3) * sign(1.5 - motor_command(4))];
    
end
