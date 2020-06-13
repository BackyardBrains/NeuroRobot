
% Draw the activity front
vplot_front.XData = [nstep nstep] * ms_per_step;

% Draw audio spectrum
draw_audio.YData = pw(1:audx);
