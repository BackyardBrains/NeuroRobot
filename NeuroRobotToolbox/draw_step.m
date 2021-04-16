
% Draw the activity front
vplot_front.XData = [nstep nstep] * ms_per_step;

% Draw audio spectrum
draw_audio.CData(:, nstep) = sound_spectrum(:, nstep);
cplot_front.XData = [nstep nstep];