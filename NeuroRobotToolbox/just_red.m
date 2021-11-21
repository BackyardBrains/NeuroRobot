
send_this = 'd:131;d:231;d:331;d:431;d:531;d:631;';

if rak_only
    rak_cam.writeSerial(send_this)
elseif use_esp32
    esp32WebsocketClient.send(send_this);
end