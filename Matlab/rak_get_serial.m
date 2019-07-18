serial_receive = rak_cam.readSerial();
if ~isempty(serial_receive)
    these_vals = str2num(serial_receive);
    this_ind = size(these_vals, 1);
    this_duration = these_vals(this_ind,3);
    this_distance = (this_duration/2) / 29.1;
    this_distance(this_distance == 0) = 300;
else
    this_distance = 300;
    disp('rak_cam readSerial empty')
end