serial_receive = rak_cam.readSerial();
if ~isempty(serial_receive)
    these_vals = str2num(serial_receive);
    this_ind = size(these_vals, 1);
    this_duration = these_vals(this_ind,3);
    this_distance = (this_duration/2) / 29.1;
    this_distance(this_distance > 300) = 300;
    this_distance(this_distance == 0) = 300;
    disp(horzcat('distance sensor = ', num2str(this_distance), ', this_ind = ', num2str(this_ind)))
%     serialArray = [serialArray serial_receive];
%     a = regexp(serialArray, '[\r]');
%     b = length(serialArray);
%     if ~isempty(a) && b >= 6
%         a = a(end);
%         x = serialArray(b-5:b-1);       
%         disp('Received:')
%         disp(x)
%         serialArray = [];
%     end
else
    this_distance = 300;
end