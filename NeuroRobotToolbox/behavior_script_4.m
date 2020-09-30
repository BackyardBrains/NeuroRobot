
% Blink 2

script_step_count = script_step_count + 1;

if rak_only && ~rem(nstep, 7)
    if pulse_led_flag_1
        pulse_led_flag_1 = 0;
        rak_cam.writeSerial('d:610;d:521')
        rak_cam.writeSerial('d:410;d:321')
        rak_cam.writeSerial('d:210;d:121')
    else
        pulse_led_flag_1 = 1;
        rak_cam.writeSerial('d:611;d:520')
        rak_cam.writeSerial('d:411;d:320')
        rak_cam.writeSerial('d:211;d:120')
    end
end
if rak_only && ~rem(nstep, 11)
    if pulse_led_flag_2
        pulse_led_flag_2 = 0;
        rak_cam.writeSerial('d:621;d:530;')
        rak_cam.writeSerial('d:421;d:330;')
        rak_cam.writeSerial('d:221;d:130;')
    else
        pulse_led_flag_2 = 1;
        rak_cam.writeSerial('d:620;d:531')
        rak_cam.writeSerial('d:420;d:331')
        rak_cam.writeSerial('d:220;d:131')
    end
end
if rak_only && ~rem(nstep, 17)
    if pulse_led_flag_3
        pulse_led_flag_3 = 0;
        rak_cam.writeSerial('d:631;d:520;')
        rak_cam.writeSerial('d:431;d:320;')
        rak_cam.writeSerial('d:231;d:120;')
    else
        pulse_led_flag_3 = 1;
        rak_cam.writeSerial('d:630;d:521')
        rak_cam.writeSerial('d:430;d:421')
        rak_cam.writeSerial('d:230;d:221')
    end
end

if script_step_count > 50
    script_running = 0;
    script_step_count = 0;
    rak_cam.writeSerial('d:120;')
    rak_cam.writeSerial('d:220;')
    rak_cam.writeSerial('d:320;')
    rak_cam.writeSerial('d:420;')
    rak_cam.writeSerial('d:520;')
    rak_cam.writeSerial('d:620;')    
    
    rak_cam.writeSerial('d:130;')
    rak_cam.writeSerial('d:230;')
    rak_cam.writeSerial('d:330;')
    rak_cam.writeSerial('d:430;')
    rak_cam.writeSerial('d:530;')
    rak_cam.writeSerial('d:630;')    
    
    rak_cam.writeSerial('d:110;')
    rak_cam.writeSerial('d:210;')
    rak_cam.writeSerial('d:310;')
    rak_cam.writeSerial('d:410;')
    rak_cam.writeSerial('d:510;')
    rak_cam.writeSerial('d:610;')        
end
