serial_receive = rak_cam.readSerial();

if ~isempty(serial_receive)
    if(length(serial_receive)>=24)   
        these_vals = str2num(serial_receive(1:24));
        this_duration = these_vals(3);
        this_distance = (this_duration/2) / 29.1;
        this_distance(this_distance == 0) = 300;
    else
        disp('rak serial < 24 samples')
        this_distance = 300;
    end
else
    this_distance = 300;
    disp('rak_cam readSerial empty')
end