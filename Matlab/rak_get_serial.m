serial_receive = rak.readSerial();
if ~isempty(serial_receive)
    serialArray = [serialArray serial_receive];
    a = regexp(serialArray, '[\r]');
    b = length(serialArray);
    if ~isempty(a) && b >= 6
        a = a(end);
        x = serialArray(b-5:b-1);       
        disp('Received:')
        disp(x)
        serialArray = [];
    end
end