
serial_receive = rak_cam.readSerial();
%     disp(serial_receive)
% this may need to read all available somehow or sensory input will pile up   
if ~isempty(serial_receive)
    these_vals = [];
    if length(serial_receive) >= 6
        these_vals = str2num(serial_receive(1:6));
        this_duration = these_vals(3);
        % get encoder vals here
        this_distance = (this_duration/2) / 29.1;
        this_distance(this_distance == 0) = 300;
    else
        disp('serial_receive is not empty but rak_get_serial.m is not reading it right')
        this_distance = 300;
    end
else
    disp('serial_receive is empty')
    this_distance = 300;
end
