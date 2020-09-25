

% Search

script_step_count = script_step_count + 1;

if script_step_count == 1
    % get currrent frame
    % estimate current object (i.e. use cnn to guess preferred object of
    % activating neuron)
    rak_cam.writeSerial('d:131;')
    rak_cam.writeSerial('d:231;')
end

    % turn 180 degrees and start searching (rotate slowly, random walk,
    % sound output(ask someone to bring it)) until another instance (or repeat of original) of
    % object is visually detected (found)

if (script_step_count * pulse_period) > 10 % give up
    rak_cam.writeSerial('d:130;')
    rak_cam.writeSerial('d:230;')
    rak_cam.writeSerial('d:330;')
    rak_cam.writeSerial('d:430;')
    rak_cam.writeSerial('d:530;')
    rak_cam.writeSerial('d:630;')         
    script_running = 0;
    script_step_count = 0;  
end