
if nneurons % This prevents error caused by running script after deleting all neurons

    % This script takes the current brain state, extracts motor and speaker
    % commands, and sends them (as motor_command) to robot
    
    % disp('1')
    motor_command = zeros(1, 5);
    
    % Extract motor out from spiking neurons
    left_forward = sum([sum(neuron_contacts(firing,6)) sum(neuron_contacts(firing,8))]) / 2;
    right_forward = sum([sum(neuron_contacts(firing,10)) sum(neuron_contacts(firing,12))]) / 2;
    left_backward = sum([sum(neuron_contacts(firing,7)) sum(neuron_contacts(firing,9))]) / 2;
    right_backward = sum([sum(neuron_contacts(firing,11)) sum(neuron_contacts(firing,13))]) / 2;
    
    % Extract speaker out from spiking neurons
    these_speaker_neurons = find(neuron_contacts(:, 4) & firing);
    if ~isempty(these_speaker_neurons)
        these_tones = neuron_tones(these_speaker_neurons, 1);
    else
        these_tones = [];
    end
    % disp('2')
    if these_speaker_neurons
        if ~vocal_buffer && max(these_tones) <= length(audio_out_fs)
    %             disp('1')
            if length(these_speaker_neurons) > 1
                these_speaker_neurons = these_speaker_neurons(1);
                disp('Too many custom sound neurons: playing first sound only')
            end
            nsound = neuron_tones(these_speaker_neurons, 1);
            if rak_only && nsound <= length(n_out_sounds)
                audio_file_name = strcat('.\Sounds\', audio_out_names{nsound}, '.mp3');
                rak_cam.sendAudio(audio_file_name);
    %         elseif rak_only
    %             disp('RAK cannot play visual objects yet, try, wants mp3 maybe')
    %             audio_file_name = strcat('.\Words\', audio_out_names{nsound}, '.mp3');
    %             rak_cam.sendAudio(audio_file_name);            
            elseif nsound && audio_out_fs(nsound) % so for now...
                soundsc(audio_out_wavs(nsound).y, audio_out_fs(nsound));
            end
    %         disp('3')
            vocal_buffer = round((audio_out_durations(nsound) / pulse_period) + 1);
        elseif ~vocal_buffer && max(neuron_tones) > length(audio_out_fs) && (rak_only || use_esp32)
            speaker_tone = these_tones(1);
        elseif ~vocal_buffer && max(neuron_tones) > length(audio_out_fs) && ~(rak_only || use_esp32)        
    
            if matlab_speaker_ctrl
                dxfs=16000;
                dxduration=pulse_period;
                dxvalues=1/dxfs:1/dxfs:dxduration;
    
                dxa = zeros(size(dxvalues));           
                for dxii = 1:length(these_tones)
                    dxfreq = these_tones(dxii);
                    dxa = dxa + sin(2*pi*dxfreq*dxvalues);
                end
                dxa = dxa / length(these_tones);
                
                dxa2 = ones(size(dxvalues));
                dxa2(1:500) = dxa2(1:500) .* [0.002:0.002:1];
                dxa2((end-499):end) = dxa2((end-499):end) .* [1:-0.002:0.002];             
                dxa = dxa .* dxa2;
                
                speaker_obj(dxa');
                speaker_tone = 0;
            else            
                dxfs=16000;
                dxduration=pulse_period*2;
                dxvalues=1/dxfs:1/dxfs:dxduration;
    
                dxa = zeros(size(dxvalues));
                for dxii = 1:length(these_tones)
                    dxfreq = these_tones(dxii);
                    dxa = dxa + sin(2*pi*dxfreq*dxvalues);
                end
    
                dxa2 = ones(size(dxvalues));
                dxa2(1:500) = dxa2(1:500) .* [0.002:0.002:1];
                dxa2((end-499):end) = dxa2((end-499):end) .* [1:-0.002:0.002];             
                dxa = dxa .* dxa2;            
                
                soundsc(dxa, dxfs)
                speaker_tone = 0;
            end
        end
    else
        speaker_tone = 0;
    end
    % disp('4')
    if vocal_buffer
        vocal_buffer = vocal_buffer - 1;
    end
    
    
    % Behavior scripts
    if ~isempty(neuron_scripts)
        this_script = find(neuron_scripts & firing, 1);
    end
    if exist('this_script', 'var') && ~isempty(this_script) && ~script_running % If spiking scripted neuron and no script currently running
        script_step_count = 0;
        script_running = neuron_scripts(this_script);
    %     disp(horzcat('Script running', num2str(script_running)))
    end
    
    if script_running
        if script_running == 1
            if rak_only || use_esp32
                behavior_script_1
            end
        elseif script_running == 2
            if rak_only || use_esp32
                behavior_script_2
            end
        elseif script_running == 3
            if rak_only || use_esp32
                behavior_script_3
            end        
        elseif script_running == 4
            if rak_only || use_esp32
                behavior_script_4
            end
        elseif script_running == 5
            if rak_only || use_esp32
                behavior_script_5
            end            
        else
            disp('Unknown behavior')
        end
        script_running = 0;
    end
    
    % Prepare to send
    left_forward = left_forward * 2.5;
    right_forward = right_forward * 2.5;
    left_backward = left_backward * 2.5;
    right_backward = right_backward * 2.5;
    
    left_torque = left_forward - left_backward;
    left_torque_mem = left_torque;
    left_dir = max([1 - sign(left_torque) 1]);
    left_torque = abs(left_torque);
    left_torque(left_torque > 250) = 250;
    motor_command(1,3) = left_torque;
    motor_command(1,4) = left_dir;
    
    right_torque = right_forward - right_backward;
    right_torque_mem = right_torque;
    right_dir = max([1 - sign(right_torque) 1]);
    right_torque = abs(right_torque); 
    right_torque(right_torque > 250) = 250;   
    motor_command(1,1) = right_torque;
    motor_command(1,2) = right_dir;
    
    motor_command(1,5) = speaker_tone;
    
    % Manual control exceptions
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
    
    % disp('6')
    
    %% Sending serial to RAK
    if rak_only      
        send_this = horzcat('l:', num2str(l_torque * l_dir), ';', 'r:', num2str(r_torque * r_dir),';', 's:', num2str(speaker_tone), ';');
        try
            rak_cam.writeSerial(send_this)
    %         disp(send_this)
        catch
            disp('Cannot send RAK serial')
        end
    elseif use_esp32
        send_this = horzcat('l:', num2str(l_torque * l_dir), ';', 'r:', num2str(r_torque * r_dir),';', 's:', num2str(speaker_tone), ';');
        try
            esp32WebsocketClient.send(send_this);
    %         disp(send_this)
        catch
            disp('Cannot send ESP32 serial')
        end    
    elseif bluetooth_present && ~isequal(motor_command, prev_motor_command)
        bluetooth_send_motor_command
        prev_motor_command = motor_command;
    end

end