
serial_receive = rak_cam.readSerial();
% disp(serial_receive)

serial_data = strsplit(serial_receive, ',');
if ~isempty(serial_receive)
    try
        this_distance = str2double(serial_data{3});
        this_distance(this_distance == 0) = 4000;
        disp(num2str(this_distance))
    catch
        disp('serial_receive is not empty but rak_get_serial.m does not recognize the content')
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
