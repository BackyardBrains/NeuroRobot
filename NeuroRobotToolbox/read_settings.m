


% option_app = {'BG Colors', 'Draw Neuron Numbers'; 'Draw Synapse Weights', 'Record Data', 'Use RL Controllers};
if sum(select_app.Value == 1)
    bg_colors = 1;              % Use neuron color to indicate network ID, and neuron flickering to indicate spikes  
else
    bg_colors = 0;
end

if sum(select_app.Value == 2)
    draw_neuron_numbers = 1;
else
    draw_neuron_numbers = 0;
end

if sum(select_app.Value == 3)
    draw_synapse_strengths = 1;
else
    draw_synapse_strengths = 0;
end

if sum(select_app.Value == 4)
    save_experiences = 1;
else
    save_experiences = 0;
end

if sum(select_app.Value == 5)
    use_controllers = 1;        % Switch this so correct nets are loaded with brain selection    
else
    use_controllers = 0;
end

% option_vision = {'RandomWalk'; 'AlexNet'; 'Robots'; 'Faces'};
if sum(select_vision.Value == 1)    
end
if sum(select_vision.Value == 2)
    use_cnn = 1;
else
    use_cnn = 0;
end
if sum(select_vision.Value == 3)
    use_rcnn = 1;
else
    use_rcnn = 0;
end
if sum(select_vision.Value == 4)
end

% option_hearing = {'Microphone/FFT', 'Speech2Text', 'Text2Speech'; 'OpenAI'};
audio_th = 100;               % Audio threshold (increase if sound spectrum looks too crowded)
matlab_audio_rec = 1;       % Use computer microphone to listen

matlab_speaker_ctrl = 0;    % Multi tone output
vocal = 0;                  % Custom sound output
supervocal = 0;             % Custom word output (text-to-speech - REQUIRES WINDOWS)

if sum(select_communication.Value == 1)
else
end
if sum(select_communication.Value == 2)
else
end
if sum(select_communication.Value == 3)
else
end
if sum(select_communication.Value == 4)
else
end

% select_brain
brain_name = brain_string{select_brain.Value};

