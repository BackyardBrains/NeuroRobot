
% rak_cam.sendAudio('Sounds/kitten.mp3');

if ~kitten_counter
    kitten_counter = 10;
end
kitten_counter = kitten_counter - 1;
if kitten_counter > 5
    if ~kitten_flag
        rak_cam.writeSerial('d:131;d:231;d:331;d:431;d:531;d:631;') % red
        disp('red')
    else
        rak_cam.writeSerial('d:121;d:221;d:321;d:421;d:521;d:621;') % green
        disp('green')
    end
else
    rak_cam.writeSerial('d:120;d:220;d:320;d:420;d:520;d:620;d:130;d:230;d:330;d:430;d:530;d:630;') % off
    disp('off')
end
if kitten_counter == 1
    if ~kitten_flag
        kitten_flag = 1;
    else
        kitten_flag = 0;
    end
    script_running = 0;
    kitten_counter = kitten_counter - 1;
end
