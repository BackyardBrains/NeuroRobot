
motor_command = zeros(1, 5);
left_forward = sum([sum(neuron_contacts(firing,6)) sum(neuron_contacts(firing,8))]) / 2;
right_forward = sum([sum(neuron_contacts(firing,10)) sum(neuron_contacts(firing,12))]) / 2;
left_backward = sum([sum(neuron_contacts(firing,7)) sum(neuron_contacts(firing,9))]) / 2;
right_backward = sum([sum(neuron_contacts(firing,11)) sum(neuron_contacts(firing,13))]) / 2;

left_torque = left_forward - left_backward;
left_dir = max([1 - sign(left_torque) 1]);
left_torque = abs(left_torque);
left_torque(left_torque > 250) = 250;
% left_torque(left_torque < 40) = 0;
motor_command(1,3) = left_torque;
motor_command(1,4) = left_dir;    

right_torque = right_forward - right_backward;
right_dir = max([1 - sign(right_torque) 1]);
right_torque = abs(right_torque); 
right_torque(right_torque > 250) = 250;   
% right_torque(right_torque < 40) = 0;
motor_command(1,1) = right_torque;
motor_command(1,2) = right_dir;

these_speaker_neurons = neuron_contacts(:, 4) & firing;
if sum(these_speaker_neurons)
    if ~vocal
        these_tones = neuron_tones(these_speaker_neurons, 1);
        these_tones(these_tones == 0) = [];
        speaker_tone = round(mean(these_tones)) / 2;
        if ~rak_only
            speaker_tone = round(speaker_tone * 0.0039); % the arduino currently needs an 8-bit number and will multiply by 256
        end
    else
        if sum(these_speaker_neurons) >= 2
            disp('Cannot play more than one sound at once. Cannot select one either.')
        else
            nsound = neuron_tones(these_speaker_neurons, 1);
            rak_cam.sendAudio(strcat('.\Sounds\', num2str(audio_pref_names{nsound}), '.mp3'));
        end
    end
else
    speaker_tone = 0;
end

motor_command(1,5) = speaker_tone;

if ~sum(motor_command(1, [1 3]))
    if manual_control == 1
        motor_command = [90 1 90 2 speaker_tone];
    elseif manual_control == 2
        motor_command = [90 2 90 1 speaker_tone];
    elseif manual_control == 3
        motor_command = [150 1 150 1 speaker_tone];
    elseif manual_control == 4 
        motor_command = [150 2 150 2 speaker_tone];
    elseif manual_control == 5
        motor_command = [0 0 0 0 speaker_tone];
    end
end

% Repackage
r_torque = motor_command(1,1);
r_dir = motor_command(1,2);
if r_dir == 2
    r_dir = -1;
end
l_torque = motor_command(1,3);
l_dir = motor_command(1,4);
if l_dir == 2
    l_dir = -1;
end 
    
% Update motor contact colors
if l_torque
    if l_dir == 1
        contact_h(6).MarkerFaceColor = [0 0.45 0];
        contact_h(8).MarkerFaceColor = [0 0.45 0];
        contact_h(7).MarkerFaceColor = [0.9 0.6 0.3];
        contact_h(9).MarkerFaceColor = [0.9 0.6 0.3];
    elseif l_dir == -1
        contact_h(6).MarkerFaceColor = [0.9 0.6 0.3];
        contact_h(8).MarkerFaceColor = [0.9 0.6 0.3];
        contact_h(7).MarkerFaceColor = [0 0.45 0];
        contact_h(9).MarkerFaceColor = [0 0.45 0];
    end
else
    contact_h(6).MarkerFaceColor = [0.9 0.6 0.3];
    contact_h(7).MarkerFaceColor = [0.9 0.6 0.3];     
    contact_h(8).MarkerFaceColor = [0.9 0.6 0.3];
    contact_h(9).MarkerFaceColor = [0.9 0.6 0.3];
end

if r_torque
    if r_dir == 1
        contact_h(10).MarkerFaceColor = [0 0.45 0];
        contact_h(12).MarkerFaceColor = [0 0.45 0];
        contact_h(11).MarkerFaceColor = [0.9 0.6 0.3];
        contact_h(13).MarkerFaceColor = [0.9 0.6 0.3];
    elseif r_dir == -1
        contact_h(10).MarkerFaceColor = [0.9 0.6 0.3];
        contact_h(12).MarkerFaceColor = [0.9 0.6 0.3];
        contact_h(11).MarkerFaceColor = [0 0.45 0];
        contact_h(13).MarkerFaceColor = [0 0.45 0];
    end
else
    contact_h(10).MarkerFaceColor = [0.9 0.6 0.3];
    contact_h(11).MarkerFaceColor = [0.9 0.6 0.3];     
    contact_h(12).MarkerFaceColor = [0.9 0.6 0.3];
    contact_h(13).MarkerFaceColor = [0.9 0.6 0.3];
end    

%% Sending serial to RAK
if rak_only      
    send_this = horzcat('l:', num2str(l_torque * l_dir), ';', 'r:', num2str(r_torque * r_dir),';', 's:', num2str(speaker_tone), ';');
    try
        rak_cam.writeSerial(send_this)
    catch
        disp('Cannot send RAK serial')
    end
elseif bluetooth_present && ~isequal(motor_command, prev_motor_command)
    bluetooth_send_motor_command
    prev_motor_command = motor_command;
end

