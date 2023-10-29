
try
    esp32WebsocketClient = ESP32SocketClient('ws://192.168.4.1/ws');
    esp32WebsocketClient.send('d:121;d:221;d:321;d:421;d:521;d:621;');
catch
    disp('ESP32 reconnection attempt failed')
end