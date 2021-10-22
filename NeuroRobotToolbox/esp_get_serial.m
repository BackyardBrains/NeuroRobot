
try
    serial_receive = esp32WebsocketClient.getIncomingBuffer();
catch
     disp('Cannot receive ESP32 serial')
end
size(serial_receive)
if ~isempty(serial_receive)
    
    serial_data = strsplit(serial_receive, ',');
    try
        
        this_distance = str2double(serial_data{3});
        this_distance(this_distance == 0) = 4000;
       
    catch
        disp('serial_receive is not empty but ESP_get_serial.m does not recognize the content')
        this_distance = 4000;
    end
else
    
    disp('serial_receive is empty')
    this_distance = 4000;
end