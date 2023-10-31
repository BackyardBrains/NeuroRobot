try
    serial_receive = esp32WebsocketClient.getIncomingBuffer();
catch
     disp('Cannot receive ESP32 serial')
end

if exist('serial_receive', 'var') && ~isempty(serial_receive)
    serial_data = strsplit(serial_receive, ',');
    try       
        this_distance = str2double(serial_data{3});
        this_distance(this_distance == 0) = 4000;
        
%         disp(num2str(this_distance))
       
    catch
        disp('serial_receive is not empty but ESP_get_serial.m does not recognize the content')
        this_distance = 4000;
    end
else
    try
    if ~rem(nstep, 100)
        disp('serial_receive is empty')
    end
    catch
    end
    this_distance = 4000;
end