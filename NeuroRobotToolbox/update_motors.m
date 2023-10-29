
if nneurons % This prevents error caused by running script after deleting all neurons

    % This script takes the current brain state, extracts motor and speaker
    % commands, and sends them (as motor_command) to robot
    
    motor_command = zeros(1, 5);
    
    % Extract motor out from spiking neurons
    left_backward = sum([sum(neuron_contacts(firing,6)) sum(neuron_contacts(firing,8))]) / 2;
    left_forward = sum([sum(neuron_contacts(firing,7)) sum(neuron_contacts(firing,9))]) / 2;

%     right_backward = sum([sum(neuron_contacts(firing,10)) sum(neuron_contacts(firing,12))]) / 2;
%     right_forward = sum([sum(neuron_contacts(firing,11)) sum(neuron_contacts(firing,13))]) / 2;

    right_forward = sum([sum(neuron_contacts(firing,10)) sum(neuron_contacts(firing,12))]) / 2;
    right_backward = sum([sum(neuron_contacts(firing,11)) sum(neuron_contacts(firing,13))]) / 2;    

    % Extract speaker out from spiking neurons
    these_speaker_neurons = find(neuron_contacts(:, 4) & firing);
    if ~isempty(these_speaker_neurons)
        these_tones = neuron_tones(these_speaker_neurons, 1);
    else
        these_tones = [];
    end

    if these_speaker_neurons
        try
            if ~vocal_buffer && max(these_tones) <= length(audio_out_fs)

                if length(these_speaker_neurons) > 1
                    these_speaker_neurons = these_speaker_neurons(1);
                    disp('Too many custom sound neurons: playing first sound only')
                end
                nsound = neuron_tones(these_speaker_neurons);

                % Insert robot speaker out here
                soundsc(audio_out_wavs(nsound).y, audio_out_fs(nsound));

                vocal_buffer = round((audio_out_durations(nsound) / pulse_period) + 1);
            
            elseif ~vocal_buffer && max(neuron_tones) > length(audio_out_fs) && (rak_only || use_esp32)  
                
                if length(these_speaker_neurons) > 1
                    speaker_tone = round(mean(neuron_tones(these_speaker_neurons)));
%                     these_speaker_neurons = these_speaker_neurons(1);
                    disp('Too many notes: playing mean note')
                else
                    speaker_tone = neuron_tones(these_speaker_neurons);
                end

%                 vocal_buffer = round((audio_out_durations(nsound) / pulse_period) + 1);

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
        catch exception
            this_error = exception.message;
            disp(this_error)
        end
    else
        speaker_tone = 0;
    end

    if vocal_buffer
        vocal_buffer = vocal_buffer - 1;
    end
    
    % Scale
    left_forward = left_forward * 2.5;
    right_forward = right_forward * 2.5;
    left_backward = left_backward * 2.5;
    right_backward = right_backward * 2.5;
    
    % Behavior scripts
    if ~isempty(neuron_scripts)
        this_script = find(neuron_scripts & firing, 1);
    end
    if exist('this_script', 'var') && ~isempty(this_script) && ~script_running % If spiking scripted neuron and no script currently running
        script_step_count = 0;
        script_running = neuron_scripts(this_script);
    end
    
    if script_running
        run_script
    else
        just_off
    end

    % Prepare to send
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
    
    if (nstep * pulse_period) < init_motor_block_in_s
        motor_command = [0 0 0 0 1000];
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
        
%     % Update motor contact colors
%     if l_torque
%         if l_dir == 1
%             contact_h(6).MarkerFaceColor = [0 0.45 0];
%             contact_h(8).MarkerFaceColor = [0 0.45 0];
%             contact_h(7).MarkerFaceColor = [0.9 0.6 0.3];
%             contact_h(9).MarkerFaceColor = [0.9 0.6 0.3];
%         elseif l_dir == -1
%             contact_h(6).MarkerFaceColor = [0.9 0.6 0.3];
%             contact_h(8).MarkerFaceColor = [0.9 0.6 0.3];
%             contact_h(7).MarkerFaceColor = [0 0.45 0];
%             contact_h(9).MarkerFaceColor = [0 0.45 0];
%         end
%     else
%         contact_h(6).MarkerFaceColor = [0.9 0.6 0.3];
%         contact_h(7).MarkerFaceColor = [0.9 0.6 0.3];     
%         contact_h(8).MarkerFaceColor = [0.9 0.6 0.3];
%         contact_h(9).MarkerFaceColor = [0.9 0.6 0.3];
%     end
%     
%     if r_torque
%         if r_dir == 1
%             contact_h(10).MarkerFaceColor = [0 0.45 0];
%             contact_h(12).MarkerFaceColor = [0 0.45 0];
%             contact_h(11).MarkerFaceColor = [0.9 0.6 0.3];
%             contact_h(13).MarkerFaceColor = [0.9 0.6 0.3];
%         elseif r_dir == -1
%             contact_h(10).MarkerFaceColor = [0.9 0.6 0.3];
%             contact_h(12).MarkerFaceColor = [0.9 0.6 0.3];
%             contact_h(11).MarkerFaceColor = [0 0.45 0];
%             contact_h(13).MarkerFaceColor = [0 0.45 0];
%         end
%     else
%         contact_h(10).MarkerFaceColor = [0.9 0.6 0.3];
%         contact_h(11).MarkerFaceColor = [0.9 0.6 0.3];     
%         contact_h(12).MarkerFaceColor = [0.9 0.6 0.3];
%         contact_h(13).MarkerFaceColor = [0.9 0.6 0.3];
%     end
    
    %% Sending serial to RAK
    if rak_only      
        send_this = horzcat('l:', num2str(l_torque * l_dir), ';', 'r:', num2str(r_torque * r_dir),';', 's:', num2str(speaker_tone), ';');
        try
            rak_cam.writeSerial(send_this)
        catch
            disp('Cannot send RAK serial')
        end
    elseif use_esp32        
        send_this = horzcat('l:', num2str(l_torque * l_dir), ';', 'r:', num2str(r_torque * r_dir),';', 's:', num2str(speaker_tone), ';');
        try
            esp32WebsocketClient.send(send_this);
        catch
            disp('Cannot send ESP32 serial')
        end
    end
end

