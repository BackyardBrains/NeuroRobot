
if ~pause_flag
    pause_flag = 1;
    stop(pulse)
    button_pause.String = 'Start';
    button_pause.BackgroundColor = [0.94 0.78 0.62];
elseif pause_flag
    pause_flag = 0;
    button_pause.String = 'Pause';
    button_pause.BackgroundColor = [0.9400 0.9400 0.9400];
    start(pulse);
end