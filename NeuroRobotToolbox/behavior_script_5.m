

%%%% 'Approach / Consume / Escape'

%%%% SCRIPT 5 %%%%

% This will be executed once per step (step time usually 100 ms)

% play(player);
script_step_count = script_step_count + 1;

if script_step_count == 1
    rak_cam.writeSerial('d:131;')
    rak_cam.writeSerial('d:231;')
    rak_cam.writeSerial('d:331;')
    rak_cam.writeSerial('d:431;')
    rak_cam.writeSerial('d:531;')
    rak_cam.writeSerial('d:631;')
    rak_cam.sendAudio(strcat('.\Sounds\', num2str(audio_pref_names{11}), '.mp3'));
end
if (script_step_count * pulse_period) > 3
    rak_cam.writeSerial('d:130;')
    rak_cam.writeSerial('d:230;')
    rak_cam.writeSerial('d:330;')
    rak_cam.writeSerial('d:430;')
    rak_cam.writeSerial('d:530;')
    rak_cam.writeSerial('d:630;')         
    script_running = 0;
    script_step_count = 0;  
end