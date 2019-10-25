
 
ftdi = serialport("COM8", 115200);


a = 0;
x = 0;
while ~a
    pause(0.1)
    x = rand;
    if x >= 0.5
        write(ftdi,40)
    else
        write(ftdi,0)
    end
end

        