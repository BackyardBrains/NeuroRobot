
send_this = 'd:111;d:211;d:311;d:411;d:511;d:611;';

if rak_only
    rak_cam.writeSerial(send_this)
elseif use_esp32
    esp32WebsocketClient.send(send_this);
end