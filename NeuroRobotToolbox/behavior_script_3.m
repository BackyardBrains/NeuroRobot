
% What does this do?

script_step_count = script_step_count + 1;

if rak_only
    if spinled == 1
        rak_cam.writeSerial('d:121;')
        rak_cam.writeSerial('d:420;')        
        spinled = 2;
    elseif spinled == 2
        rak_cam.writeSerial('d:321;')
        rak_cam.writeSerial('d:120;')
        spinled = 3;
    elseif spinled == 3
        rak_cam.writeSerial('d:521;')
        rak_cam.writeSerial('d:320;')
        spinled = 4;
    elseif spinled == 4
        rak_cam.writeSerial('d:621;')
        rak_cam.writeSerial('d:520;')
        spinled = 5;
    elseif spinled == 5
        rak_cam.writeSerial('d:221;')
        rak_cam.writeSerial('d:620;')
        spinled = 6;
    elseif spinled == 6
        rak_cam.writeSerial('d:421;')
        rak_cam.writeSerial('d:220;')
        spinled = 1;        
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
    spinled = 0;
end

