
rak_cam.writeSerial('l:50;r:-50;s:0')
x = [];

for ii = 1:20
    serial_data = strsplit(serial_receive, ',');
    serial_data
    x1 = str2double(serial_data{1});
    x2 = str2double(serial_data{2});
    x = [x; x1 x2];
    pause(0.2)
end

rak_cam.writeSerial('l:0;r:0;s:0;')

clf
plot(x(:,1))
hold on
plot(x(:,2))

disp(horzcat('Encoder clicks to full rotation: x1: ', num2str(sum(x(:,1))), ', x2: ', num2str(sum(x(:,2)))))

% rak_cam.writeSerial('l:100;r:-100;s:0;')
% pause(1)
% rak_cam.writeSerial('l:0;r:0;s:0;')
