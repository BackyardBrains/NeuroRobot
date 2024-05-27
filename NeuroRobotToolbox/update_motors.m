
if nneurons % This prevents error caused by running script after deleting all neurons

    % This script takes the current brain state, extracts motor and speaker
    % commands, and sends them (as motor_command) to robot
    
    motor_command = zeros(1, 5);
    
    % Extract motor out from spiking neurons
    
    left_forward = sum(neuron_contacts(firing,12));
    left_backward = sum(neuron_contacts(firing,13));    

    right_forward = sum(neuron_contacts(firing,8));
    right_backward = sum(neuron_contacts(firing,9));

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

    % Manual control
    hGUIData = guidata(fig_design);
    if ~isempty(hGUIData)
        this_key = hGUIData.outputVar;
        if strcmp(this_key, 'leftarrow')
            left_forward = 75;
            left_backward = 0;
            right_forward = 0;
            right_backward = 75;
        elseif strcmp(this_key, 'rightarrow')
            left_forward = 0;
            left_backward = 50;
            right_forward = 50;
            right_backward = 0;
        elseif strcmp(this_key, 'uparrow')
            left_forward = 50;
            left_backward = 0;
            right_forward = 50;
            right_backward = 0;
        elseif strcmp(this_key, 'downarrow')
            left_forward = 0;
            left_backward = 75;
            right_forward = 0;
            right_backward = 75;
        end
    end

    % Scale
    left_forward = left_forward * 2.5;
    right_forward = right_forward * 2.5;
    left_backward = left_backward * 2.5;
    right_backward = right_backward * 2.5;
    
    % Run scripts
    this_neuron = find(neuron_scripts & firing, 1);
    if ~isempty(this_neuron)
        script_running = neuron_scripts(this_neuron);
    else
        script_running = 0;
    end
    
    if rak_only || use_esp32
        if script_running == 1
            just_red
        elseif script_running == 2
            just_green
        elseif script_running == 3
            just_blue
        elseif script_running == 4
            disp('Delayer')
        elseif script_running == 5            
            this_action = getAction(agent, this_state);
            this_action = cell2mat(this_action);
            this_motor_vector = motor_combs(this_action, :);
            disp(horzcat('action: ', num2str(this_action), ', torques: ', num2str(this_motor_vector)))
            
            left_forward = 0;
            left_backward = 0;
            right_forward = 0;
            right_backward = 0;
        
            if this_motor_vector(1) > 0
                left_forward = this_motor_vector(1);
            else
                left_backward = this_motor_vector(1);
            end
            
            if this_motor_vector(2) > 0
                right_forward = this_motor_vector(2);
            else
                right_backward = -this_motor_vector(2);
            end            
        elseif script_running == 6
            % disp('CPP')
            [left_forward, right_forward] = script_cpp(this_x, this_y, this_o);
        end
        script_running = 0;   
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
    if l_dir == 1
        l_dir = -1;
    end 
        
    
    %% Sending serial to RAK
    if rak_only      
        % send_this = horzcat('l:', num2str(l_torque * l_dir), ';', 'r:', num2str(r_torque * r_dir),';', 's:', num2str(speaker_tone), ';');
        % try
        %     rak_cam.writeSerial(send_this)
        % catch
        %     disp('Cannot send RAK serial')
        % end
    elseif use_esp32
        send_this = horzcat('l:', num2str(l_torque * l_dir), ';', 'r:', num2str(r_torque * r_dir),';', 's:', num2str(speaker_tone), ';');
        try
            esp32WebsocketClient.send(send_this);
        catch
            disp('Cannot send ESP32 serial')
        end
        % disp(horzcat('xstep: ', num2str(xstep)))
        % disp(send_this)
        % send_this_2 = horzcat('motor command: ', num2str(motor_command));
        % disp(send_this_2)
    end
end

