
try
    esp32WebsocketClient = ESP32SocketClient('ws://192.168.4.1/ws');
    just_green
    disp('ESP32 reconnected!')
catch
    disp('ESP32 reconnection attempt failed')
end