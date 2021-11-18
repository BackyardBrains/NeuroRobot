
send_this = 'd:121;d:221;d:321;d:421;d:521;d:621;';

if rak_only
    rak_cam.writeSerial(send_this)
elseif use_esp32
    esp32WebsocketClient.send(send_this);
end