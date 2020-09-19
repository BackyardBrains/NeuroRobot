
%%%% 'Prime blink'

%%%% SCRIPT 4 %%%%

% This will be executed once per step (step time usually 100 ms)

if rak_only && ~rem(nstep, 7)
    if pulse_led_flag_1
        pulse_led_flag_1 = 0;
        rak_cam.writeSerial('d:610;d:521')
    else
        pulse_led_flag_1 = 1;
        rak_cam.writeSerial('d:611;d:520')
    end
end
if rak_only && ~rem(nstep, 11)
    if pulse_led_flag_2
        pulse_led_flag_2 = 0;
        rak_cam.writeSerial('d:621;d:530;')
    else
        pulse_led_flag_2 = 1;
        rak_cam.writeSerial('d:620;d:531')
    end
end
if rak_only && ~rem(nstep, 17)
    if pulse_led_flag_3
        pulse_led_flag_3 = 0;
        rak_cam.writeSerial('d:631;d:520;')
    else
        pulse_led_flag_3 = 1;
        rak_cam.writeSerial('d:630;d:521')
    end
end

