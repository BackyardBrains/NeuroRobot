
send_this = 'd:110;d:210;d:310;d:410;d:510;d:610;d:120;d:220;d:320;d:420;d:520;d:620;d:130;d:230;d:330;d:430;d:530;d:630;';

if rak_only
    rak_cam.writeSerial(send_this)
elseif use_esp32
    esp32WebsocketClient.send(send_this);
end