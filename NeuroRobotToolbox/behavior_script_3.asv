
%%%% 'Ring blink'

%%%% SCRIPT 3 %%%%

% This will be executed once per step (step time usually 100 ms)

if rak_only
    if spinled == 1
        rak_cam.writeSerial('d:121;')
        rak_cam.writeSerial('d:620;')        
        spinled = 2;
    elseif spinled == 2
        rak_cam.writeSerial('d:221;')
        rak_cam.writeSerial('d:120;')
        spinled = 3;
    elseif spinled == 3
        rak_cam.writeSerial('d:321;')
        rak_cam.writeSerial('d:220;')
        spinled = 4;
    elseif spinled == 4
        rak_cam.writeSerial('d:421;')
        rak_cam.writeSerial('d:320;')
        spinled = 5;
    elseif spinled == 5
        rak_cam.writeSerial('d:521;')
        rak_cam.writeSerial('d:420;')
        spinled = 6;
    elseif spinled == 6
        rak_cam.writeSerial('d:621;')
        rak_cam.writeSerial('d:520;')
        spinled = 1;        
    end
end
